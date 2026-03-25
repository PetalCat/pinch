import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connection_provider.dart';
import 'project_provider.dart';

final sessionHistoryListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final conn = ref.watch(connectionServiceProvider);
  return conn.getHistoricalSessions();
});

/// Historical sessions filtered by the active project
final projectSessionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final activeProject = ref.watch(activeProjectProvider);
  if (activeProject == null) return [];

  final conn = ref.watch(connectionServiceProvider);
  final allHistory = await conn.getHistoricalSessions();

  // Filter to sessions whose projectDir matches the active project
  return allHistory.where((s) {
    final sessionDir = s['projectDir'] as String? ?? '';
    return sessionDir == activeProject.directory ||
        sessionDir.endsWith('/${activeProject.name}');
  }).toList();
});
