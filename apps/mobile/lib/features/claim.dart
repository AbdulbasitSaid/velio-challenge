// G3 claim (S7 FR-010, FR-012, FR-016; UI design F-G3). Two fields for a new guest, or "Claiming as
// {Name} / {masked contact} · saved on this phone / Not you?". One Idempotency-Key per attempt, kept
// for the code until a final outcome so a retry or a restart during a slow claim never books twice.
// Offline, Claim waits: nothing is queued (PRD M2).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/identity.dart';
import '../core/invite_logic.dart';
import '../core/online.dart';
import '../core/providers.dart';
import '../ui/art.dart';
import '../ui/components.dart';

/// The attempt's key, reused until the claim succeeds or fails for good (V-CLM-1).
class AttemptKeys {
  AttemptKeys(this._prefs);
  final SharedPreferencesAsync _prefs;

  Future<String> forCode(String code) async {
    final k = 'velio.claim_key.$code';
    final existing = await _prefs.getString(k);
    if (existing != null) return existing;
    final key = const Uuid().v4();
    await _prefs.setString(k, key);
    return key;
  }

  Future<void> clear(String code) => _prefs.remove('velio.claim_key.$code');
}

final attemptKeysProvider = Provider<AttemptKeys>((ref) => AttemptKeys(SharedPreferencesAsync()));

class ClaimScreen extends ConsumerStatefulWidget {
  const ClaimScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<ClaimScreen> createState() => _ClaimState();
}

class _ClaimState extends ConsumerState<ClaimScreen> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  InviteView? _view;
  bool _submitting = false;
  String? _nameError;
  String? _contactError;
  ClaimBanner? _banner;

  /// "Claiming as" needs the saved name; without it the guest fills the two fields.
  late bool _signedIn = ref.read(identityProvider).profile != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = await ref.read(cacheProvider).invite(widget.code);
    if (cached != null && mounted) setState(() => _view = cached.value);
    try {
      final v = await ref.read(apiProvider).invite(widget.code);
      if (mounted) setState(() => _view = v);
    } catch (_) {
      // The cached copy is enough to show what's being claimed.
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _notYou() async {
    await ref.read(apiProvider).signOut();
    await ref.read(identityProvider).signOut();
    await ref.read(cacheProvider).clearMyPlans();
    ref.read(sessionVersionProvider.notifier).state++;
    if (mounted) setState(() => _signedIn = false);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _name.text.trim();
    final contact = _contact.text.trim();
    if (!_signedIn && (name.isEmpty || contact.isEmpty)) {
      setState(() {
        _nameError = name.isEmpty ? nameError : null;
        _contactError = contact.isEmpty ? contactError : null;
      });
      return;
    }
    setState(() {
      _submitting = true;
      _nameError = null;
      _contactError = null;
      _banner = null;
    });
    final keys = ref.read(attemptKeysProvider);
    final api = ref.read(apiProvider);
    try {
      final res = await api.claim(
        widget.code,
        idempotencyKey: await keys.forCode(widget.code),
        platform: ref.read(platformProvider),
        displayName: _signedIn ? null : name,
        contact: _signedIn ? null : contact,
      );
      await keys.clear(widget.code);
      final token = res.token;
      if (token != null) {
        await ref
            .read(identityProvider)
            .signIn(
              token,
              LocalProfile(userId: res.user.id, displayName: res.user.displayName, maskedContact: maskContact(contact)),
            );
        ref.read(sessionVersionProvider.notifier).state++;
      }
      HapticFeedback.mediumImpact(); // PRD M3
      if (mounted) context.pushReplacement('/i/${widget.code}/in/${res.planId}');
    } on ApiException catch (e) {
      final outcome = claimOutcome(e.network ? null : e.code);
      if (outcome is! ClaimBanner || !outcome.retry) await keys.clear(widget.code);
      if (!mounted) return;
      switch (outcome) {
        case ClaimDone():
          // Already booked from another device: the invite shows "You're already going" with the plan.
          context.pushReplacement('/i/${widget.code}');
        case ClaimBack():
          context.pop();
        case ClaimFieldError(:final field, :final message):
          setState(() => field == 'contact' ? _contactError = message : _nameError = message);
        case ClaimBanner():
          if (outcome.soldOut) HapticFeedback.heavyImpact();
          setState(() => _banner = outcome);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = isOnline(ref);
    final view = _view;
    final a = view?.activity;
    final profile = ref.read(identityProvider).profile;
    final banner = _banner;
    final blocked = banner != null && !banner.retry;
    final host = a == null ? 'The host' : firstName(a.host.shortName);
    final disclosure = view == null
        ? null
        : view.rail == InviteViewRailEnum.vouch
        ? '$host (the host) will see your name and that ${firstName(view.inviter.shortName)} invited you. Your phone or email stays private.'
        : '$host (the host) will see your name and that you joined from a public link. Your phone or email stays private.';

    return Scaffold(
      appBar: VAppBar(
        leading: VIconButton('back', label: 'Back', onPressed: () => context.pop()),
        title: 'Claim your spot',
        trailing: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Semantics(
            label: 'Invite code ${widget.code.split('').join(' ')}',
            child: ExcludeSemantics(child: VChip(widget.code)),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: AutofillGroup(
          child: ScreenBody(
            children: [
              if (a != null)
                Container(
                  padding: const EdgeInsets.all(VelioSpace.s3),
                  decoration: BoxDecoration(
                    color: VelioColors.surface,
                    borderRadius: BorderRadius.circular(VelioRadius.card),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(VelioRadius.small),
                        child: SizedBox.square(dimension: 56, child: Photo(url: a.photoUrl, small: true)),
                      ),
                      const SizedBox(width: VelioSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: VelioText.bodyStrong.copyWith(fontSize: 16)),
                            Text(
                              '${formatWhen(a.startsAt, a.timezone)} ${zoneLabel(a.timezone)}',
                              style: VelioText.caption.copyWith(color: VelioColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (!online)
                const VBanner(
                  tone: BannerTone.offline,
                  title: 'You’re offline',
                  body: 'Reconnect to claim. Nothing was booked.',
                ),
              if (banner != null) VBanner(tone: BannerTone.error, title: banner.title, body: banner.body),
              if (_signedIn && profile != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: 14),
                  decoration: BoxDecoration(
                    color: VelioColors.surface,
                    borderRadius: BorderRadius.circular(VelioRadius.card),
                  ),
                  child: Row(
                    children: [
                      Avatar(name: profile.displayName, size: 44),
                      const SizedBox(width: VelioSpace.s3),
                      // "Not you?" moves under the name when large text leaves no room beside it.
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: VelioSpace.s2,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Claiming as ${profile.displayName}', style: VelioText.bodyStrong),
                                Text(
                                  '${profile.maskedContact} · saved on this phone',
                                  style: VelioText.caption.copyWith(color: VelioColors.muted),
                                ),
                              ],
                            ),
                            VButton(
                              'Not you?',
                              variant: ButtonVariant.quiet,
                              small: true,
                              onPressed: _submitting ? null : _notYou,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                VTextField(
                  label: 'Your name',
                  controller: _name,
                  placeholder: 'First and last name',
                  help: 'The host and the people in your group see this.',
                  error: _nameError,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                ),
                VTextField(
                  label: 'Phone or email',
                  controller: _contact,
                  keyboardType: TextInputType.emailAddress,
                  help: 'So you can find this booking again. We don’t message you.',
                  error: _contactError,
                  autofillHints: const [AutofillHints.telephoneNumber, AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ],
              if (disclosure != null) VBanner(title: 'What the host sees', body: disclosure),
              VButton(
                _submitting
                    ? 'Confirming…'
                    : !online
                    ? 'Reconnect to claim'
                    : banner?.retry ?? false
                    ? 'Try again'
                    : 'Confirm my spot',
                block: true,
                loading: _submitting,
                onPressed: online && !blocked ? _submit : null,
              ),
              Text(
                'Spots aren’t held. Claim while they last.',
                textAlign: TextAlign.center,
                style: VelioText.caption.copyWith(color: VelioColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
