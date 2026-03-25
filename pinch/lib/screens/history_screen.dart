import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/history_provider.dart';
import '../theme/tva_colors.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const _mono = TextStyle(fontFamily: 'IBMPlexMono');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sessionHistoryListProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SESSION HISTORY',
              style: _mono.copyWith(
                fontSize: 18,
                color: TvaColors.txt,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All Claude Code sessions across your projects',
              style: _mono.copyWith(fontSize: 10, color: TvaColors.txt3),
            ),
            const SizedBox(height: 24),
            historyAsync.when(
              loading: () => Text(
                'Loading...',
                style: _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
              ),
              error: (e, _) => Text(
                'Failed to load history',
                style: _mono.copyWith(fontSize: 11, color: TvaColors.rust),
              ),
              data: (sessions) => _buildGroupedList(context, sessions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(
      BuildContext context, List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) {
      return Text(
        'No sessions found',
        style: _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final todaySessions = <Map<String, dynamic>>[];
    final yesterdaySessions = <Map<String, dynamic>>[];
    final thisWeekSessions = <Map<String, dynamic>>[];
    final olderSessions = <Map<String, dynamic>>[];

    for (final s in sessions) {
      final dt = DateTime.tryParse(s['lastModified'] as String? ?? '') ?? now;
      final day = DateTime(dt.year, dt.month, dt.day);
      if (day == today) {
        todaySessions.add(s);
      } else if (day == yesterday) {
        yesterdaySessions.add(s);
      } else if (day.isAfter(weekAgo)) {
        thisWeekSessions.add(s);
      } else {
        olderSessions.add(s);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todaySessions.isNotEmpty) ...[
          _groupHeader('TODAY'),
          ...todaySessions.map((s) => _sessionCard(context, s)),
          const SizedBox(height: 16),
        ],
        if (yesterdaySessions.isNotEmpty) ...[
          _groupHeader('YESTERDAY'),
          ...yesterdaySessions.map((s) => _sessionCard(context, s)),
          const SizedBox(height: 16),
        ],
        if (thisWeekSessions.isNotEmpty) ...[
          _groupHeader('THIS WEEK'),
          ...thisWeekSessions.map((s) => _sessionCard(context, s)),
          const SizedBox(height: 16),
        ],
        if (olderSessions.isNotEmpty) ...[
          _groupHeader('OLDER'),
          ...olderSessions.map((s) => _sessionCard(context, s)),
        ],
      ],
    );
  }

  Widget _groupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: _mono.copyWith(
          fontSize: 9,
          color: TvaColors.txt3,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _sessionCard(BuildContext context, Map<String, dynamic> session) {
    final projectName = session['projectName'] as String? ?? '';
    final firstMessage = session['firstMessage'] as String? ?? '(no message)';
    final model = session['model'] as String? ?? 'unknown';
    final timeAgo = _formatTimeAgo(session['lastModified'] as String? ?? '');
    final shortCode = projectName.length >= 2
        ? projectName.substring(0, 2).toUpperCase()
        : projectName.toUpperCase();

    return GestureDetector(
      onTap: () => context.go('/session/${session['id']}?historical=true'),
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
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: TvaColors.brd),
                color: TvaColors.bgRaised,
              ),
              child: Text(
                shortCode,
                style: _mono.copyWith(fontSize: 8, color: TvaColors.txt3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstMessage.length > 80
                        ? '${firstMessage.substring(0, 80)}...'
                        : firstMessage,
                    style: _mono.copyWith(fontSize: 11, color: TvaColors.txt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$projectName  ·  $model  ·  $timeAgo',
                    style: _mono.copyWith(fontSize: 8, color: TvaColors.txt3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                    color: TvaColors.amber.withValues(alpha: 0.3)),
              ),
              child: Text(
                'VIEW',
                style: _mono.copyWith(
                  fontSize: 8,
                  color: TvaColors.amber,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}
