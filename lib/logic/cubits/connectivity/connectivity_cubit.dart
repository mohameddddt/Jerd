import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

/// `true` when some network is available. Drives the offline banner.
class ConnectivityCubit extends Cubit<bool> {
  StreamSubscription<bool>? _subscription;

  ConnectivityCubit({
    required Stream<bool> changes,
    required Future<bool> Function() check,
  }) : super(true) {
    check().then((online) {
      if (!isClosed) emit(online);
    });
    _subscription = changes.listen(emit);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
