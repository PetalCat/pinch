import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent.dart';
import 'connection_provider.dart';

final agentsProvider = StateNotifierProvider<AgentsNotifier, AsyncValue<List<Agent>>>((ref) {
  return AgentsNotifier(ref);
});

class AgentsNotifier extends StateNotifier<AsyncValue<List<Agent>>> {
  AgentsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
    // Listen for agentStatus events from the WS stream
    _ref.listen(agentEventStreamProvider, (_, next) {
      next.whenData((event) => _handleEvent(event));
    });
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final conn = _ref.read(connectionServiceProvider);
      final agents = await conn.getAgents();
      if (mounted) state = AsyncValue.data(agents);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? '';
    if (type == 'agentStatus') {
      final agentId = event['agentId'] as String?;
      final status  = event['status']  as String?;
      if (agentId == null || status == null) return;
      state.whenData((agents) {
        state = AsyncValue.data(agents.map((a) => a.id == agentId ? a.copyWith(status: status) : a).toList());
      });
    } else if (type == 'nodeState') {
      final raw = event['agents'] as List<dynamic>?;
      if (raw != null) {
        final agents = raw.map((e) => Agent.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(agents);
      }
    }
  }

  Future<void> startAgent(String agentId) async {
    final conn = _ref.read(connectionServiceProvider);
    await conn.startAgent(agentId);
  }

  Future<void> stopAgent(String agentId) async {
    final conn = _ref.read(connectionServiceProvider);
    await conn.stopAgent(agentId);
  }

  Future<void> deleteAgent(String agentId) async {
    final conn = _ref.read(connectionServiceProvider);
    await conn.deleteAgent(agentId);
    state.whenData((agents) {
      state = AsyncValue.data(agents.where((a) => a.id != agentId).toList());
    });
  }

  Future<void> provisionAgent(String agentId) async {
    final conn = _ref.read(connectionServiceProvider);
    final result = await conn.provisionAgent(agentId);
    final matrixUserId = result['matrixUserId'] as String?;
    if (matrixUserId != null) {
      state.whenData((agents) {
        state = AsyncValue.data(agents.map((a) {
          if (a.id != agentId) return a;
          return Agent(
            id: a.id, name: a.name, status: a.status, nodeId: a.nodeId,
            systemPrompt: a.systemPrompt, allowedTools: a.allowedTools,
            disallowedTools: a.disallowedTools, configDir: a.configDir,
            projectDir: a.projectDir, model: a.model,
            matrixUserId: matrixUserId, matrixProvisioned: true,
            autoRestart: a.autoRestart, createdAt: a.createdAt, lastStartedAt: a.lastStartedAt,
          );
        }).toList());
      });
    }
  }
}

// Stream of raw agent-related WS events (agentStatus, nodeState)
final agentEventStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final conn = ref.watch(connectionServiceProvider);
  return conn.agentEventStream;
});
