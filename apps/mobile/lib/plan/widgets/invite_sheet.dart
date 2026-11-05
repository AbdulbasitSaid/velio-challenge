// The "Invite a friend" sheets (S7 FR-013; UI design F-B4): a vouch for one named friend, or the Plan's
// public link, both handed to the phone's share sheet. Velio sends nothing itself (PRD Notifications).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../../ui/components.dart';
import '../bloc/invite_sheet_bloc.dart';

class InviteSheet extends StatefulWidget {
  const InviteSheet({super.key, required this.activity});
  final PublicActivity activity;

  @override
  State<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<InviteSheet> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The contact never goes into the message; the guest picks the recipient in the share sheet.
  Future<void> _share(BuildContext context, InviteSheetState state) async {
    final navigator = Navigator.of(context);
    await SharePlus.instance.share(ShareParams(text: state.message!));
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final state = context.watch<InviteSheetBloc>().state;
    final bloc = context.read<InviteSheetBloc>();
    final l = state.link;
    return BlocListener<InviteSheetBloc, InviteSheetState>(
      listenWhen: (p, c) => p.message != c.message && c.message != null,
      listener: _share,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(VelioSpace.s5, VelioSpace.s3, VelioSpace.s5, VelioSpace.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: VelioColors.fieldBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: VelioSpace.s4),
                if (state.error != null) ...[
                  VBanner(tone: BannerTone.error, title: state.error!),
                  const SizedBox(height: VelioSpace.s3),
                ],
                ...switch (state.step) {
                  InviteSheetStep.choose => [
                    Text('Invite a friend', style: VelioText.heading),
                    const SizedBox(height: VelioSpace.s2),
                    Text(
                      'Invites don’t hold a spot, so tell friends now.',
                      style: VelioText.body.copyWith(color: VelioColors.muted),
                    ),
                    const SizedBox(height: VelioSpace.s4),
                    NextStepList([
                      NextStep(
                        icon: 'host',
                        title: 'Vouch for a friend',
                        meta: 'One invite, one person. It shows your name, so they know it’s from you.',
                        onTap: () => bloc.add(const InviteSheetVouchChosen()),
                      ),
                      NextStep(
                        icon: 'share',
                        title: 'Share a link',
                        meta: 'For a group chat. Anyone with it can claim a spot while spots last.',
                        onTap: () => bloc.add(const InviteSheetLinkRequested()),
                      ),
                    ]),
                  ],
                  InviteSheetStep.vouch => [
                    Text('Vouch for a friend', style: VelioText.heading),
                    const SizedBox(height: VelioSpace.s4),
                    VTextField(
                      label: 'Friend’s name',
                      controller: _name,
                      placeholder: 'Who is it for?',
                      error: state.nameError,
                      maxLength: 80,
                    ),
                    const SizedBox(height: VelioSpace.s4),
                    VTextField(
                      label: 'Their phone or email (optional)',
                      controller: _contact,
                      placeholder: '+254 7… or name@example.com',
                      help: 'Used only to send and match this invite. ${firstName(a.host.shortName)} never sees it.',
                      error: state.contactError,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: VelioSpace.s4),
                    VTextField(
                      label: 'Note (optional)',
                      controller: _note,
                      placeholder: 'A line from you, shown on their invite',
                      multiline: true,
                      maxLength: 280,
                    ),
                    const SizedBox(height: VelioSpace.s5),
                    VButton(
                      state.busy ? 'Creating…' : 'Create and share',
                      block: true,
                      loading: state.busy,
                      onPressed: () => bloc.add(
                        InviteSheetVouchSubmitted(name: _name.text, contact: _contact.text, note: _note.text),
                      ),
                    ),
                  ],
                  InviteSheetStep.link => [
                    Text('Your link', style: VelioText.heading),
                    const SizedBox(height: VelioSpace.s3),
                    if (l == null && state.busy)
                      const Skeleton(height: 52, radius: VelioRadius.field)
                    else if (l != null && l.paused) ...[
                      VBanner(
                        title: l.pausedReason == PauseReason.host
                            ? 'The host paused this link.'
                            : 'You paused this link.',
                        body: l.pausedReason == PauseReason.host
                            ? 'Bookings already made are safe. Vouch invites still work.'
                            : 'Nobody can claim from it until you resume it. Bookings already made are safe.',
                      ),
                      if (l.pausedReason != PauseReason.host) ...[
                        const SizedBox(height: VelioSpace.s3),
                        VButton(
                          'Resume link',
                          block: true,
                          loading: state.busy,
                          onPressed: () => bloc.add(const InviteSheetResumePressed()),
                        ),
                      ],
                    ] else if (l != null) ...[
                      SelectableText(l.link.replaceFirst(RegExp(r'^https?://'), ''), style: VelioText.bodyStrong),
                      const SizedBox(height: VelioSpace.s4),
                      VButton(
                        'Share',
                        icon: 'share',
                        block: true,
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(text: 'Join the group going to ${a.title}: ${l.link}'),
                        ),
                      ),
                    ],
                  ],
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}
