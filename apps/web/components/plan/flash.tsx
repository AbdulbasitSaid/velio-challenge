'use client';

// A short-lived toast pinned to the bottom of the screen ("Link copied"). The Toast is its own status
// region, so screen readers hear it without moving focus.
import { useCallback, useEffect, useRef, useState, useSyncExternalStore } from 'react';
import { Toast } from '../feedback';
import { canNativeShare } from '@/lib/share';

export const FLASH_MS = 2_500;

export function useFlash(): [node: React.ReactNode, show: (message: string) => void] {
  const [message, setMessage] = useState<string | null>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const show = useCallback((m: string) => {
    if (timer.current) clearTimeout(timer.current);
    setMessage(m);
    timer.current = setTimeout(() => setMessage(null), FLASH_MS);
  }, []);
  useEffect(() => () => void (timer.current && clearTimeout(timer.current)), []);
  const node = message ? (
    <div className="pointer-events-none fixed inset-x-0 bottom-8 z-50 flex justify-center">
      <Toast>{message}</Toast>
    </div>
  ) : null;
  return [node, show];
}

const noSubscribe = () => () => undefined;

/** A browser capability: false on the server and before hydration, so the first client render matches. */
export function useBrowserValue(read: () => boolean): boolean {
  return useSyncExternalStore(noSubscribe, read, () => false);
}

export function useCanShare(): boolean {
  return useBrowserValue(canNativeShare);
}
