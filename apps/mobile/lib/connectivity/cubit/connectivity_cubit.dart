// The online hint for the whole app (S7 §4.8): true until the platform says there's no network.
import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../repositories/connectivity_repository.dart';

class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit({required ConnectivityRepository connectivityRepository}) : super(true) {
    _sub = connectivityRepository.online.listen(emit);
  }

  late final StreamSubscription<bool> _sub;

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
