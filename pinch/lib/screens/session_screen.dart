import 'package:flutter/material.dart';

import '../models/session_event.dart';
import '../theme/tva_colors.dart';
import '../widgets/timeline/timeline_view.dart';

class SessionScreen extends StatefulWidget {
  final String sessionId;
  const SessionScreen({super.key, required this.sessionId});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  bool _isTimeline = true;

  static final _demoEvents = [
    SessionEvent(
      id: '1',
      sessionId: 'demo',
      timestamp: DateTime.now(),
      type: EventType.userMessage,
      data: const {
        'text':
            'Fix the authentication middleware — tokens expire silently and users with expired tokens can still access protected routes.',
      },
    ),
    SessionEvent(
      id: '2',
      sessionId: 'demo',
      timestamp: DateTime.now(),
      type: EventType.assistantText,
      data: const {
        'text':
            "I'll fix the auth middleware. Let me examine the current implementation.",
        'done': true,
      },
    ),
    SessionEvent(
      id: '3',
      sessionId: 'demo',
      timestamp: DateTime.now(),
      type: EventType.toolUse,
      data: const {
        'toolName': 'Read',
        'input': {'path': 'src/auth/middleware.ts'},
        'toolUseId': 't1',
      },
    ),
    SessionEvent(
      id: '4',
      sessionId: 'demo',
      timestamp: DateTime.now(),
      type: EventType.toolResult,
      data: const {
        'toolUseId': 't1',
        'success': true,
        'output': '',
        'duration': 0.3,
      },
    ),
    SessionEvent(
      id: '5',
      sessionId: 'demo',
      timestamp: DateTime.now(),
      type: EventType.toolUse,
      data: const {
        'toolName': 'Edit',
        'input': {'path': 'src/auth/middleware.ts'},
        'toolUseId': 't2',
      },
    ),
    SessionEvent(
      id: '6',
      sessionId: 'demo',
      timestamp: DateTime.now(),
      type: EventType.toolResult,
      data: const {
        'toolUseId': 't2',
        'success': true,
        'duration': 1.2,
        'diff': {
          'file': 'src/auth/middleware.ts',
          'added': 8,
          'removed': 2,
          'lines': [
            '  const token = req.headers.authorization;',
            '- if (!token) return res.status(401).send();',
            '+ if (!token) return res.status(401).json({ error: "No token" });',
            '+ const decoded = verifyToken(token);',
            '+ if (decoded.exp < Date.now() / 1000) {',
            '+   return res.status(401).json({ error: "Expired" });',
            '+ }',
          ],
        },
      },
    ),
    SessionEvent(
      id: '7',
      sessionId: 'demo',
      timestamp: DateTime.now(),
      type: EventType.permissionRequest,
      data: const {
        'toolName': 'Bash',
        'command': 'npm test --filter auth',
        'workDir': '~/projects/sveltechat',
        'toolUseId': 't3',
      },
    ),
    SessionEvent(
      id: '8',
      sessionId: 'demo',
      timestamp: DateTime.now(),
      type: EventType.toolUse,
      data: const {
        'toolName': 'Bash',
        'input': {'command': 'npm test --filter auth'},
        'toolUseId': 't3',
      },
    ),
    SessionEvent(
      id: '9',
      sessionId: 'demo',
      timestamp: DateTime.now(),
      type: EventType.toolResult,
      data: const {
        'toolUseId': 't3',
        'success': false,
        'duration': 2.1,
        'output':
            'FAIL  2 of 12 tests failed\n  x middleware rejects missing token\n  x middleware rejects expired token',
      },
    ),
    SessionEvent(
      id: '10',
      sessionId: 'demo',
      timestamp: DateTime.now(),
      type: EventType.assistantText,
      data: const {
        'text':
            'Fixed. The issue was in two places — the middleware was not checking token.exp against the current timestamp, and the error response shape did not match what the test suite expected. All 12 auth tests now pass.',
        'done': true,
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSessionBar(),
        Expanded(
          child: TimelineView(events: _demoEvents),
        ),
      ],
    );
  }

  Widget _buildSessionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: TvaColors.bg2,
        border: Border(bottom: BorderSide(color: TvaColors.brd)),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: TvaColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Fix auth middleware',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TvaColors.txt,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '2m — opus 4.6',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: TvaColors.txt3,
            ),
          ),
          const Spacer(),
          // Toggle group
          Row(
            children: [
              _buildToggleBtn('TIMELINE', isActive: _isTimeline),
              _buildToggleBtn('TERMINAL', isActive: !_isTimeline),
            ],
          ),
          const SizedBox(width: 8),
          // Stop button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: TvaColors.rust),
            ),
            child: const Text(
              'STOP',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: TvaColors.rust,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, {required bool isActive}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isTimeline = label == 'TIMELINE';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x14C08818) : Colors.transparent,
          border: Border.all(
            color: isActive ? TvaColors.amberDm : TvaColors.brd,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8,
            color: isActive ? TvaColors.amber : TvaColors.txt3,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
