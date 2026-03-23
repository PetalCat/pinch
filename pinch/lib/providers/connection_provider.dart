import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_event.dart';
import '../models/session.dart';
import '../models/project.dart';
import '../models/document.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

abstract class ConnectionService {
  Stream<ConnectionStatus> get statusStream;
  ConnectionStatus get currentStatus;
  Future<void> connect(String host, int port, {String? authToken});
  Future<void> disconnect();
  Stream<SessionEvent> sendPrompt(String sessionId, String prompt);
  Future<String> createSession(String projectDir, {String? name});
  Future<void> stopSession(String sessionId);
  Future<void> respondToPermission(String toolUseId, bool allowed,
      {bool always = false});
  Future<List<Session>> getSessions(String projectId);
  Future<List<Project>> getProjects();
  Future<List<Document>> getDocs(String projectId);
  Future<String> readDocument(String projectId, String docPath);
  Future<List<SessionEvent>> getSessionHistory(String sessionId);
}

final connectionServiceProvider = Provider<ConnectionService>((ref) {
  return MockConnectionService._instance;
});

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  return ref.watch(connectionServiceProvider).statusStream;
});

/// Inline mock so the provider file is self-contained; the full mock lives in
/// services/mock_connection.dart for direct use elsewhere.
class MockConnectionService implements ConnectionService {
  static final _instance = MockConnectionService._();
  MockConnectionService._();

  final _statusController =
      Stream<ConnectionStatus>.value(ConnectionStatus.connected)
          .asBroadcastStream();

  @override
  Stream<ConnectionStatus> get statusStream => _statusController;
  @override
  ConnectionStatus get currentStatus => ConnectionStatus.connected;

  @override
  Future<void> connect(String host, int port, {String? authToken}) async {}
  @override
  Future<void> disconnect() async {}

  @override
  Future<List<Project>> getProjects() async => [
        const Project(
            id: 'p1',
            name: 'SvelteChat',
            directory: '~/projects/sveltechat',
            shortCode: 'SC'),
        const Project(
            id: 'p2',
            name: 'Alpine',
            directory: '~/projects/alpine',
            shortCode: 'AP'),
      ];

  @override
  Future<List<Session>> getSessions(String projectId) async => [
        Session(
            id: 's1',
            projectId: projectId,
            name: 'Fix auth middleware',
            status: SessionStatus.active,
            createdAt: DateTime.now().subtract(const Duration(minutes: 4))),
        Session(
            id: 's2',
            projectId: projectId,
            name: 'Add dark mode',
            status: SessionStatus.idle,
            createdAt: DateTime.now().subtract(const Duration(minutes: 18))),
        Session(
            id: 's3',
            projectId: projectId,
            name: 'Refactor DB layer',
            status: SessionStatus.ended,
            createdAt: DateTime.now().subtract(const Duration(minutes: 48))),
      ];

  @override
  Future<List<Document>> getDocs(String projectId) async => [
        const Document(
            path: 'docs/specs/auth.md',
            title: 'Auth Design Spec',
            category: DocCategory.spec),
        const Document(
            path: 'docs/plans/migration.md',
            title: 'Migration Plan',
            category: DocCategory.plan),
        const Document(
            path: 'docs/api.md',
            title: 'API Endpoints',
            category: DocCategory.finding),
      ];

  @override
  Future<String> readDocument(String projectId, String docPath) async =>
      '# Sample Document\n\nThis is a placeholder document.\n\n## Section 1\n\nContent goes here.\n\n## Section 2\n\nMore content.';

  @override
  Stream<SessionEvent> sendPrompt(String sessionId, String prompt) async* {
    yield SessionEvent(
        id: 'e1',
        sessionId: sessionId,
        timestamp: DateTime.now(),
        type: EventType.assistantText,
        data: const {'text': 'Working on it...', 'done': false});
    await Future.delayed(const Duration(seconds: 1));
    yield SessionEvent(
        id: 'e2',
        sessionId: sessionId,
        timestamp: DateTime.now(),
        type: EventType.assistantText,
        data: const {'text': 'Working on it... Done.', 'done': true});
  }

  @override
  Future<String> createSession(String projectDir, {String? name}) async =>
      'new-session-${DateTime.now().millisecondsSinceEpoch}';
  @override
  Future<void> stopSession(String sessionId) async {}
  @override
  Future<void> respondToPermission(String toolUseId, bool allowed,
      {bool always = false}) async {}
  @override
  Future<List<SessionEvent>> getSessionHistory(String sessionId) async => [];
}
