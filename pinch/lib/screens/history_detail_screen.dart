import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/session_event.dart';
import '../providers/connection_provider.dart';
import '../providers/history_provider.dart';
import '../theme/tva_colors.dart';
import '../widgets/timeline/timeline_view.dart';

class HistoryDetailScreen extends ConsumerWidget {
  final String sessionId;

  const HistoryDetailScreen({super.key, required this.sessionId});

  static const _mono = TextStyle(fontFamily: 'IBMPlexMono');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyList = ref.watch(sessionHistoryListProvider);

    // Find session metadata from the list
    String sessionTitle = 'Session';
    String projectName = '';
    historyList.whenData((sessions) {
      for (final s in sessions) {
        if (s['id'] == sessionId) {
          sessionTitle = s['firstMessage'] as String? ?? 'Session';
          projectName = s['projectName'] as String? ?? '';
          break;
        }
      }
    });

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: TvaColors.bg2,
            border: Border(
              bottom: BorderSide(color: TvaColors.brd),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/history'),
                child: Text(
                  '<',
                  style: _mono.copyWith(
                    fontSize: 14,
                    color: TvaColors.txt3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionTitle.length > 60
                          ? '${sessionTitle.substring(0, 60)}...'
                          : sessionTitle,
                      style: _mono.copyWith(
                        fontSize: 11,
                        color: TvaColors.txt,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (projectName.isNotEmpty)
                      Text(
                        projectName,
                        style:
                            _mono.copyWith(fontSize: 8, color: TvaColors.txt3),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Resume session with --resume flag
                  debugPrint('Resume $sessionId');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: TvaColors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'RESUME',
                    style: _mono.copyWith(
                      fontSize: 9,
                      color: TvaColors.amber,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Timeline content
        Expanded(
          child: FutureBuilder<List<SessionEvent>>(
            future: ref
                .read(connectionServiceProvider)
                .getHistoricalSession(sessionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Text(
                    'Loading session...',
                    style:
                        _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No events found',
                    style:
                        _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
                  ),
                );
              }
              return TimelineView(events: snapshot.data!);
            },
          ),
        ),
      ],
    );
  }
}
