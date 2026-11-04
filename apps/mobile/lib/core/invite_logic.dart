// Which invite screen shows (S6 §4.3, the same order as apps/web/lib/invite-screen.ts) and what a
// claim rejection means (S6 FR-009, apps/web/components/invite/claim-form.tsx). Pure, so every row
// is unit-tested (S7 V-INV-1, V-ERR-1).
import 'package:velio_api/velio_api.dart';

enum OpenBlock { none, host, alreadyGoing, bookingsPaused }

sealed class InviteScreen {
  const InviteScreen();
}

/// G7: claimed by this guest (own) or by someone else.
class ClaimedScreen extends InviteScreen {
  const ClaimedScreen({required this.own});
  final bool own;
}

/// G6: the invite expired at the start time.
class ExpiredScreen extends InviteScreen {
  const ExpiredScreen();
}

/// A public link paused by its creator, the host or the auto-pause (S6 §12 Q2).
class PausedScreen extends InviteScreen {
  const PausedScreen();
}

/// G5: sold out isn't an invite state (PRD Lifecycles), so this follows the live count.
class SoldOutScreen extends InviteScreen {
  const SoldOutScreen();
}

/// G1 (vouch) or G2 (public), with Claim blocked for the host, someone already going, or paused bookings.
class OpenScreen extends InviteScreen {
  const OpenScreen(this.block);
  final OpenBlock block;
}

InviteScreen selectScreen(InviteView view, {int? spotsLeft}) {
  final spots = spotsLeft ?? view.activity.spotsLeft;
  if (view.status == InviteViewStatusEnum.claimed) return ClaimedScreen(own: view.claimedByViewer);
  if (view.status == InviteViewStatusEnum.expired || view.activity.status == PublicActivityStatusEnum.started) {
    return const ExpiredScreen();
  }
  if (view.status == InviteViewStatusEnum.paused) return const PausedScreen();
  final viewer = view.activity.viewer;
  if (viewer?.isHost ?? false) return const OpenScreen(OpenBlock.host);
  if (viewer?.booking?.status == PublicActivityViewerBookingStatusEnum.confirmed) {
    return const OpenScreen(OpenBlock.alreadyGoing);
  }
  if (spots <= 0) return const SoldOutScreen();
  if (view.activity.bookingsPaused) return const OpenScreen(OpenBlock.bookingsPaused);
  return const OpenScreen(OpenBlock.none);
}

sealed class ClaimOutcome {
  const ClaimOutcome();
}

/// Booked (or already booked from another device): go to You're in or the Plan.
class ClaimDone extends ClaimOutcome {
  const ClaimDone();
}

/// The invite screen already shows this state (expired, paused, claimed, host): go back to it.
class ClaimBack extends ClaimOutcome {
  const ClaimBack();
}

class ClaimFieldError extends ClaimOutcome {
  const ClaimFieldError(this.field, this.message);
  final String field;
  final String message;
}

class ClaimBanner extends ClaimOutcome {
  const ClaimBanner(this.title, this.body, {required this.retry, this.soldOut = false});
  final String title;
  final String body;

  /// Offer "Try again" with the same idempotency key (server error, network).
  final bool retry;

  /// Lands on sold out: the distinct haptic (PRD M3).
  final bool soldOut;
}

const contactError = 'Enter a full phone number with country code, or an email address.';
const nameError = 'Enter your name.';

/// [code] is the API's error code; null for a network failure or an unexpected answer.
ClaimOutcome claimOutcome(String? code) => switch (code) {
  'invalid_contact' => const ClaimFieldError('contact', contactError),
  'validation_failed' => const ClaimFieldError('name', nameError),
  'sold_out' => const ClaimBanner(
    'Someone just took the last spot.',
    'We didn’t book you. Go back to see other dates and activities.',
    retry: false,
    soldOut: true,
  ),
  'rate_limited' => const ClaimBanner(
    'Too many attempts from this device.',
    'Try again in an hour. Your invite still works.',
    retry: false,
  ),
  'bookings_paused' => const ClaimBanner(
    'Bookings are paused for this activity.',
    'Nothing has changed for people already going. Check back soon.',
    retry: false,
  ),
  'booking_removed' => const ClaimBanner(
    'The host removed your booking for this activity.',
    'Your spot was released. You can still book another date.',
    retry: false,
  ),
  'already_booked' => const ClaimDone(),
  'invite_expired' ||
  'invite_paused' ||
  'already_claimed' ||
  'activity_started' ||
  'forbidden' ||
  'invalid_code' ||
  'not_found' => const ClaimBack(),
  _ => const ClaimBanner(
    'We couldn’t confirm your spot. Nothing was booked.',
    'Try again. You won’t be booked twice.',
    retry: true,
  ),
};
