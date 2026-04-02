import 'dart:async';

import '../models/session_event.dart';
import '../models/session_options.dart';
import '../models/session.dart';
import '../models/project.dart';
import '../models/document.dart';
import '../providers/connection_provider.dart';

/// Full mock implementation of [ConnectionService] for demo / offline use.
class MockConnectionService implements ConnectionService {
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _status = ConnectionStatus.connected;

  @override
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  @override
  ConnectionStatus get currentStatus => _status;

  @override
  Future<void> connect(String host, int port, {String? authToken}) async {
    _status = ConnectionStatus.connected;
    _statusController.add(_status);
  }

  @override
  Future<void> disconnect() async {
    _status = ConnectionStatus.disconnected;
    _statusController.add(_status);
  }

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
      '# Sample Document\n\nThis is a placeholder document.\n\n'
      '## Section 1\n\nContent goes here.\n\n'
      '## Section 2\n\nMore content.';

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
      {bool always = false, String? sessionId}) async {}
  @override
  Future<List<SessionEvent>> getSessionHistory(String sessionId) async => [];

  @override
  Stream<SessionEvent> get eventStream => const Stream.empty();

  @override
  Future<String> createSessionWithOptions(SessionOptions options) async {
    return 'mock-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<List<Project>> getMyProjects() async => [
        const Project(
            id: 'p1',
            name: 'SvelteChat',
            directory: '~/projects/sveltechat',
            shortCode: 'SC',
            hasSpecs: true,
            hasPlans: true),
        const Project(
            id: 'p2',
            name: 'Alpine',
            directory: '~/projects/alpine',
            shortCode: 'AP',
            hasBrainstorm: true),
      ];

  @override
  Future<List<Project>> discoverProjects() async => [
        const Project(
            id: '/home/user/projects/sveltechat',
            name: 'SvelteChat',
            directory: '/home/user/projects/sveltechat',
            shortCode: 'SC',
            hasSpecs: true,
            hasPlans: true),
        const Project(
            id: '/home/user/projects/alpine',
            name: 'Alpine',
            directory: '/home/user/projects/alpine',
            shortCode: 'AP',
            hasBrainstorm: true),
      ];

  @override
  Future<void> setActiveProject(String directory) async {}

  @override
  Future<List<Map<String, dynamic>>> getHistoricalSessions() async => [];

  @override
  Future<List<SessionEvent>> getHistoricalSession(String sessionId) async => [];

}
