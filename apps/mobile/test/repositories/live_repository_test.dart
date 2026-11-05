// LiveRepository (V-REPO-1): a watch is a stream that follows the topics while listened to, and
// stops when cancelled.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:velio/data/realtime.dart';
import 'package:velio/repositories/live_repository.dart';

class FakeSocket implements RealtimeSocket {
  final _in = StreamController<dynamic>();
  final _ready = Completer<void>();
  final sent = <Map<String, dynamic>>[];
  bool closed = false;

  void open() => _ready.complete();
  void push(Map<String, Object> m) => _in.add(jsonEncode(m));

  @override
  Stream<dynamic> get messages => _in.stream;
  @override
  Future<void> get ready => _ready.future;
  @override
  void send(String data) => sent.add(jsonDecode(data) as Map<String, dynamic>);
  @override
  void close() {
    closed = true;
    _in.close();
  }
}

void main() {
  const id = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f';
  late FakeSocket socket;
  late LiveRepository live;

  setUp(() {
    socket = FakeSocket();
    live = LiveRepository(
      RealtimeClient(url: Uri.parse('wss://x.test/api/ws'), platform: 'android', createSocket: (_) => socket),
    );
  });

  test('subscribe, refresh, then spots, Plan and attendance updates; cancel stops the watch', () async {
    final updates = <LiveUpdate>[];
    final sub = live.watch(['activity:$id', 'plan:p1', 'host:$id']).listen(updates.add);
    socket.open();
    await pumpEventQueue();
    expect(socket.sent.first, {
      'type': 'subscribe',
      'topics': ['activity:$id', 'plan:p1', 'host:$id'],
    });
    socket
      ..push({'type': 'spots', 'activityId': id, 'spotsLeft': 3, 'version': 7})
      ..push({'type': 'plan', 'planId': 'p1'})
      ..push({'type': 'attendance', 'activityId': id});
    await pumpEventQueue();
    expect(updates.whereType<LiveStatusChanged>().single.status, RealtimeStatus.live);
    expect(updates.whereType<LiveRefreshRequested>(), hasLength(1));
    final spots = updates.whereType<LiveSpotsChanged>().single;
    expect((spots.activityId, spots.spotsLeft, spots.version), (id, 3, 7));
    expect(updates.whereType<LivePlanChanged>().single.planId, 'p1');
    expect(updates.whereType<LiveAttendanceChanged>().single.activityId, id);

    await sub.cancel();
    // The last watch ended, so the client closes the socket.
    expect(socket.closed, isTrue);
  });
}
