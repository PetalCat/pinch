import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import 'connection_provider.dart';

/// Currently selected project
final activeProjectProvider = StateProvider<Project?>((ref) => null);

/// Recent projects from server
final recentProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final conn = ref.watch(connectionServiceProvider);
  return conn.getProjects();
});

/// Discovered projects (triggered by scan button)
final discoveredProjectsProvider =
    FutureProvider.family<List<Project>, bool>((ref, scan) async {
  if (!scan) return [];
  final conn = ref.watch(connectionServiceProvider);
  return conn.discoverProjects();
});
