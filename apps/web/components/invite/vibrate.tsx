'use client';

import { useEffect } from 'react';

/** A short buzz on "You're in" where the browser supports it (Android Chrome); a progressive extra (S6 §4.4). */
export function Vibrate() {
  useEffect(() => {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    navigator.vibrate?.(40);
  }, []);
  return null;
}
