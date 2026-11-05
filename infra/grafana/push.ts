// Pushes the dashboards and alert rules in infra/grafana to Grafana Cloud (S8 FR-018). Idempotent:
// dashboards are matched by UID and overwritten, and the alert rule group is replaced as a whole.
// Needs GRAFANA_URL (https://<stack>.grafana.net) and GRAFANA_SA_TOKEN (a service-account token with
// dashboard and alerting write access), from the environment or the git-ignored root .env. With
// GRAFANA_ALERT_EMAIL, the Velio rules notify that address through their own contact point; the
// stack's notification policy is left alone.
import { readdir } from 'node:fs/promises';
import { join } from 'node:path';

const FOLDER = { uid: 'velio', title: 'Velio' };
const CONTACT = 'velio-email';
const dir = import.meta.dir;

const url = process.env.GRAFANA_URL?.replace(/\/+$/, '');
const token = process.env.GRAFANA_SA_TOKEN;
const alertEmail = process.env.GRAFANA_ALERT_EMAIL;
if (!url || !token) {
  console.error('Set GRAFANA_URL and GRAFANA_SA_TOKEN (README "Grafana dashboards and alerts").');
  process.exit(1);
}

async function api(method: string, path: string, body?: unknown): Promise<Response> {
  const res = await fetch(`${url}${path}`, {
    method,
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
      // Provisioned through the API but still editable in the UI.
      'x-disable-provenance': 'true',
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return res;
}

async function ok(res: Response, what: string) {
  if (!res.ok) throw new Error(`${what}: HTTP ${res.status} ${await res.text()}`);
  return res;
}

/** The stack's hosted Prometheus (Grafana Cloud names it grafanacloud-<stack>-prom). */
async function prometheusUid(): Promise<string> {
  const sources = (await (await ok(await api('GET', '/api/datasources'), 'list data sources')).json()) as {
    uid: string;
    name: string;
    type: string;
  }[];
  const prom = sources.filter((s) => s.type === 'prometheus');
  const pick = prom.find((s) => /^grafanacloud-.*-prom$/.test(s.name)) ?? prom[0];
  if (!pick) throw new Error('No Prometheus data source in this stack.');
  console.log(`Prometheus data source: ${pick.name}`);
  return pick.uid;
}

/** `${PROM}` in the JSON stands for the data source UID, which differs per stack. */
const withSource = (text: string, uid: string) => JSON.parse(text.replaceAll('${PROM}', uid)) as unknown;

async function ensureFolder() {
  const found = await api('GET', `/api/folders/${FOLDER.uid}`);
  if (found.ok) return;
  await ok(await api('POST', '/api/folders', FOLDER), 'create folder');
  console.log(`Created folder ${FOLDER.title}`);
}

/** Upserts the Velio email contact point; returns its name, or undefined if there is none to use. */
async function contactPoint(): Promise<string | undefined> {
  const found = (await (
    await ok(await api('GET', `/api/v1/provisioning/contact-points?name=${CONTACT}`), 'list contact points')
  ).json()) as { uid: string }[];
  if (!alertEmail) return found.length > 0 ? CONTACT : undefined;
  const body = { uid: CONTACT, name: CONTACT, type: 'email', settings: { addresses: alertEmail } };
  if (found.length > 0) {
    await ok(
      await api('PUT', `/api/v1/provisioning/contact-points/${found[0]!.uid}`, body),
      'update contact point',
    );
  } else {
    await ok(await api('POST', '/api/v1/provisioning/contact-points', body), 'create contact point');
  }
  console.log(`Contact point: ${CONTACT}`);
  return CONTACT;
}

const prom = await prometheusUid();
await ensureFolder();
const receiver = await contactPoint();

for (const file of (await readdir(join(dir, 'dashboards'))).filter((f) => f.endsWith('.json')).sort()) {
  const dashboard = withSource(await Bun.file(join(dir, 'dashboards', file)).text(), prom) as {
    title: string;
  };
  await ok(
    await api('POST', '/api/dashboards/db', { dashboard, folderUid: FOLDER.uid, overwrite: true }),
    `dashboard ${file}`,
  );
  console.log(`Dashboard: ${dashboard.title}`);
}

for (const file of (await readdir(join(dir, 'alerts'))).filter((f) => f.endsWith('.json')).sort()) {
  const group = withSource(await Bun.file(join(dir, 'alerts', file)).text(), prom) as {
    title: string;
    rules: { folderUID?: string; ruleGroup?: string }[];
  };
  for (const rule of group.rules) {
    Object.assign(rule, { folderUID: FOLDER.uid, ruleGroup: group.title });
    // Simplified routing: these rules go straight to the Velio contact point.
    if (receiver) Object.assign(rule, { notification_settings: { receiver } });
  }
  await ok(
    await api(
      'PUT',
      `/api/v1/provisioning/folder/${FOLDER.uid}/rule-groups/${encodeURIComponent(group.title)}`,
      {
        ...group,
        folderUid: FOLDER.uid,
      },
    ),
    `alert rules ${file}`,
  );
  console.log(`Alert rules: ${group.title} (${group.rules.length})${receiver ? ` → ${receiver}` : ''}`);
}
