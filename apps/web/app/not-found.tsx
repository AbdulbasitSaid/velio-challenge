import { ErrorScreen } from '@/components/error-screen';
import { SiteHeader } from './site-header';

export default function NotFound() {
  return (
    <>
      <SiteHeader />
      <ErrorScreen
        code="404"
        headline="This page doesn't exist."
        body="The link may be old or mistyped. Your plans and invites are where you left them."
      />
    </>
  );
}
