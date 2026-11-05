// /admin (S8 FR-014): not linked from anywhere and not indexed; everything behind the admin token.
import type { Metadata } from 'next';
import { AdminConsole } from '@/components/admin/admin-console';

export const metadata: Metadata = { title: 'Admin', robots: { index: false, follow: false } };

export default function AdminPage() {
  return <AdminConsole />;
}
