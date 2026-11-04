'use client';

// H2 create and edit (S5 FR-033, FR-034; PRD A1, A4, Q2, Q13). Copy-deck validation with a summary, a
// live preview card, the location picker, and the photo uploaded straight to the bucket. After the first
// booking, date, time, zone and place show locked; the API's `location_locked` and
// `capacity_below_bookings` land on their fields. Price and community are set once: the API has no edit
// for them.
import type { HostActivity } from '@velio/contracts';
import { useRouter } from 'next/navigation';
import { useRef, useState, useSyncExternalStore, type FormEvent } from 'react';
import { ActivityCard } from '../cards';
import { Banner } from '../feedback';
import { LocationBlock } from '../maps';
import { LocationPickerLive } from '../maps-live';
import { useFlash } from '../plan/flash';
import { Button, Icon, Photo, TextField } from '../primitives';
import { ApiRequestError, apiJson } from '@/lib/api/client';
import { formatMoney, formatWhen, zoneLabel } from '@/lib/format';
import {
  CAPACITY_MAX,
  communityCenter,
  communityCurrency,
  createBody,
  MEETING_POINT_MAX,
  parsePrice,
  patchBody,
  spotsHelp,
  summaryTitle,
  validate,
  zonedToIso,
  type FormErrors,
  type HostForm,
} from '@/lib/host-form';
import { PhotoError, uploadPhoto } from '@/lib/photo';

const LOCKED = 'Date, time and place are locked now that people have booked.';

const noSubscribe = () => () => undefined;
const NO_ZONES: string[] = [];
let zoneList: string[] | null = null;
const readZones = () => (zoneList ??= Intl.supportedValuesOf?.('timeZone') ?? NO_ZONES);
const readZone = () => Intl.DateTimeFormat().resolvedOptions().timeZone;

export interface EditContext {
  id: string;
  booked: number;
  photoUrl: string | null;
  directionsUrl: string;
  staticMapUrl: string | null;
  communityName: string;
  currency: string;
}

/** Maps a save error to fields or a banner. Exported for tests. */
export function saveFailure(err: unknown): { fields: FormErrors; refresh?: boolean } | { banner: string } {
  if (err instanceof ApiRequestError) {
    if (err.code === 'location_locked') return { fields: { date: LOCKED, location: LOCKED }, refresh: true };
    if (err.code === 'capacity_below_bookings')
      return { fields: { capacity: 'That’s fewer spots than people have booked.' }, refresh: true };
    if (err.code === 'validation_failed' && err.message.includes('photoKey'))
      return { fields: { photo: 'Upload the photo again.' } };
    if (err.code === 'forbidden' || err.code === 'not_found')
      return { banner: 'You can’t edit this activity.' };
  }
  return { banner: 'Check your connection and try again.' };
}

function plural(n: number, one: string, many: string) {
  return n === 1 ? `1 ${one}` : `${n} ${many}`;
}

export function ActivityForm({
  communities,
  host,
  initial,
  edit,
  published,
}: {
  communities: { slug: string; name: string }[];
  /** The host as guests see them, for the preview ("Amara O."). */
  host: string;
  initial: HostForm;
  /** Absent when creating. */
  edit?: EditContext;
  /** Straight after publishing (`?published=1`). */
  published?: boolean;
}) {
  const router = useRouter();
  const editing = !!edit;
  const booked = edit?.booked ?? 0;
  const locked = booked > 0;
  const [form, setForm] = useState(initial);
  // The zone defaults to the browser's (S5 §4.8), read after hydration so the server render matches.
  const browserZone = useSyncExternalStore(noSubscribe, readZone, () => '');
  const zones = useSyncExternalStore(noSubscribe, readZones, () => NO_ZONES);
  const [zoneEdited, setZoneEdited] = useState(!!initial.timezone);
  const [now, setNow] = useState(() => Date.now());
  const [baseline, setBaseline] = useState(initial);
  const [photoUrl, setPhotoUrl] = useState(edit?.photoUrl ?? null);
  const [photoBusy, setPhotoBusy] = useState(false);
  const [photoFailed, setPhotoFailed] = useState<string | null>(null);
  const [showErrors, setShowErrors] = useState(false);
  const [apiErrors, setApiErrors] = useState<FormErrors>({});
  const [banner, setBanner] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [flash, showFlash] = useFlash();
  const summary = useRef<HTMLDivElement>(null);
  const file = useRef<HTMLInputElement>(null);

  const current: HostForm = zoneEdited ? form : { ...form, timezone: browserZone };
  const currency = edit?.currency ?? communityCurrency(form.communitySlug);
  const options = { editing, locked, booked, currency };
  const validation = validate(current, { ...options, now });
  const errors: FormErrors = { ...(showErrors ? validation : {}), ...apiErrors };
  if (photoFailed) errors.photo = photoFailed;
  const errorCount = Object.keys(showErrors ? validation : {}).length;

  function set<K extends keyof HostForm>(key: K, value: HostForm[K]) {
    if (key === 'timezone') setZoneEdited(true);
    setForm((f) => ({ ...f, [key]: value }));
    setApiErrors((e) => {
      if (!Object.keys(e).length) return e;
      const next = { ...e };
      delete next[key as keyof FormErrors];
      if (key === 'location' || key === 'date') {
        delete next.location;
        delete next.date;
      }
      return next;
    });
  }

  async function pickPhoto(picked: File | undefined) {
    if (!picked) return;
    setPhotoBusy(true);
    setPhotoFailed(null);
    try {
      const { key, previewUrl } = await uploadPhoto(picked);
      setPhotoUrl(previewUrl);
      set('photoKey', key);
    } catch (err) {
      setPhotoFailed(
        err instanceof PhotoError && err.reason === 'unreadable'
          ? 'We couldn’t read that photo. Try a JPG or PNG.'
          : 'We couldn’t upload the photo. Check your connection and try again.',
      );
    } finally {
      setPhotoBusy(false);
      if (file.current) file.current.value = '';
    }
  }

  async function submit(e: FormEvent) {
    e.preventDefault();
    setBanner(null);
    const at = Date.now();
    setNow(at);
    if (Object.keys(validate(current, { ...options, now: at })).length) {
      setShowErrors(true);
      requestAnimationFrame(() => summary.current?.focus());
      return;
    }
    setSaving(true);
    try {
      if (!edit) {
        const created = await apiJson<HostActivity>('/activities', {
          method: 'POST',
          body: createBody(current),
        });
        router.replace(`/host/activities/${created.id}/edit?published=1`);
        return;
      }
      const patch = patchBody(current, baseline, locked);
      if (Object.keys(patch).length) {
        await apiJson<HostActivity>(`/activities/${edit.id}`, { method: 'PATCH', body: patch });
      }
      setBaseline(current);
      setShowErrors(false);
      showFlash('Changes saved');
      router.refresh();
      setSaving(false);
    } catch (err) {
      setSaving(false);
      const failure = saveFailure(err);
      if ('banner' in failure) {
        setBanner(failure.banner);
      } else {
        setApiErrors(failure.fields);
        if (failure.refresh) router.refresh();
      }
    }
  }

  const community = communities.find((c) => c.slug === form.communitySlug);
  const iso = zonedToIso(current.date, current.time, current.timezone);
  const priceMinor = parsePrice(form.price, currency);
  const title = baseline.title || 'your activity';
  const pageTitle = published ? title : editing ? `Edit ${title}` : 'Create an activity';

  const photo = photoUrl ? (
    <div className="relative aspect-[16/10] overflow-hidden rounded-card bg-forest md:aspect-[16/7] [&_img]:absolute [&_img]:inset-0 [&_img]:size-full [&_img]:object-cover [&_svg]:absolute [&_svg]:inset-0 [&_svg]:size-full">
      <Photo src={photoUrl} alt={`Photo for ${form.title || 'your activity'}`} />
      <Button
        small
        className="!absolute right-3 bottom-3 !bg-surface !text-forest"
        loading={photoBusy}
        onClick={() => file.current?.click()}
      >
        Change photo
      </Button>
    </div>
  ) : (
    <div
      className={`flex flex-col items-center gap-2.5 rounded-card border-2 border-dashed bg-surface px-5 py-7 text-center md:p-8 ${errors.photo ? 'border-danger' : 'border-field-border'}`}
    >
      <strong>Add one photo</strong>
      <span className="text-[14px] text-muted">It leads your activity page and every invite link.</span>
      <Button variant="secondary" small loading={photoBusy} onClick={() => file.current?.click()}>
        {photoBusy ? 'Uploading…' : 'Choose a photo'}
      </Button>
    </div>
  );

  return (
    <main className="mx-auto flex w-full max-w-content flex-col gap-6 px-5 pt-3 pb-8 md:px-10 md:pt-8 md:pb-16">
      {flash}
      <div className="flex flex-col gap-1.5">
        <a href="/host/activities" className="text-[14px] font-bold">
          My activities
        </a>
        <h1 className="m-0 text-title md:text-[36px] md:leading-[42px]">{pageTitle}</h1>
      </div>

      {published && edit ? (
        <div
          className="flex flex-wrap items-center gap-3.5 rounded-card bg-lime px-5 py-4 text-forest"
          role="status"
        >
          <Icon name="check" />
          <strong className="min-w-[200px] flex-1">
            Published. {title} is live in {edit.communityName}.
          </strong>
          <Button variant="secondary" small href={`/host/activities/${edit.id}/attendance`}>
            Open live attendance
          </Button>
          <Button variant="quiet" small href={`/activities/${edit.id}`}>
            View the page
          </Button>
        </div>
      ) : null}
      {locked ? (
        <Banner icon="lock" title={LOCKED}>
          <span className="hidden md:inline">{plural(booked, 'person is', 'people are')} going. </span>
          You can still change the title, description, photo and number of spots.
        </Banner>
      ) : null}
      {errorCount ? (
        <div ref={summary} tabIndex={-1} className="outline-none">
          <Banner tone="error" title={summaryTitle(errorCount, editing)}>
            They’re marked below.
          </Banner>
        </div>
      ) : null}
      {banner ? (
        <Banner tone="error" title={editing ? 'We couldn’t save your changes.' : 'We couldn’t publish this.'}>
          {banner}
        </Banner>
      ) : null}

      <form noValidate onSubmit={submit} className="flex flex-wrap items-start gap-6 md:gap-10">
        <div className="flex min-w-0 flex-[999_1_560px] flex-col gap-6 md:gap-7">
          <section className="flex flex-col gap-4" aria-labelledby="h2-basics">
            <h2 id="h2-basics" className="m-0 text-heading">
              The basics
            </h2>
            {photo}
            {errors.photo ? (
              <span className="vl-field-error" id="h-photo-err" role="alert">
                <Icon name="alert" />
                {errors.photo}
              </span>
            ) : null}
            <input
              ref={file}
              type="file"
              accept="image/*"
              className="vl-sr"
              tabIndex={-1}
              aria-hidden
              onChange={(e) => pickPhoto(e.currentTarget.files?.[0])}
            />
            <TextField
              id="h-title"
              label="Title"
              value={form.title}
              placeholder="What are people signing up for?"
              maxLength={200}
              error={errors.title}
              onChange={(v) => set('title', v)}
            />
            <TextField
              id="h-desc"
              label="Description"
              multiline
              value={form.description}
              placeholder="What happens, what to bring, who it suits"
              maxLength={5000}
              onChange={(v) => set('description', v)}
            />
            <div className="vl-field">
              <label htmlFor="h-community">Community</label>
              <select
                id="h-community"
                value={form.communitySlug}
                disabled={editing}
                onChange={(e) => set('communitySlug', e.currentTarget.value)}
              >
                {communities.map((c) => (
                  <option key={c.slug} value={c.slug}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
          </section>

          <section className="flex flex-col gap-4" aria-labelledby="h2-when">
            <h2 id="h2-when" className="m-0 text-heading">
              When
            </h2>
            <div className="grid grid-cols-2 gap-3 md:grid-cols-[repeat(auto-fit,minmax(min(180px,100%),1fr))]">
              <TextField
                id="h-date"
                label="Date"
                type="date"
                value={form.date}
                readOnly={locked}
                error={errors.date}
                onChange={(v) => set('date', v)}
              />
              <TextField
                id="h-time"
                label="Start time"
                type="time"
                value={form.time}
                readOnly={locked}
                error={errors.time}
                onChange={(v) => set('time', v)}
              />
              <TextField
                id="h-zone"
                label="Time zone"
                className="col-span-2 md:col-span-1"
                value={current.timezone}
                list="h-zones"
                autoComplete="off"
                readOnly={locked}
                help="Guests see times in this zone"
                error={errors.timezone}
                onChange={(v) => set('timezone', v.trim())}
              />
              {locked ? null : (
                <datalist id="h-zones">
                  {zones.map((z) => (
                    <option key={z} value={z} />
                  ))}
                </datalist>
              )}
            </div>
          </section>

          <section className="flex flex-col gap-4" aria-labelledby="h2-where">
            <h2 id="h2-where" className="m-0 text-heading">
              Where
            </h2>
            {locked && form.location ? (
              <>
                <LocationBlock
                  title={false}
                  venue={form.location.venueName}
                  address={form.location.addressText}
                  meetingPoint={form.meetingPoint || null}
                  directionsUrl={edit!.directionsUrl}
                  staticMapUrl={edit!.staticMapUrl}
                  map={!!edit!.staticMapUrl}
                />
                <p className="vl-public-note m-0">
                  <Icon name="lock" />
                  Location is locked because people have booked.
                </p>
                {errors.location ? (
                  <span className="vl-field-error" role="alert">
                    <Icon name="alert" />
                    {errors.location}
                  </span>
                ) : null}
              </>
            ) : (
              <>
                <LocationPickerLive
                  value={form.location}
                  onChange={(v) => set('location', v)}
                  defaultCenter={communityCenter(form.communitySlug)}
                  errors={{
                    location: errors.location,
                    venueName: errors.venueName,
                    addressText: errors.addressText,
                  }}
                />
                <TextField
                  id="h-meet"
                  label="Meeting point (optional)"
                  value={form.meetingPoint}
                  placeholder="Where exactly to find you"
                  maxLength={MEETING_POINT_MAX}
                  count={form.meetingPoint.length}
                  onChange={(v) => set('meetingPoint', v)}
                />
              </>
            )}
          </section>

          <section className="flex flex-col gap-4" aria-labelledby="h2-price">
            <h2 id="h2-price" className="m-0 text-heading">
              Price and spots
            </h2>
            <div className="grid grid-cols-1 gap-3 md:grid-cols-[repeat(auto-fit,minmax(min(220px,100%),1fr))]">
              <TextField
                id="h-price"
                label={`Price per person (${currency})`}
                value={form.price}
                inputMode="decimal"
                readOnly={editing}
                help="Guests pay you on the day. Velio takes no payment."
                error={errors.price}
                onChange={(v) => set('price', v)}
              />
              <Spots
                value={form.capacity}
                floor={Math.max(1, booked)}
                booked={booked}
                error={errors.capacity}
                onChange={(v) => set('capacity', v)}
              />
            </div>
          </section>
        </div>

        <aside className="flex min-w-0 flex-[1_1_340px] flex-col gap-4" aria-label="Preview">
          <span className="text-[12px] font-bold tracking-[.06em] text-muted uppercase">Preview</span>
          <ActivityCard
            title={form.title.trim() || 'Your activity title'}
            photoUrl={photoUrl}
            scene="lake"
            community={community?.name}
            spots={Math.max(0, form.capacity - booked)}
            date={iso ? formatWhen(iso, current.timezone) : 'Date and time'}
            zone={iso ? zoneLabel(current.timezone) : undefined}
            place={form.location?.venueName.trim() || 'Location'}
            price={priceMinor ? formatMoney(priceMinor, currency) : undefined}
            host={host}
          />
          <Button type="submit" block loading={saving} disabled={photoBusy}>
            {editing ? 'Save changes' : 'Publish'}
          </Button>
          {locked ? null : (
            <p className="m-0 text-caption text-muted">
              Once someone books, date, time and place lock. Check them before you publish.
            </p>
          )}
        </aside>
      </form>
    </main>
  );
}

function Spots({
  value,
  floor,
  booked,
  error,
  onChange,
}: {
  value: number;
  floor: number;
  booked: number;
  error?: string;
  onChange: (value: number) => void;
}) {
  const border = { background: 'var(--surface)', border: '1.5px solid var(--field-border)' };
  return (
    <div className={`vl-field${error ? ' has-error' : ''}`}>
      <label htmlFor="h-spots">Total spots</label>
      <div className="flex items-center gap-2">
        <button
          className="vl-iconbtn"
          type="button"
          aria-label="One fewer spot"
          aria-controls="h-spots"
          disabled={value <= floor}
          style={border}
          onClick={() => onChange(Math.max(floor, value - 1))}
        >
          <Icon name="minus" />
        </button>
        <input
          id="h-spots"
          value={Number.isFinite(value) ? String(value) : ''}
          inputMode="numeric"
          aria-invalid={error ? true : undefined}
          aria-describedby="h-spots-help"
          className="!w-[88px] text-center !font-bold !text-[18px]"
          onChange={(e) => {
            const raw = e.currentTarget.value.replace(/\D/g, '');
            onChange(raw ? Math.min(CAPACITY_MAX + 1, Number(raw)) : NaN);
          }}
        />
        <button
          className="vl-iconbtn"
          type="button"
          aria-label="One more spot"
          aria-controls="h-spots"
          disabled={value >= CAPACITY_MAX}
          style={border}
          onClick={() => onChange(Number.isFinite(value) ? Math.max(floor, value + 1) : floor)}
        >
          <Icon name="plus" />
        </button>
      </div>
      {error ? (
        <span className="vl-field-error" id="h-spots-help">
          <Icon name="alert" />
          {error}
        </span>
      ) : (
        <span className="vl-field-help" id="h-spots-help">
          {spotsHelp(booked)}
        </span>
      )}
    </div>
  );
}
