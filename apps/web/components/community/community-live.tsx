'use client';

// C1 community page (S5 FR-020, FR-022). Phone: a List / Map toggle, and the Maps script loads only when
// Map is chosen (NFR-004). From 768 px the design shows the list and map side by side, so the map loads
// there once the page is wide enough. Spots on every card are live; the map keeps only activities with
// spots, so sold-out and started ones leave it.
import type { ActivityCard as Card, CommunityPage } from '@velio/contracts';
import { useCallback, useState, useSyncExternalStore } from 'react';
import { ActivityCard, PlanCard } from '../cards';
import { EmptyState } from '../feedback';
import { CommunityMapLive, type CommunityMapPoint } from '../maps-live';
import { Photo, PhotoArt, Segmented, SpotsBadge, type SpotsState } from '../primitives';
import { apiJson } from '@/lib/api/client';
import { formatWhen } from '@/lib/format';
import { useOnline } from '@/lib/online';
import { useLiveSpots } from '@/lib/realtime/react';

const WIDE = '(min-width: 768px)';

function useWide(): boolean {
  return useSyncExternalStore(
    useCallback((cb: () => void) => {
      const mq = window.matchMedia(WIDE);
      mq.addEventListener('change', cb);
      return () => mq.removeEventListener('change', cb);
    }, []),
    () => window.matchMedia(WIDE).matches,
    () => false,
  );
}

const MAP_HINT = 'Only activities with spots show. Sold-out and started ones leave the map.';

function countLine(withSpots: number, total: number): string {
  if (total === 0) return 'No upcoming activities';
  if (withSpots === 0) return 'No upcoming activities with spots';
  return withSpots === 1 ? '1 upcoming activity with spots' : `${withSpots} upcoming activities with spots`;
}

export function CommunityLive({ page }: { page: CommunityPage }) {
  const { community, activities } = page;
  const online = useOnline();
  const wide = useWide();
  const [view, setView] = useState<'list' | 'map'>('list');
  const { spots, status } = useLiveSpots(
    Object.fromEntries(activities.map((a) => [a.id, { spotsLeft: a.spotsLeft, version: a.version }])),
    async () => {
      const fresh = await apiJson<CommunityPage>(`/communities/${community.slug}`);
      return Object.fromEntries(
        fresh.activities.map((a) => [a.id, { spotsLeft: a.spotsLeft, version: a.version }]),
      );
    },
  );
  const stale = !online || status === 'reconnecting';
  const spotsOf = (a: Card) => spots[a.id]?.spotsLeft ?? a.spotsLeft;
  const stateOf = (a: Card): SpotsState => (stale ? 'stale' : spots[a.id]?.changed ? 'changed' : 'live');

  const open = activities.filter((a) => a.status !== 'started' && spotsOf(a) > 0);
  const byId = new Map(activities.map((a) => [a.id, a]));
  const points: CommunityMapPoint[] = open.map((a) => ({
    id: a.id,
    lat: a.location.lat,
    lng: a.location.lng,
    label: `${spotsOf(a)} left`,
    title: a.title,
  }));

  const showMap = wide || view === 'map';
  const map = (
    <div className="flex flex-col gap-2">
      <CommunityMapLive
        points={points}
        ratio={wide ? '4 / 5' : '3 / 4'}
        onShowList={() => setView('list')}
        renderCard={(id) => {
          const a = byId.get(id)!;
          return (
            <PlanCard
              href={`/activities/${a.id}`}
              photoUrl={a.photoUrl}
              scene="lake"
              title={a.title}
              date={formatWhen(a.startsAt, a.timezone)}
              place={`${a.location.venueName} · ${spotsOf(a) === 1 ? '1 spot left' : `${spotsOf(a)} spots left`}`}
              members={a.members.preview.map((p) => ({ name: p.shortName, seed: p.avatarSeed }))}
              memberTotal={a.members.count}
              code="View activity"
            />
          );
        }}
      />
      <p className="m-0 text-caption text-muted">{MAP_HINT}</p>
    </div>
  );

  return (
    <main className="mx-auto flex w-full max-w-content flex-col gap-5 px-5 pt-1 pb-8 md:gap-6 md:px-10 md:pt-6 md:pb-16">
      <section className="flex flex-col gap-5 md:flex-row md:flex-wrap md:items-center md:gap-6">
        <div className="relative aspect-video overflow-hidden rounded-hero bg-forest md:aspect-[16/10] md:w-[220px] md:flex-none md:rounded-card [&>img]:absolute [&>img]:inset-0 [&>img]:size-full [&>img]:object-cover [&>svg]:absolute [&>svg]:inset-0 [&>svg]:size-full">
          {community.coverPhotoUrl ? (
            <Photo src={community.coverPhotoUrl} alt={`${community.name} cover photo`} priority />
          ) : (
            <PhotoArt scene="savanna" alt={`${community.name} cover photo`} />
          )}
        </div>
        <div className="flex min-w-0 flex-col gap-1.5 md:min-w-[260px] md:flex-1">
          <h1 className="m-0 text-title md:text-[36px] md:leading-[42px]">{community.name}</h1>
          <p className="m-0 text-muted md:text-[16px] md:leading-6">{community.blurb}</p>
          <span className="text-[14px] font-bold text-forest">
            {countLine(open.length, activities.length)}
          </span>
        </div>
      </section>

      {activities.length === 0 ? (
        <div className="md:mx-auto md:my-10 md:max-w-[480px]">
          <EmptyState
            icon="calendar"
            title="Nothing coming up right now"
            body="Activities with spots show here as soon as a host publishes one."
          />
        </div>
      ) : (
        <>
          <div className="md:hidden">
            <Segmented
              label="View"
              value={view}
              options={[
                { value: 'list', label: 'List', icon: 'list' },
                { value: 'map', label: 'Map', icon: 'map' },
              ]}
              onChange={(v) => setView(v as 'list' | 'map')}
            />
          </div>
          <div className="flex flex-wrap items-start gap-6">
            <ul
              className={`m-0 flex min-w-0 flex-[1_1_380px] list-none flex-col gap-3.5 p-0 ${view === 'map' ? 'max-md:hidden' : ''}`}
              aria-label={`Upcoming activities in ${community.name}`}
            >
              {activities.map((a) => (
                <li key={a.id}>
                  <a href={`/activities/${a.id}`} className="block text-inherit no-underline md:hidden">
                    <ActivityCard
                      compact
                      title={a.title}
                      photoUrl={a.photoUrl}
                      scene="lake"
                      spots={spotsOf(a)}
                      spotsState={stateOf(a)}
                      date={formatWhen(a.startsAt, a.timezone)}
                      place={a.location.venueName}
                    />
                  </a>
                  <a
                    href={`/activities/${a.id}`}
                    className="hidden grid-cols-[120px_minmax(0,1fr)] gap-3.5 rounded-card bg-surface p-3 text-ink no-underline md:grid"
                  >
                    <span className="relative aspect-[4/3] overflow-hidden rounded-[10px] bg-forest [&>img]:absolute [&>img]:inset-0 [&>img]:size-full [&>img]:object-cover [&>svg]:block [&>svg]:size-full">
                      <Photo src={a.photoUrl} scene="lake" alt="" />
                    </span>
                    <span className="flex min-w-0 flex-col gap-1.5">
                      <strong className="text-[16px]">{a.title}</strong>
                      <span className="text-caption text-muted">
                        {formatWhen(a.startsAt, a.timezone)} · {a.location.venueName}
                      </span>
                      <span>
                        <SpotsBadge spots={spotsOf(a)} state={stateOf(a)} />
                      </span>
                    </span>
                  </a>
                </li>
              ))}
            </ul>
            {showMap ? <div className="min-w-0 flex-[1.3_1_460px]">{map}</div> : null}
          </div>
        </>
      )}
    </main>
  );
}
