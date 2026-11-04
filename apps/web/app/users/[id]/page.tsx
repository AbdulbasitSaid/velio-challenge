// /users/<id> (S5 §4.8 P1; PRD Q10). Public and server-rendered: the person as "First L.", when they
// joined, and what they host next. Never their bookings or Plans (SEC-001).
import { Profile } from '@velio/contracts';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { cache } from 'react';
import { SiteHeader } from '../../site-header';
import { ActivityCard, Avatar, Icon } from '@/components';
import { ApiRequestError } from '@/lib/api/client';
import { serverFetch } from '@/lib/api/server';
import { firstName, formatWhen, monthYear } from '@/lib/format';

export const dynamic = 'force-dynamic';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const loadProfile = cache(async (id: string): Promise<Profile | null> => {
  if (!UUID.test(id)) return null;
  try {
    return await serverFetch(`/users/${id}/profile`, { schema: Profile });
  } catch (err) {
    if (err instanceof ApiRequestError && (err.status === 404 || err.status === 400)) return null;
    throw err;
  }
});

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const profile = await loadProfile((await params).id);
  return { title: profile?.person.shortName ?? 'Profile' };
}

export default async function ProfilePage({ params }: { params: Promise<{ id: string }> }) {
  const profile = await loadProfile((await params).id);
  if (!profile) notFound();
  const { person, hosting } = profile;
  const first = firstName(person.shortName);

  return (
    <>
      <SiteHeader />
      <main className="mx-auto flex w-full max-w-content flex-col gap-6 px-5 pt-3 pb-8 md:gap-8 md:px-10 md:pt-10 md:pb-16">
        <section className="flex flex-col items-center gap-3 rounded-hero bg-surface px-5 py-7 text-center md:flex-row md:flex-wrap md:gap-6 md:bg-transparent md:p-0 md:text-left">
          <span className="md:hidden">
            <Avatar name={person.shortName} seed={person.avatarSeed} size={88} decorative />
          </span>
          <span className="hidden md:inline-flex">
            <Avatar name={person.shortName} seed={person.avatarSeed} size={96} decorative />
          </span>
          <div className="flex flex-col gap-1">
            <h1 className="m-0 text-title md:text-[36px] md:leading-[42px]">{person.shortName}</h1>
            <span className="text-[14px] text-muted md:text-[15px]">
              On Velio since {monthYear(profile.memberSince)}
            </span>
          </div>
        </section>

        {hosting.length ? (
          <section className="flex flex-col gap-3.5 md:gap-4" aria-labelledby="hosting-h">
            <h2 id="hosting-h" className="m-0 text-heading">
              Upcoming with {first}
            </h2>
            <ul className="m-0 grid list-none grid-cols-1 gap-3.5 p-0 md:grid-cols-[repeat(auto-fill,minmax(min(280px,100%),1fr))] md:gap-4">
              {hosting.map((a) => (
                <li key={a.id}>
                  <a href={`/activities/${a.id}`} className="block text-inherit no-underline">
                    <ActivityCard
                      compact
                      title={a.title}
                      photoUrl={a.photoUrl}
                      scene="lake"
                      spots={a.spotsLeft}
                      date={formatWhen(a.startsAt, a.timezone)}
                      place={a.location.venueName}
                    />
                  </a>
                </li>
              ))}
            </ul>
          </section>
        ) : (
          <p className="m-0 text-center text-muted md:text-left md:text-[16px]">
            {first} isn’t hosting anything right now.
          </p>
        )}

        <p className="m-0 flex items-start gap-2 text-caption text-muted md:items-center">
          <span className="mt-px inline-flex size-4 flex-none text-forest [&>svg]:size-4">
            <Icon name="lock" />
          </span>
          Profiles never show which activities someone has booked.
        </p>
      </main>
    </>
  );
}
