// Realtime client (S7 §4.7): one socket for the app implementing the six client rules in
// packages/contracts/src/realtime.ts, as apps/web/lib/realtime/client.ts does. The socket closes when
// the app goes to the background and resumes (resume=1, then a refetch) in the foreground.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

enum RealtimeStatus { connecting, live, reconnecting }

class SpotsEvent {
  const SpotsEvent(this.activityId, this.spotsLeft, this.version);
  final String activityId;
  final int spotsLeft;
  final int version;
}

class Watch {
  Watch({required this.topics, required this.refresh, this.onSpots, this.onPlan});
  final List<String> topics;

  /// Fetch every snapshot the screen shows: after `subscribe` on each (re)connect (rule 1), on
  /// `resync` (rule 4) and every 10 s while disconnected (rule 3).
  final Future<void> Function() refresh;
  final void Function(SpotsEvent event)? onSpots;

  /// Rule 5: the Plan changed; fetch it again.
  final void Function(String planId)? onPlan;
}

/// The socket, behind an interface so tests drive it by hand.
abstract interface class RealtimeSocket {
  Stream<dynamic> get messages;
  Future<void> get ready;
  void send(String data);
  void close();
}

class ChannelSocket implements RealtimeSocket {
  ChannelSocket(Uri uri) : _channel = WebSocketChannel.connect(uri);
  final WebSocketChannel _channel;
  @override
  Stream<dynamic> get messages => _channel.stream;
  @override
  Future<void> get ready => _channel.ready;
  @override
  void send(String data) => _channel.sink.add(data);
  @override
  void close() => _channel.sink.close();
}

class RealtimeClient {
  RealtimeClient({
    required this.url,
    required this.platform,
    RealtimeSocket Function(Uri uri)? createSocket,
    Random? random,
    this.pollInterval = const Duration(seconds: 10),
  }) : _createSocket = createSocket ?? ChannelSocket.new,
       _random = random ?? Random();

  /// `wss://<host>/api/ws`, without the query.
  final Uri url;
  final String platform;
  final Duration pollInterval;
  final RealtimeSocket Function(Uri uri) _createSocket;
  final Random _random;

  static const _backoffMin = Duration(seconds: 1);
  static const _backoffMax = Duration(seconds: 30);

  final _watches = <Watch>{};
  final _status = StreamController<RealtimeStatus>.broadcast();
  RealtimeStatus _current = RealtimeStatus.connecting;
  RealtimeSocket? _socket;
  StreamSubscription<dynamic>? _sub;
  bool _open = false;
  bool _everConnected = false;
  bool _paused = false;
  int _attempt = 0;
  Timer? _reconnect;
  Timer? _poll;

  RealtimeStatus get status => _current;
  Stream<RealtimeStatus> get statusChanges => _status.stream;

  /// Starts following the topics; the returned function stops.
  void Function() watch(Watch w) {
    _watches.add(w);
    if (_socket == null && _reconnect == null && !_paused) {
      _connect();
    } else if (_open) {
      _send({'type': 'subscribe', 'topics': w.topics});
      _refresh(w);
    } else if (_current == RealtimeStatus.reconnecting) {
      _refresh(w);
    }
    return () {
      _watches.remove(w);
      if (_open) {
        final still = _watches.expand((x) => x.topics).toSet();
        final gone = w.topics.where((t) => !still.contains(t)).toList();
        if (gone.isNotEmpty) _send({'type': 'unsubscribe', 'topics': gone});
      }
      if (_watches.isEmpty) _stop();
    };
  }

  /// Rule 6: after a `spots` version is painted.
  void rendered(String activityId, int version) {
    if (_open) _send({'type': 'rendered', 'activityId': activityId, 'version': version});
  }

  /// App lifecycle: background closes the socket; foreground reconnects with resume=1 and refetches.
  void setForeground(bool foreground) {
    if (foreground) {
      if (_paused) {
        _paused = false;
        if (_watches.isNotEmpty) _connect();
      }
    } else if (!_paused) {
      _paused = true;
      _teardown();
    }
  }

  void _connect() {
    _reconnect = null;
    final query = {'platform': platform, if (_everConnected) 'resume': '1'};
    final RealtimeSocket socket;
    try {
      socket = _createSocket(url.replace(queryParameters: query));
    } catch (_) {
      _scheduleReconnect();
      return;
    }
    _socket = socket;
    _sub = socket.messages.listen(
      _handle,
      onDone: () => _closed(socket),
      onError: (_) => _closed(socket),
      cancelOnError: true,
    );
    socket.ready.then((_) {
      if (_socket != socket) return;
      _open = true;
      _everConnected = true;
      _attempt = 0;
      _stopPolling();
      _setStatus(RealtimeStatus.live);
      final topics = _watches.expand((w) => w.topics).toSet().toList();
      if (topics.isNotEmpty) _send({'type': 'subscribe', 'topics': topics});
      _refreshAll(); // rule 1: after subscribe
    }, onError: (_) => _closed(socket));
  }

  void _closed(RealtimeSocket socket) {
    if (_socket != socket) return;
    _sub?.cancel();
    _sub = null;
    _socket = null;
    _open = false;
    if (_watches.isNotEmpty && !_paused) _scheduleReconnect();
  }

  void _handle(dynamic data) {
    Object? msg;
    try {
      msg = jsonDecode('$data');
    } catch (_) {
      return;
    }
    if (msg is! Map) return;
    switch (msg['type']) {
      case 'spots':
        final id = msg['activityId'], spots = msg['spotsLeft'], version = msg['version'];
        if (id is! String || spots is! int || version is! int) return;
        final event = SpotsEvent(id, spots, version);
        for (final w in _watches.toList()) {
          if (w.topics.contains('activity:$id')) w.onSpots?.call(event);
        }
      case 'plan':
        final id = msg['planId'];
        for (final w in _watches.toList()) {
          if (w.topics.contains('plan:$id')) w.onPlan?.call('$id');
        }
      case 'resync':
        _refreshAll();
    }
  }

  void _scheduleReconnect() {
    _setStatus(RealtimeStatus.reconnecting);
    _startPolling();
    final ceiling = min(_backoffMax.inMilliseconds, _backoffMin.inMilliseconds * pow(2, _attempt).toInt());
    _attempt++;
    // Full jitter keeps many phones from reconnecting in step after a deploy.
    final delay = max(_backoffMin.inMilliseconds ~/ 2, (ceiling * _random.nextDouble()).round());
    _reconnect = Timer(Duration(milliseconds: delay), _connect);
  }

  void _startPolling() {
    if (_poll != null) return;
    _refreshAll();
    _poll = Timer.periodic(pollInterval, (_) => _refreshAll());
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  void _refresh(Watch w) => w.refresh().catchError((_) {});
  void _refreshAll() {
    for (final w in _watches.toList()) {
      _refresh(w);
    }
  }

  void _send(Map<String, Object> message) => _socket?.send(jsonEncode(message));

  void _setStatus(RealtimeStatus s) {
    if (s == _current) return;
    _current = s;
    _status.add(s);
  }

  void _teardown() {
    _reconnect?.cancel();
    _reconnect = null;
    _stopPolling();
    final socket = _socket;
    _sub?.cancel();
    _sub = null;
    _socket = null;
    _open = false;
    socket?.close();
  }

  void _stop() {
    _teardown();
    _paused = false;
    _attempt = 0;
    _setStatus(RealtimeStatus.connecting);
  }
}

/// `wss://<host>/api/ws` from the API base URL.
Uri realtimeUrl(String apiBase) {
  final base = Uri.parse(apiBase);
  return base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws', path: '/api/ws');
}
