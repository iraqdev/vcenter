/// DNZ Notifications — Flutter SDK (من دليل DNZ)
/// العرض المحلي يمر عبر NotificationCenter لتوحيد الصوت ومنع التكرار.
library dnz_notifications;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:ecommerce/notifications/notification_center.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef DNZMessageHandler = void Function(Map<String, dynamic> message);

class DNZException implements Exception {
  final String message;
  final int? statusCode;
  DNZException(this.message, [this.statusCode]);
  @override
  String toString() => 'DNZException($statusCode): $message';
}

class DNZNotifications {
  DNZNotifications._();
  static final DNZNotifications instance = DNZNotifications._();

  late String _apiKey;
  late String _apiBase;
  String? _connectionId;
  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  Timer? _heartbeat;
  bool _shouldReconnect = true;
  final List<DNZMessageHandler> _handlers = [];

  bool _initialized = false;
  bool _wsConnected = false;

  Future<void> initialize({
    required String apiKey,
    required String apiBase,
  }) async {
    if (_initialized) return;
    if (apiKey.isEmpty) throw ArgumentError('apiKey مطلوب');
    _apiKey = apiKey;
    _apiBase = apiBase.endsWith('/')
        ? apiBase.substring(0, apiBase.length - 1)
        : apiBase;

    await NotificationCenter.init();

    final prefs = await SharedPreferences.getInstance();
    _connectionId = prefs.getString('dnz_connection_id') ?? _generateConnectionId();
    await prefs.setString('dnz_connection_id', _connectionId!);
    _initialized = true;
  }

  String get connectionId => _connectionId ?? '';

  /// true عندما يكون WebSocket متصلاً — لتجنب عرض إشعار FCM مكرر.
  bool get isWebSocketConnected => _wsConnected;

  void onMessage(DNZMessageHandler handler) => _handlers.add(handler);

  String _generateConnectionId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<Map<String, dynamic>> registerDevice({
    required String recipientId,
    String? fcmToken,
    String? apnsToken,
  }) async {
    _ensureInit();
    final platform = Platform.isIOS ? 'ios' : 'android';
    final body = <String, dynamic>{
      'recipientId': recipientId,
      'platform': platform,
      'deviceTransport': 'mobile_background',
      'connectionId': _connectionId,
    };
    if (fcmToken != null && fcmToken.isNotEmpty) body['nativeFcmToken'] = fcmToken;
    if (apnsToken != null && apnsToken.isNotEmpty) body['nativeApnsToken'] = apnsToken;
    final res = await http.post(
      Uri.parse('$_apiBase/v1/subscribers/register'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<void> startBackground() async {
    _ensureInit();
    _shouldReconnect = true;
    await _connectWs();
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) => _sendHeartbeat());
  }

  Future<void> stopBackground() async {
    _shouldReconnect = false;
    _wsConnected = false;
    _heartbeat?.cancel();
    _heartbeat = null;
    await _wsSub?.cancel();
    _wsSub = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Uri _backgroundWsUri() {
    final wsBase = _apiBase
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return Uri.parse(
      '$wsBase/v1/ws/background'
      '?connectionId=$_connectionId&apiKey=$_apiKey',
    );
  }

  Future<void> _connectWs() async {
    final url = _backgroundWsUri();
    try {
      print('🔌 DNZ WebSocket: $url');
      _channel = WebSocketChannel.connect(url);
      _wsConnected = true;
      _wsSub = _channel!.stream.listen(
        _onWsData,
        onError: (e) {
          print('⚠️ DNZ WebSocket error: $e');
          _wsConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          _wsConnected = false;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _wsConnected = false;
      print('⚠️ DNZ WebSocket: $e');
      _scheduleReconnect();
    }
  }

  void _onWsData(dynamic data) {
    if (data is! String) return;
    try {
      final msg = jsonDecode(data) as Map<String, dynamic>;
      _showLocal(msg);
      for (final h in _handlers) {
        try {
          h(msg);
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _scheduleReconnect() {
    _wsSub = null;
    _channel = null;
    if (!_shouldReconnect) return;
    Future.delayed(const Duration(seconds: 3), () {
      _connectWs().catchError((_) {});
    });
  }

  Future<void> _sendHeartbeat() async {
    if (!_wsConnected) return;
    try {
      await http.post(
        Uri.parse('$_apiBase/v1/devices/heartbeat'),
        headers: _headers(),
        body: jsonEncode({'connectionId': _connectionId}),
      );
    } catch (_) {}
  }

  Future<void> _showLocal(Map<String, dynamic> msg) async {
    await NotificationCenter.show(
      title: msg['title']?.toString() ?? 'DNZ',
      body: msg['body']?.toString() ?? '',
      payload: jsonEncode(msg['data'] ?? {}),
      dedupeKey: 'dnz:${msg['title']}|${msg['body']}|${msg['data']}',
    );
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'X-API-Key': _apiKey,
      };

  Future<Map<String, dynamic>> _decode(http.Response res) async {
    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    if (res.statusCode >= 400) {
      throw DNZException(body['detail']?.toString() ?? 'HTTP ${res.statusCode}', res.statusCode);
    }
    return body;
  }

  void _ensureInit() {
    if (!_initialized) {
      throw StateError('DNZNotifications: استدعِ initialize() أولاً');
    }
  }
}
