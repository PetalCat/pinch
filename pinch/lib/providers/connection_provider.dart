import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent.dart';
import '../models/session_event.dart';
import '../models/session_options.dart';
import '../models/session.dart';
import '../models/project.dart';
import '../models/document.dart';
import '../services/local_connection.dart';

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
      {bool always = false, String? sessionId});
  Future<List<Session>> getSessions(String projectId);
  Future<List<Project>> getProjects();
  Future<List<Document>> getDocs(String projectId);
  Future<String> readDocument(String projectId, String docPath);
  Future<List<SessionEvent>> getSessionHistory(String sessionId);
  Future<List<Map<String, dynamic>>> getHistoricalSessions();
  Future<List<SessionEvent>> getHistoricalSession(String sessionId);
  Future<String> createSessionWithOptions(SessionOptions options);
  Future<List<Project>> discoverProjects();
  Future<List<Project>> getMyProjects();
  Future<void> setActiveProject(String directory);
  Stream<SessionEvent> get eventStream;

  // PTY session support (real Claude Code terminal)
  Stream<Map<String, dynamic>> get ptyStream;
  Future<String> createPtySession(String projectDir, {int cols = 120, int rows = 40, String? model, bool dangerouslySkipPermissions = false});
  void sendPtyInput(String sessionId, String data);
  void sendPtyResize(String sessionId, int cols, int rows);

  // Agent management
  Stream<Map<String, dynamic>> get agentEventStream;
  Future<List<Agent>> getAgents();
  Future<void> startAgent(String agentId);
  Future<void> stopAgent(String agentId);
  Future<void> deleteAgent(String agentId);
  Future<Map<String, dynamic>> provisionAgent(String agentId);

  // Node fleet
  Future<List<Map<String, dynamic>>> getNodes();
}

final connectionServiceProvider = Provider<ConnectionService>((ref) {
  return LocalConnection();
});

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  return ref.watch(connectionServiceProvider).statusStream;
});
