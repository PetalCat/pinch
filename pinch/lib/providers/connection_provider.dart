import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_event.dart';
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
      {bool always = false});
  Future<List<Session>> getSessions(String projectId);
  Future<List<Project>> getProjects();
  Future<List<Document>> getDocs(String projectId);
  Future<String> readDocument(String projectId, String docPath);
  Future<List<SessionEvent>> getSessionHistory(String sessionId);
}

final connectionServiceProvider = Provider<ConnectionService>((ref) {
  return LocalConnection();
});

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  return ref.watch(connectionServiceProvider).statusStream;
});
