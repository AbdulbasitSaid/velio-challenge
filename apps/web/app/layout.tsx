import type { Metadata, Viewport } from 'next';
import { DM_Sans, Sora } from 'next/font/google';
import type { ReactNode } from 'react';
import { RealtimeProvider } from '@/lib/realtime/react';
import { WebVitals } from '@/lib/telemetry/web-vitals';
import './globals.css';

// next/font downloads these OFL faces at build time and serves them from our origin (S5 FR-004).
const sora = Sora({ subsets: ['latin'], weight: ['700'], display: 'swap', variable: '--font-sora' });
const dmSans = DM_Sans({
  subsets: ['latin'],
  weight: ['400', '700'],
  display: 'swap',
  variable: '--font-dm-sans',
});

export const metadata: Metadata = {
  title: { default: 'Velio', template: '%s · Velio' },
};

export const viewport: Viewport = {
  themeColor: '#f5f3ec',
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={`${sora.variable} ${dmSans.variable}`}>
      <body className="min-h-dvh bg-cream text-body text-ink antialiased">
        <WebVitals />
        <RealtimeProvider>{children}</RealtimeProvider>
      </body>
    </html>
  );
}
