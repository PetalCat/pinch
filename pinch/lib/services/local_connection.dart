import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/session_event.dart';
import '../models/session_options.dart';
import '../models/session.dart';
import '../models/project.dart';
import '../models/document.dart';
import '../providers/connection_provider.dart';

class LocalConnection implements ConnectionService {
  late Dio _dio;
  WebSocketChannel? _ws;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _baseUrl = '';
  String _wsUrl = '';

  final _eventController = StreamController<SessionEvent>.broadcast();

  @override
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  @override
  ConnectionStatus get currentStatus => _status;

  @override
  Future<void> connect(String host, int port, {String? authToken}) async {
    _baseUrl = 'http://$host:$port';
    _wsUrl = 'ws://$host:$port/ws';
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _status = ConnectionStatus.connecting;
    _statusController.add(_status);

    try {
      // Test connection with a simple request
      await _dio.get('/api/projects');

      // Connect WebSocket
      _ws = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _ws!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data.toString()) as Map<String, dynamic>;
            final event = SessionEvent.fromJson(json);
            _eventController.add(event);
          } catch (_) {
            // Ignore malformed messages
          }
        },
        onError: (Object e) {
          _status = ConnectionStatus.error;
          _statusController.add(_status);
        },
        onDone: () {
          _status = ConnectionStatus.disconnected;
          _statusController.add(_status);
        },
      );

      _status = ConnectionStatus.connected;
      _statusController.add(_status);
    } catch (e) {
      _status = ConnectionStatus.error;
      _statusController.add(_status);
    }
  }

  @override
  Future<void> disconnect() async {
    await _ws?.sink.close();
    _ws = null;
    _status = ConnectionStatus.disconnected;
    _statusController.add(_status);
  }

  @override
  Stream<SessionEvent> sendPrompt(String sessionId, String prompt) {
    _ws?.sink.add(jsonEncode({
      'action': 'prompt',
      'sessionId': sessionId,
      'text': prompt,
    }));
    // Return filtered stream of events for this session
    return _eventController.stream.where((e) => e.sessionId == sessionId);
  }

  @override
  Future<String> createSession(String projectDir, {String? name}) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _ws?.sink.add(jsonEncode({
      'action': 'createSession',
      'projectDir': projectDir,
      'name': name,
    }));
    return sessionId;
  }

  @override
  Future<void> stopSession(String sessionId) async {
    _ws?.sink.add(jsonEncode({'action': 'stop', 'sessionId': sessionId}));
  }

  @override
  Future<void> respondToPermission(String toolUseId, bool allowed,
      {bool always = false}) async {
    _ws?.sink.add(jsonEncode({
      'action': 'permission',
      'toolUseId': toolUseId,
      'allowed': allowed,
      'always': always,
    }));
  }

  @override
  Future<List<Project>> getProjects() async {
    final resp = await _dio.get('/api/projects');
    return (resp.data as List)
        .map((j) => Project.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Session>> getSessions(String projectId) async {
    final resp = await _dio.get('/api/projects/$projectId/sessions');
    return (resp.data as List)
        .map((j) => Session.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Document>> getDocs(String projectId) async {
    final resp = await _dio.get('/api/projects/$projectId/docs');
    return (resp.data as List)
        .map((j) => Document.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> readDocument(String projectId, String docPath) async {
    final resp = await _dio.get('/api/projects/$projectId/docs/$docPath');
    return (resp.data as Map<String, dynamic>)['content'] as String;
  }

  @override
  Stream<SessionEvent> get eventStream => _eventController.stream;

  @override
  Future<String> createSessionWithOptions(SessionOptions options) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _ws?.sink.add(jsonEncode({
      'action': 'createSession',
      'options': options.toJson(),
    }));
    return sessionId;
  }

  @override
  Future<List<SessionEvent>> getSessionHistory(String sessionId) async {
    try {
      final resp = await _dio.get('/api/sessions/$sessionId/events');
      return (resp.data as List)
          .map((j) => SessionEvent.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
