import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/session.dart';
import '../providers/connection_provider.dart';
import '../providers/history_provider.dart';
import '../providers/project_provider.dart';
import '../providers/session_provider.dart';
import '../theme/tva_colors.dart';
import '../widgets/session_create_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _mono = TextStyle(fontFamily: 'IBMPlexMono');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('PINCH', style: textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text('Remote Operations Interface', style: textTheme.bodySmall),
            const SizedBox(height: 32),

            // Quick Session button
            GestureDetector(
              onTap: () => _createSession(context, ref),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: TvaColors.amber),
                ),
                child: Row(
                  children: [
                    Text(
                      '+ QUICK SESSION',
                      style: _mono.copyWith(
                        fontSize: 11,
                        color: TvaColors.amber,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '>',
                      style: _mono.copyWith(
                        fontSize: 11,
                        color: TvaColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Recent Sessions
            Text(
              'RECENT SESSIONS',
              style: textTheme.labelMedium,
            ),
            const SizedBox(height: 12),
            ref.watch(sessionsProvider).when(
                  data: (sessions) => Column(
                    children:
                        sessions.map((s) => _SessionCard(session: s)).toList(),
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

            // Active Project
            Builder(builder: (context) {
              final activeProject = ref.watch(activeProjectProvider);
              if (activeProject == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIVE PROJECT', style: textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: TvaColors.clawd.withValues(alpha: 0.3)),
                      color: TvaColors.bgPanel,
                    ),
                    child: Row(
                      children: [
                        Text(
                          activeProject.shortCode ?? '',
                          style: _mono.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: TvaColors.txt2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeProject.name,
                                style: _mono.copyWith(
                                    fontSize: 11, color: TvaColors.txt),
                              ),
                              Text(
                                activeProject.directory,
                                style: _mono.copyWith(
                                    fontSize: 8, color: TvaColors.txt3),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),

            // Recent History
            Text('RECENT HISTORY', style: textTheme.labelMedium),
            const SizedBox(height: 8),
            ref.watch(sessionHistoryListProvider).when(
                  data: (sessions) {
                    final recent = sessions.take(5).toList();
                    if (recent.isEmpty) {
                      return Text(
                        'No session history',
                        style: _mono.copyWith(
                            fontSize: 11, color: TvaColors.txt3),
                      );
                    }
                    return Column(
                      children: recent
                          .map((s) => _HistoryCard(session: s))
                          .toList(),
                    );
                  },
                  loading: () => Text(
                    'Loading...',
                    style: _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.go('/history'),
              child: Text(
                'VIEW ALL HISTORY >',
                style: _mono.copyWith(
                  fontSize: 9,
                  color: TvaColors.txt3,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Browse Projects
            GestureDetector(
              onTap: () => context.go('/projects'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: TvaColors.brd),
                ),
                child: Text(
                  'BROWSE PROJECTS',
                  style: _mono.copyWith(
                    fontSize: 11,
                    color: TvaColors.txt3,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSession(BuildContext context, WidgetRef ref) async {
    final options = await showSessionCreateDialog(context);
    if (options != null) {
      final conn = ref.read(connectionServiceProvider);
      final sessionId = await conn.createSessionWithOptions(options);
      ref.read(activeSessionIdProvider.notifier).state = sessionId;
      if (context.mounted) context.go('/session/$sessionId');
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final Session session;

  static const _mono = TextStyle(fontFamily: 'IBMPlexMono');

  Color _statusColor(SessionStatus status) {
    return switch (status) {
      SessionStatus.active => TvaColors.greenBr,
      SessionStatus.idle => TvaColors.amber,
      SessionStatus.ended => TvaColors.txt3,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/session/${session.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: TvaColors.bgPanel,
          border: Border.all(color: TvaColors.brd),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(session.status),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name,
                    style: _mono.copyWith(fontSize: 11, color: TvaColors.txt),
                  ),
                  Text(
                    '${session.model ?? 'opus'} · ${session.status.name}',
                    style: _mono.copyWith(fontSize: 8, color: TvaColors.txt3),
                  ),
                ],
              ),
            ),
            Text(
              '>',
              style: _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.session});

  final Map<String, dynamic> session;

  static const _mono = TextStyle(fontFamily: 'IBMPlexMono');

  static String _formatTimeAgo(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final firstMessage = session['firstMessage'] as String? ?? '(no message)';
    final projectName = session['projectName'] as String? ?? '';
    final model = session['model'] as String? ?? '';
    final timeAgo = _formatTimeAgo(session['lastModified'] as String? ?? '');

    return GestureDetector(
      onTap: () => context.go('/session/${session['id']}?historical=true'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: TvaColors.bgPanel,
          border: Border.all(color: TvaColors.brd),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstMessage,
                    style: _mono.copyWith(fontSize: 11, color: TvaColors.txt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$projectName  ·  $model  ·  $timeAgo',
                    style: _mono.copyWith(fontSize: 8, color: TvaColors.txt3),
                  ),
                ],
              ),
            ),
            Text(
              '>',
              style: _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
            ),
          ],
        ),
      ),
    );
  }
}
