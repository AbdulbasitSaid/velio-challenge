// B6 loading state: shown while the server fetches the Plans.
import { SiteHeader } from '../../site-header';
import { Skeleton } from '@/components';

export default function Loading() {
  return (
    <>
      <SiteHeader current="My plans" />
      <main
        className="mx-auto flex w-full max-w-content flex-col gap-5 px-5 pt-1 pb-8 md:px-10 md:pt-8"
        aria-busy
        aria-label="Loading your plans"
      >
        <h1 className="m-0 text-title md:text-[36px] md:leading-[42px]">My plans</h1>
        <div className="vl-list">
          <Skeleton variant="row" />
          <Skeleton variant="row" />
          <Skeleton variant="row" />
        </div>
      </main>
    </>
  );
}
