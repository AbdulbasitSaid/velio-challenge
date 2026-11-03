import type { MemberPerson, PublicPerson } from '@velio/contracts';

interface PersonRow {
  id: string;
  display_name: string;
}

/** "Tunde Adeyemi" → "Tunde A." (PRD Q12). A single name is returned as is. */
export function shortName(displayName: string): string {
  const parts = displayName.trim().split(/\s+/);
  const first = parts[0] ?? '';
  if (parts.length < 2) return first;
  const initial = Array.from(parts[parts.length - 1]!)[0]!.toUpperCase();
  return `${first} ${initial}.`;
}

export function toPublicPerson(user: PersonRow): PublicPerson {
  return { id: user.id, shortName: shortName(user.display_name), avatarSeed: user.id };
}

export function toMemberPerson(user: PersonRow): MemberPerson {
  return { ...toPublicPerson(user), displayName: user.display_name };
}
