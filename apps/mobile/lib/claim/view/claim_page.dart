// G3 claim (S7 FR-010, FR-012, FR-016; UI design F-G3). Two fields for a new guest, or "Claiming as
// {Name} / {masked contact} · saved on this phone / Not you?". Offline, Claim waits: nothing is
// queued (PRD M2).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../connectivity/cubit/connectivity_cubit.dart';
import '../../domain/format.dart';
import '../../repositories/invite_repository.dart';
import '../../repositories/session_repository.dart';
import '../../session/bloc/session_bloc.dart';
import '../../ui/components.dart';
import '../bloc/claim_bloc.dart';
import '../widgets/claim_summary.dart';
import '../widgets/claiming_as.dart';

class ClaimPage extends StatelessWidget {
  const ClaimPage({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ClaimBloc(
      inviteRepository: context.read<InviteRepository>(),
      sessionRepository: context.read<SessionRepository>(),
      code: code,
    )..add(const ClaimRequested()),
    child: ClaimView(code: code),
  );
}

class ClaimView extends StatefulWidget {
  const ClaimView({super.key, required this.code});
  final String code;

  @override
  State<ClaimView> createState() => _ClaimViewState();
}

class _ClaimViewState extends State<ClaimView> {
  final _name = TextEditingController();
  final _contact = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _submit() => context.read<ClaimBloc>().add(ClaimSubmitted(name: _name.text, contact: _contact.text));

  void _onResult(BuildContext context, ClaimState state) {
    switch (state.result) {
      case ClaimResult.claimed:
        HapticFeedback.mediumImpact(); // PRD M3
        context.pushReplacement('/i/${widget.code}/in/${state.planId}');
      case ClaimResult.alreadyGoing:
        context.pushReplacement('/i/${widget.code}');
      case ClaimResult.back:
        context.pop();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = context.select((ConnectivityCubit c) => c.state);
    final profile = context.select((SessionBloc b) => b.state.profile);
    final state = context.watch<ClaimBloc>().state;
    final view = state.view;
    final a = view?.activity;
    final banner = state.banner;
    final host = a == null ? 'The host' : firstName(a.host.shortName);
    final disclosure = view == null
        ? null
        : view.rail == InviteViewRailEnum.vouch
        ? '$host (the host) will see your name and that ${firstName(view.inviter.shortName)} invited you. Your phone or email stays private.'
        : '$host (the host) will see your name and that you joined from a public link. Your phone or email stays private.';

    return MultiBlocListener(
      listeners: [
        BlocListener<ClaimBloc, ClaimState>(listenWhen: (p, c) => p.results != c.results, listener: _onResult),
        // PRD M3: the distinct haptic as the claim lands on sold out.
        BlocListener<ClaimBloc, ClaimState>(
          listenWhen: (p, c) => p.banner != c.banner && (c.banner?.soldOut ?? false),
          listener: (_, _) => HapticFeedback.heavyImpact(),
        ),
      ],
      child: Scaffold(
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
                if (a != null) ClaimSummary(activity: a),
                if (!online)
                  const VBanner(
                    tone: BannerTone.offline,
                    title: 'You’re offline',
                    body: 'Reconnect to claim. Nothing was booked.',
                  ),
                if (banner != null) VBanner(tone: BannerTone.error, title: banner.title, body: banner.body),
                if (state.signedIn && profile != null)
                  ClaimingAs(
                    displayName: profile.displayName,
                    maskedContact: profile.maskedContact,
                    onNotYou: state.submitting ? null : () => context.read<ClaimBloc>().add(const ClaimNotYouPressed()),
                  )
                else ...[
                  VTextField(
                    label: 'Your name',
                    controller: _name,
                    placeholder: 'First and last name',
                    help: 'The host and the people in your group see this.',
                    error: state.nameError,
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    maxLength: 80,
                  ),
                  VTextField(
                    label: 'Phone or email',
                    controller: _contact,
                    keyboardType: TextInputType.emailAddress,
                    help: 'So you can find this booking again. We don’t message you.',
                    error: state.contactError,
                    autofillHints: const [AutofillHints.telephoneNumber, AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
                if (disclosure != null) VBanner(title: 'What the host sees', body: disclosure),
                VButton(
                  state.submitting
                      ? 'Confirming…'
                      : !online
                      ? 'Reconnect to claim'
                      : banner?.retry ?? false
                      ? 'Try again'
                      : 'Confirm my spot',
                  block: true,
                  loading: state.submitting,
                  onPressed: online && !state.blocked ? _submit : null,
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
      ),
    );
  }
}
