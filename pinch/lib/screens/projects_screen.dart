import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/project.dart';
import '../providers/connection_provider.dart';
import '../providers/project_provider.dart';
import '../theme/tva_colors.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  static const _mono = TextStyle(fontFamily: 'IBMPlexMono');

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        color: color.withValues(alpha: 0.06),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 7,
          color: color,
          letterSpacing: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _projectCard(Project project, {int? sessionCount}) {
    return GestureDetector(
      onTap: () async {
        final conn = ref.read(connectionServiceProvider);
        await conn.setActiveProject(project.directory);
        ref.read(activeProjectProvider.notifier).state = project;
        if (mounted) context.go('/home');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border.all(color: TvaColors.brd),
          color: TvaColors.bgPanel,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: TvaColors.brd),
                color: TvaColors.bgRaised,
              ),
              child: Text(
                project.shortCode ?? '',
                style: _mono.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: TvaColors.txt2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: _mono.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TvaColors.txt,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.directory,
                    style: _mono.copyWith(
                      fontSize: 8,
                      color: TvaColors.txt3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    spacing: 6,
                    children: [
                      if (sessionCount != null && sessionCount > 0)
                        _tag('$sessionCount SESSIONS', TvaColors.txt2),
                      if (project.hasSpecs) _tag('SPECS', TvaColors.tealBr),
                      if (project.hasPlans) _tag('PLANS', TvaColors.greenBr),
                      if (project.hasBrainstorm)
                        _tag('BRAINSTORM', TvaColors.amber),
                      if (project.hasFindings) _tag('DOCS', TvaColors.txt2),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '>',
              style: _mono.copyWith(fontSize: 14, color: TvaColors.txt3),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final allAsync = ref.watch(allProjectsProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('PROJECTS', style: textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text('Browse and discover projects',
                style: textTheme.bodySmall),
            const SizedBox(height: 32),

            // All Projects
            Text('ALL PROJECTS', style: textTheme.labelMedium),
            const SizedBox(height: 12),
            allAsync.when(
              data: (projects) => projects.isEmpty
                  ? Text(
                      'No projects found',
                      style:
                          _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
                    )
                  : Column(
                      children: projects
                          .map((p) => _projectCard(p))
                          .toList(),
                    ),
              loading: () => Text(
                'Loading...',
                style: _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
              ),
              error: (e, _) => Text(
                'Offline',
                style: _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
              ),
            ),

            const SizedBox(height: 24),

            // Scan / refresh button
            GestureDetector(
              onTap: () => ref.invalidate(allProjectsProvider),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: TvaColors.amber),
                ),
                child: Row(
                  children: [
                    Text(
                      'SCAN FOR PROJECTS',
                      style: _mono.copyWith(
                        fontSize: 11,
                        color: TvaColors.amber,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '*',
                      style: _mono.copyWith(
                        fontSize: 14,
                        color: TvaColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
