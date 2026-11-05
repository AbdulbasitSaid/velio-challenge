// Opens the "Invite a friend" sheet as its own route, with its bloc (S7 FR-013).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../repositories/plan_repository.dart';
import '../bloc/invite_sheet_bloc.dart';
import '../widgets/invite_sheet.dart';

Future<void> showInviteSheet(BuildContext context, PlanView plan, PublicActivity a) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: VelioColors.surface,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VelioRadius.hero))),
  builder: (_) => BlocProvider(
    create: (_) => InviteSheetBloc(planRepository: context.read<PlanRepository>(), plan: plan, activity: a),
    child: InviteSheet(activity: a),
  ),
);
