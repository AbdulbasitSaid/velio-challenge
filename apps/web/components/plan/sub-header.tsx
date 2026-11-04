// The back bar over B3 and B3b: back to the Plan, with the activity and its day.
import type { PlanView } from '@velio/contracts';
import { Icon } from '../primitives';
import { formatDay } from '@/lib/format';

export function PlanSubHeader({ plan }: { plan: PlanView }) {
  const a = plan.activity;
  return (
    <header className="mx-auto box-border flex w-full max-w-[480px] items-center gap-2 px-3 py-2">
      <a href={`/plans/${plan.id}`} className="vl-iconbtn" aria-label="Back to your plan">
        <Icon name="back" />
      </a>
      <span className="flex-1 text-[15px] font-bold">
        {a.title} · {formatDay(a.startsAt, a.timezone)}
      </span>
    </header>
  );
}
