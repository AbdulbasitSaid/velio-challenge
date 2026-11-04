'use client';

import { useRouter } from 'next/navigation';
import { useState, type FormEvent } from 'react';
import { Banner, Button, TextField } from '@/components';
import { ApiRequestError, apiFetch } from '@/lib/api/client';

const CONTACT_ERROR = 'Enter a phone number with country code, or a full email address.';

export function SignInForm({ next }: { next: string }) {
  const router = useRouter();
  const [name, setName] = useState('');
  const [contact, setContact] = useState('');
  const [nameError, setNameError] = useState<string | null>(null);
  const [contactError, setContactError] = useState<string | null>(null);
  const [serverError, setServerError] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    const displayName = name.trim();
    const value = contact.trim();
    setNameError(displayName ? null : 'Enter your name.');
    setContactError(value ? null : CONTACT_ERROR);
    if (!displayName || !value) return;

    setSubmitting(true);
    setServerError(false);
    try {
      await apiFetch('/sessions', {
        method: 'POST',
        body: { displayName, contact: value },
        headers: { 'x-client': 'web' },
      });
      router.replace(next);
      router.refresh();
    } catch (err) {
      setSubmitting(false);
      if (err instanceof ApiRequestError && err.code === 'invalid_contact') setContactError(CONTACT_ERROR);
      else if (err instanceof ApiRequestError && err.code === 'validation_failed')
        setNameError('Enter your name.');
      else setServerError(true);
    }
  }

  return (
    <form
      onSubmit={submit}
      noValidate
      className="flex w-full min-w-0 flex-[1_1_380px] flex-col gap-4 md:max-w-[440px] md:rounded-hero md:bg-surface md:p-7"
    >
      <div className="flex flex-col gap-2">
        <h1 className="m-0 text-title md:text-heading">Continue to Velio</h1>
        <p className="m-0 text-muted">Your name and a phone number or email. No password.</p>
      </div>
      {serverError ? (
        <Banner tone="error" title="We couldn't sign you in.">
          Check your connection and try again.
        </Banner>
      ) : null}
      <TextField
        id="x1-name"
        label="Your name"
        value={name}
        onChange={setName}
        placeholder="First and last name"
        autoComplete="name"
        maxLength={100}
        error={nameError}
        help="Others see your first name and last initial."
      />
      <TextField
        id="x1-contact"
        label="Phone or email"
        value={contact}
        onChange={setContact}
        placeholder="+254 7… or you@example.com"
        autoComplete="email"
        maxLength={254}
        error={contactError}
        help="Use the same one on every device to see your plans. We don't message you."
      />
      <Button type="submit" block loading={submitting}>
        {submitting ? 'Continuing…' : 'Continue'}
      </Button>
    </form>
  );
}
