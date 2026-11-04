// X1 sign in (S7 FR-017, PRD Q14): name and the phone or email used before, so My plans works on a
// new phone. Only a masked contact is kept on the device (SEC-002).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/identity.dart';
import '../core/invite_logic.dart';
import '../core/online.dart';
import '../core/providers.dart';
import '../ui/components.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.next});

  /// Where to go after signing in; only app paths are accepted.
  final String? next;
  @override
  ConsumerState<SignInScreen> createState() => _SignInState();
}

class _SignInState extends ConsumerState<SignInScreen> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  bool _busy = false;
  String? _nameError;
  String? _contactError;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final contact = _contact.text.trim();
    setState(() {
      _nameError = name.isEmpty ? nameError : null;
      _contactError = contact.isEmpty ? contactError : null;
      _error = null;
    });
    if (name.isEmpty || contact.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await ref.read(apiProvider).signIn(name, contact);
      await ref
          .read(identityProvider)
          .signIn(
            res.token!,
            LocalProfile(userId: res.user.id, displayName: res.user.displayName, maskedContact: maskContact(contact)),
          );
      ref.read(sessionVersionProvider.notifier).state++;
      if (!mounted) return;
      final next = widget.next;
      context.go(next != null && next.startsWith('/') && !next.startsWith('//') ? next : '/me/plans');
    } on ApiException catch (e) {
      setState(() {
        if (e.code == 'invalid_contact') {
          _contactError = 'Enter a phone number with country code, or a full email address.';
        } else if (e.code == 'validation_failed') {
          _nameError = nameError;
        } else {
          _error = e.network ? 'Check your connection and try again.' : 'We couldn’t sign you in.';
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = isOnline(ref);
    return Scaffold(
      appBar: VAppBar(
        leading: VIconButton(
          'back',
          label: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: 'Sign in',
      ),
      body: SafeArea(
        top: false,
        child: AutofillGroup(
          child: ScreenBody(
            children: [
              Semantics(header: true, child: Text('Continue to Velio', style: VelioText.title)),
              Text(
                'Your name and a phone number or email. No password.',
                style: VelioText.body.copyWith(color: VelioColors.muted),
              ),
              if (_error != null) VBanner(tone: BannerTone.error, title: _error!),
              VTextField(
                label: 'Your name',
                controller: _name,
                placeholder: 'First and last name',
                help: 'Others see your first name and last initial.',
                error: _nameError,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
              ),
              VTextField(
                label: 'Phone or email',
                controller: _contact,
                keyboardType: TextInputType.emailAddress,
                placeholder: '+254 7… or you@example.com',
                help: 'Use the same one on every device to see your plans. We don’t message you.',
                error: _contactError,
                autofillHints: const [AutofillHints.telephoneNumber, AutofillHints.email],
                onSubmitted: (_) => _submit(),
              ),
              VButton(
                _busy
                    ? 'Continuing…'
                    : online
                    ? 'Continue'
                    : 'Reconnect to continue',
                block: true,
                loading: _busy,
                onPressed: online ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
