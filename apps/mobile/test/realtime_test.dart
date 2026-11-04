// V-RT-1: the six client rules against a fake socket and fake timers.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velio/core/realtime.dart';

class FakeSocket implements RealtimeSocket {
  FakeSocket(this.uri);
  final Uri uri;
  final _in = StreamController<dynamic>();
  final _ready = Completer<void>();
  final sent = <Map<String, dynamic>>[];
  bool closed = false;

  void open() => _ready.complete();
  void fail() => _in.close();
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

const id = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f';

void main() {
  late List<FakeSocket> sockets;
  late List<String> order;
  RealtimeClient client() => RealtimeClient(
    url: Uri.parse('wss://example.test/api/ws'),
    platform: 'android',
    random: Random(1),
    createSocket: (uri) {
      final s = FakeSocket(uri);
      sockets.add(s);
      return s;
    },
  );

  setUp(() {
    sockets = [];
    order = [];
  });

  test('rule 1: subscribe first, then fetch; platform in the URL', () {
    fakeAsync((async) {
      final rt = client();
      var fetches = 0;
      rt.watch(
        Watch(
          topics: ['activity:$id'],
          refresh: () async {
            order.add('fetch');
            fetches++;
          },
        ),
      );
      expect(sockets.single.uri.queryParameters, {'platform': 'android'});
      sockets.single.open();
      async.flushMicrotasks();
      order.insertAll(0, sockets.single.sent.map((m) => m['type'] as String));
      expect(order, ['subscribe', 'fetch']);
      expect(sockets.single.sent.single['topics'], ['activity:$id']);
      expect(fetches, 1);
      expect(rt.status, RealtimeStatus.live);
    });
  });

  test('routes spots and plan events to the watching screen', () {
    fakeAsync((async) {
      final rt = client();
      final spots = <SpotsEvent>[];
      final plans = <String>[];
      rt.watch(Watch(topics: ['activity:$id', 'plan:p1'], refresh: () async {}, onSpots: spots.add, onPlan: plans.add));
      sockets.single.open();
      async.flushMicrotasks();
      sockets.single.push({'type': 'spots', 'activityId': id, 'spotsLeft': 4, 'version': 9, 'committedAt': 'x'});
      sockets.single.push({'type': 'spots', 'activityId': 'other', 'spotsLeft': 1, 'version': 1, 'committedAt': 'x'});
      sockets.single.push({'type': 'plan', 'planId': 'p1'});
      async.flushMicrotasks();
      expect(spots.single.spotsLeft, 4);
      expect(spots.single.version, 9);
      expect(plans, ['p1']);
    });
  });

  test('V-RT-3: attendance reaches only the watch on host:<id>', () {
    fakeAsync((async) {
      final rt = client();
      final host = <String>[];
      final guest = <String>[];
      rt.watch(Watch(topics: ['activity:$id', 'host:$id'], refresh: () async {}, onAttendance: host.add));
      rt.watch(Watch(topics: ['activity:$id'], refresh: () async {}, onAttendance: guest.add));
      sockets.single.open();
      async.flushMicrotasks();
      sockets.single.push({'type': 'attendance', 'activityId': id});
      sockets.single.push({'type': 'attendance', 'activityId': 'other'});
      async.flushMicrotasks();
      expect(host, [id]);
      expect(guest, isEmpty);
    });
  });

  test('reconnect after a session change: a new socket with resume=1 and a refetch', () {
    fakeAsync((async) {
      final rt = client();
      var fetches = 0;
      rt.watch(Watch(topics: ['host:$id'], refresh: () async => fetches++));
      sockets.single.open();
      async.flushMicrotasks();
      expect(fetches, 1);
      rt.reconnect();
      expect(sockets.first.closed, isTrue);
      expect(sockets.last.uri.queryParameters['resume'], '1');
      sockets.last.open();
      async.flushMicrotasks();
      expect(sockets.last.sent.last, {
        'type': 'subscribe',
        'topics': ['host:$id'],
      });
      expect(fetches, 2);
    });
  });

  test('rule 3: disconnected, it polls every 10 s and reconnects with resume=1', () {
    fakeAsync((async) {
      final rt = client();
      var fetches = 0;
      rt.watch(Watch(topics: ['activity:$id'], refresh: () async => fetches++));
      sockets.single.open();
      async.flushMicrotasks();
      expect(fetches, 1);
      sockets.single.fail();
      async.flushMicrotasks();
      expect(rt.status, RealtimeStatus.reconnecting);
      expect(fetches, 2, reason: 'refetch at once when the socket drops');
      // Reconnect attempts keep failing to open; polling continues.
      async.elapse(const Duration(seconds: 10));
      expect(fetches, greaterThanOrEqualTo(3));
      expect(sockets.length, greaterThan(1));
      expect(sockets.last.uri.queryParameters['resume'], '1');
      final before = fetches;
      sockets.last.open();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 30));
      expect(fetches, before + 1, reason: 'one fetch after resubscribing, then no more polling');
      expect(rt.status, RealtimeStatus.live);
    });
  });

  test('rule 4: resync refetches every watched screen', () {
    fakeAsync((async) {
      final rt = client();
      var a = 0, b = 0;
      rt.watch(Watch(topics: ['activity:$id'], refresh: () async => a++));
      rt.watch(Watch(topics: ['plan:p1'], refresh: () async => b++));
      sockets.single.open();
      async.flushMicrotasks();
      sockets.single.push({'type': 'resync'});
      async.flushMicrotasks();
      expect(a, 2);
      expect(b, 2);
    });
  });

  test('rule 6: rendered is sent with the version', () {
    fakeAsync((async) {
      final rt = client();
      rt.watch(Watch(topics: ['activity:$id'], refresh: () async {}));
      sockets.single.open();
      async.flushMicrotasks();
      rt.rendered(id, 7);
      expect(sockets.single.sent.last, {'type': 'rendered', 'activityId': id, 'version': 7});
    });
  });

  test('background closes the socket; foreground resumes with a refetch', () {
    fakeAsync((async) {
      final rt = client();
      var fetches = 0;
      rt.watch(Watch(topics: ['activity:$id'], refresh: () async => fetches++));
      sockets.single.open();
      async.flushMicrotasks();
      rt.setForeground(false);
      expect(sockets.single.closed, isTrue);
      async.elapse(const Duration(minutes: 5));
      expect(sockets.length, 1, reason: 'no reconnects in the background');
      rt.setForeground(true);
      expect(sockets.length, 2);
      expect(sockets.last.uri.queryParameters['resume'], '1');
      sockets.last.open();
      async.flushMicrotasks();
      expect(fetches, 2);
    });
  });

  test('stopping the last watch unsubscribes and closes', () {
    fakeAsync((async) {
      final rt = client();
      final stop = rt.watch(Watch(topics: ['activity:$id'], refresh: () async {}));
      sockets.single.open();
      async.flushMicrotasks();
      stop();
      expect(sockets.single.closed, isTrue);
      expect(rt.status, RealtimeStatus.connecting);
    });
  });

  test('realtimeUrl uses wss for https', () {
    expect(realtimeUrl('https://d.cloudfront.net').toString(), 'wss://d.cloudfront.net/api/ws');
    expect(realtimeUrl('http://10.0.2.2:3001').toString(), 'ws://10.0.2.2:3001/api/ws');
  });
}
