// Avatar colour from a person's avatarSeed. The prototype's hash (djb2 over UTF-16 code units, unsigned 32-bit)
// so production matches the approved canvas; the Dart output implements the same function and shares
// fixtures/avatar.json (MVP FR-032).
export const AVATAR_COLORS = ['lime', 'sky', 'sun', 'lilac', 'peach'] as const;
export type AvatarColor = (typeof AVATAR_COLORS)[number];

export function avatarIndex(seed: string): number {
  let x = 5381;
  for (let i = 0; i < seed.length; i++) x = ((x << 5) + x + seed.charCodeAt(i)) >>> 0;
  return x % AVATAR_COLORS.length;
}

export function avatarColor(seed: string): AvatarColor {
  return AVATAR_COLORS[avatarIndex(seed)]!;
}

export function initials(name: string): string {
  const parts = name.replace(/\./g, '').trim().split(/\s+/);
  const first = parts[0]?.[0] ?? '?';
  const last = parts.length > 1 ? (parts[parts.length - 1]?.[0] ?? '') : '';
  return (first + last).toUpperCase();
}
