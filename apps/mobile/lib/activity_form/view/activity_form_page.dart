// H2 create and edit (S7b FR-007–FR-010; web activity-form.tsx; PRD A1, A4, Q2, Q13). Copy-deck
// validation with a summary, a preview card, the location picker, and the photo uploaded straight to
// the bucket. After the first booking, date, time, zone and place show locked; the API's
// `location_locked` and `capacity_below_bookings` land on their fields. Price and community are set
// once: the API has no edit for them.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../app/config.dart';
import '../../domain/load_error.dart';
import '../../repositories/host_repository.dart';
import '../../session/bloc/session_bloc.dart';
import '../../ui/components.dart';
import '../../ui/error_screen.dart';
import '../bloc/activity_form_bloc.dart';
import '../widgets/activity_form_back_button.dart';
import '../widgets/activity_form_content.dart';

class ActivityFormPage extends StatelessWidget {
  const ActivityFormPage({super.key, this.id, this.published = false});

  /// Null when creating.
  final String? id;

  /// Straight after publishing (`?published=1`).
  final bool published;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        ActivityFormBloc(hostRepository: context.read<HostRepository>(), id: id, clock: context.read<AppConfig>().clock)
          ..add(const ActivityFormRequested()),
    child: ActivityFormView(published: published),
  );
}

class ActivityFormView extends StatefulWidget {
  const ActivityFormView({super.key, this.published = false});
  final bool published;

  @override
  State<ActivityFormView> createState() => _ActivityFormViewState();
}

class _ActivityFormViewState extends State<ActivityFormView> {
  final _scroll = ScrollController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _meeting = TextEditingController();
  final _price = TextEditingController();
  final _capacity = TextEditingController();

  @override
  void dispose() {
    for (final c in [_title, _description, _meeting, _price, _capacity]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() => _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select((SessionBloc b) => b.state.signedIn);
    if (!signedIn) {
      return Scaffold(
        appBar: const VAppBar(leading: ActivityFormBackButton(), title: 'Host'),
        body: ScreenBody(
          children: [
            const EmptyState(
              icon: 'host',
              title: 'Host on Velio',
              body: 'Continue with your phone or email to create activities.',
            ),
            VButton(
              'Continue with your phone or email',
              block: true,
              onPressed: () => context.push('/signin?next=/host'),
            ),
          ],
        ),
      );
    }
    return MultiBlocListener(
      listeners: [
        // The loaded values go into the text fields once.
        BlocListener<ActivityFormBloc, ActivityFormState>(
          listenWhen: (a, b) => a.loaded != b.loaded,
          listener: (context, state) {
            final form = state.form!;
            _title.text = form.title;
            _description.text = form.description;
            _meeting.text = form.meetingPoint;
            _price.text = form.price;
            _capacity.text = '${form.capacity ?? ''}';
          },
        ),
        BlocListener<ActivityFormBloc, ActivityFormState>(
          listenWhen: (a, b) => a.scrolls != b.scrolls,
          listener: (context, state) => _toTop(),
        ),
        BlocListener<ActivityFormBloc, ActivityFormState>(
          listenWhen: (a, b) => a.saves != b.saves,
          listener: (context, state) =>
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved'))),
        ),
        BlocListener<ActivityFormBloc, ActivityFormState>(
          listenWhen: (a, b) => a.publishedId != b.publishedId && b.publishedId != null,
          listener: (context, state) => context.pushReplacement('/host/${state.publishedId}/edit?published=1'),
        ),
      ],
      child: BlocBuilder<ActivityFormBloc, ActivityFormState>(
        builder: (context, state) {
          final err = state.error;
          if (!state.ready) {
            if (err != null) {
              final notFound = err == LoadError.notFound;
              return ErrorScreen(
                kind: notFound ? ErrorKind.notFound : (err == LoadError.offline ? ErrorKind.offline : ErrorKind.server),
                onRetry: notFound ? null : () => context.read<ActivityFormBloc>().add(const ActivityFormRequested()),
              );
            }
            return Scaffold(
              appBar: VAppBar(
                leading: const ActivityFormBackButton(),
                title: state.editing ? 'Edit activity' : 'Create an activity',
              ),
              body: const ScreenBody(
                children: [
                  Skeleton(height: 180, radius: VelioRadius.card),
                  Skeleton(height: 52, radius: VelioRadius.field),
                  Skeleton(height: 52, radius: VelioRadius.field),
                ],
              ),
            );
          }
          return ActivityFormContent(
            state: state,
            published: widget.published,
            scroll: _scroll,
            title: _title,
            description: _description,
            meeting: _meeting,
            price: _price,
            capacity: _capacity,
          );
        },
      ),
    );
  }
}
