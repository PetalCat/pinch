import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connection_provider.dart';
import 'agent_provider.dart';

class ConnectedNode {
  final String nodeId;
  final String name;
  final String? hostname;
  final String? connectedAt;

  const ConnectedNode({
    required this.nodeId,
    required this.name,
    this.hostname,
    this.connectedAt,
  });

  factory ConnectedNode.fromJson(Map<String, dynamic> j) => ConnectedNode(
        nodeId: j['nodeId'] as String? ?? '',
        name: j['name'] as String? ?? j['nodeId'] as String? ?? '',
        hostname: j['hostname'] as String?,
        connectedAt: j['connectedAt'] as String?,
      );
}

final nodesProvider = StateNotifierProvider<NodesNotifier, List<ConnectedNode>>((ref) {
  return NodesNotifier(ref);
});

class NodesNotifier extends StateNotifier<List<ConnectedNode>> {
  NodesNotifier(this._ref) : super([]) {
    _load();
    _ref.listen(agentEventStreamProvider, (_, next) {
      next.whenData((event) {
        final type = event['type'] as String?;
        if (type == 'nodeState') {
          final raw = event['nodes'] as List<dynamic>?;
          if (raw != null) {
            state = raw
                .map((e) => ConnectedNode.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      });
    });
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final conn = _ref.read(connectionServiceProvider);
      final raw = await conn.getNodes();
      if (mounted) {
        state = raw.map(ConnectedNode.fromJson).toList();
      }
    } catch (_) {}
  }

  Future<void> refresh() => _load();
}
