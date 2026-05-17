import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/agent.dart';
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
  Completer<String>? _sessionIdCompleter;
  Completer<String>? _ptySessionIdCompleter;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  final _eventController      = StreamController<SessionEvent>.broadcast();
  final _ptyController        = StreamController<Map<String, dynamic>>.broadcast();
  final _agentEventController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  @override
  ConnectionStatus get currentStatus => _status;

  @override
  Future<void> connect(String host, int port, {String? authToken}) async {
    final scheme = (host != 'localhost' && host != '127.0.0.1') ? 'wss' : 'ws';
    final httpScheme = scheme == 'wss' ? 'https' : 'http';
    _baseUrl = '$httpScheme://$host${port == 443 || port == 80 ? '' : ':$port'}';
    final tokenParam = authToken != null ? '?token=${Uri.encodeComponent(authToken)}' : '';
    _wsUrl = '$scheme://$host${port == 443 || port == 80 ? '' : ':$port'}/ws$tokenParam';
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ));

    await _connectWs();
  }

  Future<void> _connectWs() async {
    _status = ConnectionStatus.connecting;
    _statusController.add(_status);

    try {
      await _dio.get('/api/projects');

      _ws = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _ws!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data.toString()) as Map<String, dynamic>;
            final type = json['type'] as String? ?? '';
            if (type == 'sessionCreated') {
              final sid = json['sessionId'] as String?;
              if (sid != null) {
                _sessionIdCompleter?.complete(sid);
                _sessionIdCompleter = null;
              }
              return;
            }
            if (type == 'sessionReady') return;
            // Route PTY messages to PTY stream
            if (type == 'ptyData' || type == 'ptyExit') {
              _ptyController.add(json);
              return;
            }
            // Route agent/node events to agent stream
            if (type == 'agentStatus' || type == 'nodeStatus' || type == 'nodeState') {
              _agentEventController.add(json);
              return;
            }
            if (type == 'ptySessionCreated') {
              final sid = json['sessionId'] as String?;
              if (sid != null) {
                _ptySessionIdCompleter?.complete(sid);
                _ptySessionIdCompleter = null;
              }
              return;
            }
            final event = SessionEvent.fromJson(json);
            _eventController.add(event);
          } catch (e) {
            debugPrint('WS parse error: $e');
          }
        },
        onError: (Object e) {
          _status = ConnectionStatus.error;
          _statusController.add(_status);
          _scheduleReconnect();
        },
        onDone: () {
          _status = ConnectionStatus.disconnected;
          _statusController.add(_status);
          _scheduleReconnect();
        },
      );

      _status = ConnectionStatus.connected;
      _statusController.add(_status);
      _reconnectAttempts = 0;
    } catch (e) {
      _status = ConnectionStatus.disconnected;
      _statusController.add(_status);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: [1, 2, 4, 8, 15, 30][_reconnectAttempts.clamp(0, 5)]);
    _reconnectAttempts++;
    debugPrint('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(delay, () => _connectWs());
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
    return createSessionWithOptions(SessionOptions(projectDir: projectDir, sessionName: name));
  }

  @override
  Future<void> stopSession(String sessionId) async {
    _ws?.sink.add(jsonEncode({'action': 'stop', 'sessionId': sessionId}));
  }

  @override
  Stream<Map<String, dynamic>> get ptyStream => _ptyController.stream;

  @override
  Future<String> createPtySession(
    String projectDir, {
    int cols = 120,
    int rows = 40,
    String? model,
    bool dangerouslySkipPermissions = false,
  }) async {
    _ptySessionIdCompleter = Completer<String>();
    _ws?.sink.add(jsonEncode({
      'action': 'createPtySession',
      'options': {
        'projectDir': projectDir,
        'cols': cols,
        'rows': rows,
        if (model != null && model != 'auto') 'model': model,
        if (dangerouslySkipPermissions) 'dangerouslySkipPermissions': true,
      },
    }));
    return _ptySessionIdCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Timed out waiting for ptySessionCreated');
        return DateTime.now().millisecondsSinceEpoch.toString();
      },
    );
  }

  @override
  void sendPtyInput(String sessionId, String data) {
    _ws?.sink.add(jsonEncode({
      'action': 'ptyInput',
      'sessionId': sessionId,
      'data': data,
      'encoding': 'utf8',
    }));
  }

  @override
  void sendPtyResize(String sessionId, int cols, int rows) {
    _ws?.sink.add(jsonEncode({
      'action': 'ptyResize',
      'sessionId': sessionId,
      'cols': cols,
      'rows': rows,
    }));
  }

  @override
  Future<void> respondToPermission(String toolUseId, bool allowed,
      {bool always = false, String? sessionId}) async {
    _ws?.sink.add(jsonEncode({
      'action': 'permission',
      'sessionId': sessionId,
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
    _sessionIdCompleter = Completer<String>();
    _ws?.sink.add(jsonEncode({
      'action': 'createSession',
      'options': options.toJson(),
    }));
    // Wait for server to respond with the real session ID (timeout 10s)
    final sessionId = await _sessionIdCompleter!.future
        .timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint('Timed out waiting for sessionCreated response');
      return DateTime.now().millisecondsSinceEpoch.toString();
    });
    return sessionId;
  }

  @override
  Future<List<Project>> getMyProjects() async {
    try {
      final resp = await _dio.get('/api/my-projects');
      final data = resp.data as Map<String, dynamic>;
      final projectsList = data['projects'] as List;
      return projectsList.map((j) {
        final m = j as Map<String, dynamic>;
        return Project(
          id: m['id'] as String? ?? '',
          name: m['name'] as String? ?? '',
          directory: m['directory'] as String? ?? '',
          shortCode: m['shortCode'] as String?,
          hasSpecs: m['hasSpecs'] == true,
          hasPlans: m['hasPlans'] == true,
          hasBrainstorm: m['hasBrainstorm'] == true,
          hasFindings: m['hasFindings'] == true,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Project>> discoverProjects() async {
    final resp = await _dio.get('/api/discover-projects');
    return (resp.data as List).map((j) {
      final m = j as Map<String, dynamic>;
      final name = m['name'] as String;
      return Project(
        id: m['path'] as String,
        name: name,
        directory: m['path'] as String,
        shortCode: name.length >= 2
            ? name.substring(0, 2).toUpperCase()
            : name.toUpperCase(),
        hasSpecs: m['has_specs'] == true,
        hasPlans: m['has_plans'] == true,
        hasBrainstorm: m['has_brainstorm'] == true,
        hasFindings: m['has_findings'] == true,
      );
    }).toList();
  }

  @override
  Future<void> setActiveProject(String directory) async {
    await _dio.post('/api/set-project', data: {'path': directory});
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

  @override
  Future<List<Map<String, dynamic>>> getHistoricalSessions() async {
    try {
      final resp = await _dio.get('/api/history');
      return (resp.data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<SessionEvent>> getHistoricalSession(String sessionId) async {
    try {
      final resp = await _dio.get('/api/history/$sessionId');
      return (resp.data as List)
          .map((j) => SessionEvent.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Agent methods ──────────────────────────────────────────────────────────

  @override
  Stream<Map<String, dynamic>> get agentEventStream => _agentEventController.stream;

  @override
  Future<List<Agent>> getAgents() async {
    try {
      final resp = await _dio.get('/api/agents');
      return (resp.data as List)
          .map((j) => Agent.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> startAgent(String agentId) async {
    await _dio.post('/api/agents/$agentId/start');
  }

  @override
  Future<void> stopAgent(String agentId) async {
    await _dio.post('/api/agents/$agentId/stop');
  }

  @override
  Future<void> deleteAgent(String agentId) async {
    await _dio.delete('/api/agents/$agentId');
  }

  @override
  Future<Map<String, dynamic>> provisionAgent(String agentId) async {
    final resp = await _dio.post('/api/agents/$agentId/provision');
    return resp.data as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getNodes() async {
    try {
      final resp = await _dio.get('/api/nodes');
      return (resp.data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

}
