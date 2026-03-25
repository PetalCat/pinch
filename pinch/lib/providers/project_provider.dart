import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import 'connection_provider.dart';

/// Currently selected project
final activeProjectProvider = StateProvider<Project?>((ref) => null);

/// All projects: merged from scan + session history
final allProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final conn = ref.watch(connectionServiceProvider);
  return conn.getMyProjects();
});

/// Recent projects from server (kept for backwards compat)
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
