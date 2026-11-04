import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import fixtures from '@velio/design-tokens/fixtures/avatar.json';
import {
  AttendanceRow,
  Avatar,
  AvatarStack,
  Banner,
  Button,
  ConfirmDialog,
  LocationBlock,
  MapView,
  MemberRow,
  Photo,
  photoSrcSet,
  PlanCard,
  Segmented,
  SpotsBadge,
  TextField,
} from '@/components';

describe('Photo (T16 D2)', () => {
  const src = '/photos/0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e01/aeb0c7c7-aa67-417b-88a9-aaa53a8e33bd.webp';
  test('uploaded photos offer the 640 px variant; cards size for it', () => {
    const small = src.replace('.webp', '-640.webp');
    expect(photoSrcSet(src)).toBe(`${small} 640w, ${src} 1280w`);
    const { container } = render(<Photo src={src} alt="" />);
    const img = container.querySelector('img')!;
    expect(img.getAttribute('srcset')).toBe(`${small} 640w, ${src} 1280w`);
    expect(img.getAttribute('sizes')).toBe('320px');
  });
  test('the hero sizes to the layout; other URLs get no srcset', () => {
    const { container } = render(<Photo src={src} alt="" priority />);
    expect(container.querySelector('img')!.getAttribute('sizes')).toBe('(min-width: 768px) 60vw, 45vw');
    expect(photoSrcSet('blob:http://x/1')).toBeUndefined();
    expect(photoSrcSet('/photos/a/b.gif')).toBeUndefined();
  });
});

describe('SpotsBadge', () => {
  test.each([
    [{ spots: 6 }, '6 spots left', 'vl-spots'],
    [{ spots: 6, state: 'changed' as const }, '6 spots left', 'vl-spots-changed'],
    [{ spots: 2 }, 'Last 2 spots', 'vl-spots-last'],
    [{ spots: 1 }, 'Last spot', 'vl-spots-last'],
    [{ spots: 0 }, 'Sold out', 'vl-spots-soldout'],
    [{ spots: 4, state: 'stale' as const }, 'Reconnecting…', 'vl-spots-stale'],
  ])('%o → %s', (props, text, cls) => {
    render(<SpotsBadge {...props} />);
    const badge = screen.getByText(text);
    expect(badge).toHaveClass(cls);
    // Announcements go through the page's single throttled live region, not the badge.
    expect(badge).not.toHaveAttribute('aria-live');
  });
});

describe('Avatar', () => {
  test.each(fixtures.filter((f) => f.seed))('seed $seed uses palette colour $index', ({ seed, index }) => {
    const colours = ['lime', 'sky', 'sun', 'lilac', 'peach'];
    const { container } = render(<Avatar name="Tunde A." seed={seed} />);
    expect((container.firstChild as HTMLElement).style.background).toBe(`var(--${colours[index]})`);
  });

  test('initials and accessible name', () => {
    render(<Avatar name="Tunde A." seed="x" />);
    expect(screen.getByTitle('Tunde A.')).toHaveTextContent('TA');
  });
});

describe('AvatarStack', () => {
  test.each([
    [[], undefined, 'Be the first to book'],
    [['Ama K.'], undefined, 'Ama K. is going'],
    [['Ama K.', 'Tunde A.'], undefined, 'Ama K. and Tunde A. are going'],
    [['Ama K.', 'Tunde A.', 'Kofi M.'], 7, 'Ama K., Tunde A. and 5 others are going'],
  ])('%o of %s', (names, total, label) => {
    render(<AvatarStack people={names.map((name) => ({ name }))} total={total} />);
    expect(screen.getByText(label)).toBeInTheDocument();
  });
});

describe('Button', () => {
  test('loading disables and marks busy', async () => {
    const onClick = vi.fn();
    render(
      <Button loading onClick={onClick}>
        Book
      </Button>,
    );
    const button = screen.getByRole('button', { name: 'Book' });
    expect(button).toBeDisabled();
    expect(button).toHaveAttribute('aria-busy', 'true');
    await userEvent.click(button);
    expect(onClick).not.toHaveBeenCalled();
  });

  test('external links open safely', () => {
    render(
      <Button href="https://maps.example" external>
        Go
      </Button>,
    );
    expect(screen.getByRole('link', { name: 'Go' })).toHaveAttribute('rel', 'noopener noreferrer');
  });
});

describe('TextField', () => {
  test('error is linked to the input', () => {
    render(<TextField label="Phone or email" error="Enter a phone number or email." />);
    const input = screen.getByLabelText('Phone or email');
    expect(input).toHaveAttribute('aria-invalid', 'true');
    expect(input).toHaveAccessibleDescription('Enter a phone number or email.');
  });

  test('count and controlled change', async () => {
    const onChange = vi.fn();
    render(<TextField label="Meeting point" maxLength={140} count={0} value="" onChange={onChange} />);
    expect(screen.getByText('0 / 140')).toBeInTheDocument();
    await userEvent.type(screen.getByLabelText('Meeting point'), 'a');
    expect(onChange).toHaveBeenCalledWith('a');
  });
});

test('Segmented reports the chosen option', async () => {
  const onChange = vi.fn();
  render(<Segmented label="View" value="List" options={['List', 'Map']} onChange={onChange} />);
  expect(screen.getByRole('button', { name: 'List' })).toHaveAttribute('aria-pressed', 'true');
  await userEvent.click(screen.getByRole('button', { name: 'Map' }));
  expect(onChange).toHaveBeenCalledWith('Map');
});

describe('rows', () => {
  test('MemberRow shows status and source', () => {
    render(<MemberRow name="Zainab Okafor" status="opened" source="vouch" you />);
    expect(screen.getByText('Zainab Okafor (you)')).toBeInTheDocument();
    expect(screen.getByText('Opened')).toBeInTheDocument();
    expect(screen.getByText('Vouch')).toBeInTheDocument();
  });

  test('AttendanceRow before start offers removal; after start offers marks', async () => {
    const onRemove = vi.fn();
    const onMark = vi.fn();
    const { rerender } = render(<AttendanceRow name="Ama K." onRemove={onRemove} />);
    await userEvent.click(screen.getByRole('button', { name: 'Remove' }));
    expect(onRemove).toHaveBeenCalled();
    rerender(<AttendanceRow name="Ama K." mode="after" mark="attended" onMark={onMark} />);
    expect(screen.getByRole('button', { name: 'Attended' })).toHaveAttribute('aria-pressed', 'true');
    await userEvent.click(screen.getByRole('button', { name: 'No-show' }));
    expect(onMark).toHaveBeenCalledWith('no_show');
  });

  test('PlanCard removed state', () => {
    render(<PlanCard title="Sunset Kayaking" href="/plans/1" removed />);
    expect(screen.getByText('Removed by host')).toBeInTheDocument();
  });
});

describe('maps', () => {
  test('LocationBlock links directions and shows the meeting point', () => {
    render(
      <LocationBlock
        venue="Boat Club"
        address="Moi South Lake Rd"
        meetingPoint="Blue gate"
        directionsUrl="https://www.google.com/maps/dir/?api=1&destination=1,2"
      />,
    );
    expect(screen.getByRole('link', { name: 'Get directions' })).toHaveAttribute(
      'href',
      'https://www.google.com/maps/dir/?api=1&destination=1,2',
    );
    expect(screen.getByText('Blue gate')).toBeInTheDocument();
  });

  test('static map image never sends a referrer', () => {
    const { container } = render(<MapView venue="Boat Club" staticMapUrl="https://maps.example/x.png" />);
    expect(container.querySelector('img')).toHaveAttribute('referrerpolicy', 'no-referrer');
  });

  test.each([
    ['failed', 'The map didn’t load. The address below still works.'],
    ['offline', 'Map unavailable offline'],
  ] as const)('%s state copy', (state, copy) => {
    render(<MapView state={state} />);
    expect(screen.getByText(copy)).toBeInTheDocument();
  });
});

test('ConfirmDialog wires both actions', async () => {
  const onConfirm = vi.fn();
  const onCancel = vi.fn();
  render(
    <ConfirmDialog
      title="Remove Ama?"
      body="Their spot opens up."
      confirm="Remove"
      destructive
      onConfirm={onConfirm}
      onCancel={onCancel}
    />,
  );
  expect(screen.getByRole('dialog', { name: 'Remove Ama?' })).toBeInTheDocument();
  await userEvent.click(screen.getByRole('button', { name: 'Remove' }));
  await userEvent.click(screen.getByRole('button', { name: 'Cancel' }));
  expect(onConfirm).toHaveBeenCalled();
  expect(onCancel).toHaveBeenCalled();
});

test('error Banner is an alert', () => {
  render(<Banner tone="error" title="Something went wrong" />);
  expect(screen.getByRole('alert')).toHaveTextContent('Something went wrong');
});
