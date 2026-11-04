// Sending invites from the booker's own phone or computer (PRD I3, Notifications): Velio sends nothing.
// The contact never goes into a URL (SEC-002): WhatsApp and SMS open with only the message, and the
// booker picks the recipient there.
import { firstName, formatDay } from './format';

/** Copy deck `vouch.message`. */
export function vouchMessage(
  inviteeName: string,
  activity: { title: string; startsAt: string; timezone: string },
  link: string,
): string {
  return `${firstName(inviteeName)}, I’m going to ${activity.title} on ${formatDay(activity.startsAt, activity.timezone)} and want you there. Claim your spot: ${link}`;
}

/** "d3x9k2.cloudfront.net/i/H4XM9R": the link as people read it. */
export function displayLink(link: string): string {
  return link.replace(/^https?:\/\//, '');
}

export function smsHref(text: string): string {
  return `sms:?&body=${encodeURIComponent(text)}`;
}

/** Resolves false when the browser refuses (no permission, insecure origin). */
export async function copyText(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    return false;
  }
}

/** The Web Share API, where the browser has it; false when it's missing or the share is cancelled. */
export async function nativeShare(data: { title?: string; text?: string; url?: string }): Promise<boolean> {
  if (typeof navigator === 'undefined' || typeof navigator.share !== 'function') return false;
  try {
    await navigator.share(data);
    return true;
  } catch {
    return false;
  }
}

export function canNativeShare(): boolean {
  return typeof navigator !== 'undefined' && typeof navigator.share === 'function';
}
