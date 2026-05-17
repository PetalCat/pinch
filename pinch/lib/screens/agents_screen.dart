import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent.dart';
import '../providers/agent_provider.dart';
import '../theme/tva_colors.dart';

class AgentsScreen extends ConsumerWidget {
  const AgentsScreen({super.key});

  static const _mono = TextStyle(fontFamily: 'IBMPlexMono');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider);

    return Scaffold(
      backgroundColor: TvaColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onRefresh: () => ref.read(agentsProvider.notifier).refresh()),
          Container(height: 1, color: TvaColors.brd),
          Expanded(
            child: agents.when(
              loading: () => const Center(child: _LoadingDot()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: _mono.copyWith(fontSize: 11, color: TvaColors.rust)),
              ),
              data: (list) => list.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          Container(height: 1, color: TvaColors.brd),
                      itemBuilder: (context, i) =>
                          _AgentTile(agent: list[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: TvaColors.bgInset,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('FLEET',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11,
                color: TvaColors.amber,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              )),
          const Spacer(),
          GestureDetector(
            onTap: onRefresh,
            child: const Icon(Icons.refresh, color: TvaColors.txt3, size: 16),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _AgentTile extends ConsumerWidget {
  final Agent agent;
  const _AgentTile({required this.agent});

  static const _mono = TextStyle(fontFamily: 'IBMPlexMono');

  Color get _statusColor {
    return switch (agent.status) {
      'running'    => TvaColors.greenBr,
      'starting'   => TvaColors.amber,
      'restarting' => TvaColors.amber,
      'error'      => TvaColors.rust,
      _            => TvaColors.txt3,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(agentsProvider.notifier);

    return Container(
      color: TvaColors.bgPanel,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Name + detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.name,
                    style: _mono.copyWith(
                        fontSize: 13,
                        color: TvaColors.txt,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(agent.id,
                      style: _mono.copyWith(
                          fontSize: 9, color: TvaColors.txt3, letterSpacing: 1)),
                  if (agent.nodeId.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text('@ ${agent.nodeId.split('.').first}',
                        style: _mono.copyWith(
                            fontSize: 9, color: TvaColors.txt3)),
                  ],
                  if (agent.matrixUserId != null) ...[
                    const SizedBox(width: 8),
                    Text(agent.matrixUserId!,
                        style: _mono.copyWith(
                            fontSize: 9, color: TvaColors.clawd.withValues(alpha: 0.7))),
                  ],
                  if (agent.projectosProjectId != null) ...[
                    const SizedBox(width: 8),
                    Text('📋 ${agent.projectosProjectId!}',
                        style: _mono.copyWith(
                            fontSize: 9, color: TvaColors.tealBr.withValues(alpha: 0.8))),
                  ],
                ]),
                if (agent.model != null) ...[
                  const SizedBox(height: 2),
                  Text(agent.model!.toUpperCase(),
                      style: _mono.copyWith(fontSize: 8, color: TvaColors.amber)),
                ],
              ],
            ),
          ),

          // Status badge
          _StatusBadge(status: agent.status),
          const SizedBox(width: 8),

          // Matrix provision button
          _MatrixButton(
            provisioned: agent.matrixProvisioned,
            onProvision: () => notifier.provisionAgent(agent.id),
          ),
          const SizedBox(width: 8),

          // Start / stop button
          _ActionButton(
            isRunning: agent.isRunning || agent.status == 'starting' || agent.status == 'restarting',
            onStart: () => notifier.startAgent(agent.id),
            onStop: () => notifier.stopAgent(agent.id),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'running'    => TvaColors.greenBr,
      'starting'   => TvaColors.amber,
      'restarting' => TvaColors.amber,
      'error'      => TvaColors.rust,
      _            => TvaColors.txt3,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 8,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _MatrixButton extends StatelessWidget {
  final bool provisioned;
  final VoidCallback onProvision;

  const _MatrixButton({required this.provisioned, required this.onProvision});

  @override
  Widget build(BuildContext context) {
    final color = provisioned ? TvaColors.clawd : TvaColors.txt3;
    return GestureDetector(
      onTap: provisioned ? null : onProvision,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: provisioned ? 0.5 : 0.3)),
        ),
        child: Icon(
          Icons.tag,
          size: 14,
          color: color.withValues(alpha: provisioned ? 1.0 : 0.4),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _ActionButton({
    required this.isRunning,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isRunning ? onStop : onStart,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(
            color: isRunning
                ? TvaColors.rust.withValues(alpha: 0.5)
                : TvaColors.greenBr.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(
          isRunning ? Icons.stop : Icons.play_arrow,
          size: 16,
          color: isRunning ? TvaColors.rust : TvaColors.greenBr,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy_outlined, color: TvaColors.txt3, size: 32),
          SizedBox(height: 12),
          Text('NO AGENTS',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                color: TvaColors.txt3,
                letterSpacing: 3,
              )),
        ],
      ),
    );
  }
}

class _LoadingDot extends StatelessWidget {
  const _LoadingDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
        color: TvaColors.amber,
      ),
    );
  }
}
