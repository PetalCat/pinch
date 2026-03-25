import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/session.dart';
import '../providers/connection_provider.dart';
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

            const SizedBox(height: 32),

            // Projects
            Text(
              'PROJECTS',
              style: textTheme.labelMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'No projects',
              style: _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
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
