// After a last_spot_race run: the SQL invariant on the run's activities. Exits 1 on any mismatch.
import { resolve } from 'node:path';
import { SQL } from 'bun';

const seed = (await Bun.file(resolve(import.meta.dir, 'results/seed.json')).json()) as {
  runId: string;
  activities: { id: string; spots: number }[];
};
const sql = new SQL(process.env.LOAD_CHECK_DATABASE_URL ?? 'postgres://postgres@localhost:5432/velio');

let failed = false;
for (const a of seed.activities) {
  const [row] = await sql`
    SELECT capacity, spots_left,
           (SELECT count(*)::int FROM bookings WHERE activity_id = a.id AND status = 'confirmed') AS confirmed
      FROM activities a WHERE id = ${a.id}`;
  const oversold = row.capacity - row.spots_left !== row.confirmed || row.confirmed > row.capacity;
  const exact = row.confirmed === a.spots && row.spots_left === 0;
  if (oversold || !exact) failed = true;
  console.log(
    `${a.spots} spot(s): confirmed=${row.confirmed} spots_left=${row.spots_left} ${oversold ? 'OVERSOLD' : exact ? 'ok' : 'MISMATCH'}`,
  );
}
await sql.close();
console.log(failed ? `check ${seed.runId}: FAILED` : `check ${seed.runId}: 0 oversold`);
process.exit(failed ? 1 : 0);
