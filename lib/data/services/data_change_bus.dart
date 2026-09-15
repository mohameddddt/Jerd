import 'dart:async';

enum DataChange {
  /// The user changed something on this device (a sync job was queued).
  local,

  /// A sync run brought server data into the local database.
  remote,
}

/// Lets cubits react to writes made elsewhere without depending on each other.
class DataChangeBus {
  final _controller = StreamController<DataChange>.broadcast();

  Stream<DataChange> get stream => _controller.stream;

  void notify(DataChange change) {
    if (!_controller.isClosed) _controller.add(change);
  }

  Future<void> dispose() => _controller.close();
}
