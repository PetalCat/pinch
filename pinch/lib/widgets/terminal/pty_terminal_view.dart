import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart' as xterm;
import '../../providers/connection_provider.dart';

/// Real PTY terminal view — feeds raw Claude Code TTY bytes to xterm.dart.
///
/// Creates a PTY session on mount, streams ptyData as bytes directly into
/// xterm.dart's Terminal buffer. Keyboard input is forwarded back to server.
class PtyTerminalView extends ConsumerStatefulWidget {
  final String projectDir;
  final String? model;
  final bool dangerouslySkipPermissions;
  final int cols;
  final int rows;

  const PtyTerminalView({
    super.key,
    required this.projectDir,
    this.model,
    this.dangerouslySkipPermissions = false,
    this.cols = 120,
    this.rows = 40,
  });

  @override
  ConsumerState<PtyTerminalView> createState() => _PtyTerminalViewState();
}

class _PtyTerminalViewState extends ConsumerState<PtyTerminalView> {
  late xterm.Terminal _terminal;
  late xterm.TerminalController _controller;
  String? _sessionId;
  StreamSubscription<Map<String, dynamic>>? _ptySub;
  bool _starting = true;
  String? _error;

  static const _theme = xterm.TerminalTheme(
    cursor: Color(0xFFC08818),
    selection: Color(0x40C08818),
    foreground: Color(0xFFDDD0B8),
    background: Color(0xFF060503),
    black: Color(0xFF060503),
    red: Color(0xFFC03828),
    green: Color(0xFF52902C),
    yellow: Color(0xFFC08818),
    blue: Color(0xFF4488DD),
    magenta: Color(0xFF8855CC),
    cyan: Color(0xFF3E8480),
    white: Color(0xFFDDD0B8),
    brightBlack: Color(0xFF5A4E3A),
    brightRed: Color(0xFFE06050),
    brightGreen: Color(0xFF6AB040),
    brightYellow: Color(0xFFD4A428),
    brightBlue: Color(0xFF6699EE),
    brightMagenta: Color(0xFFAA77EE),
    brightCyan: Color(0xFF50A8A0),
    brightWhite: Color(0xFFF0E8D8),
    searchHitBackground: Color(0x40C08818),
    searchHitBackgroundCurrent: Color(0x80C08818),
    searchHitForeground: Color(0xFFDDD0B8),
  );

  @override
  void initState() {
    super.initState();
    _terminal = xterm.Terminal(maxLines: 10000);
    _controller = xterm.TerminalController();
    _terminal.onOutput = _handleInput;
    _start();
  }

  Future<void> _start() async {
    final conn = ref.read(connectionServiceProvider);
    try {
      final sid = await conn.createPtySession(
        widget.projectDir,
        cols: widget.cols,
        rows: widget.rows,
        model: widget.model,
        dangerouslySkipPermissions: widget.dangerouslySkipPermissions,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = sid;
        _starting = false;
      });
      _ptySub = conn.ptyStream
          .where((msg) => msg['sessionId'] == sid)
          .listen(_handlePtyEvent);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _starting = false;
      });
    }
  }

  void _handlePtyEvent(Map<String, dynamic> msg) {
    final type = msg['type'] as String? ?? '';
    if (type == 'ptyData') {
      final data = msg['data'] as String? ?? '';
      final encoding = msg['encoding'] as String? ?? 'base64';
      final bytes = encoding == 'base64' ? base64.decode(data) : utf8.encode(data);
      _terminal.write(utf8.decode(bytes, allowMalformed: true));
    } else if (type == 'ptyExit') {
      _terminal.write('\r\n\x1b[2m[Session ended]\x1b[0m\r\n');
    }
  }

  void _handleInput(String data) {
    final sid = _sessionId;
    if (sid == null) return;
    ref.read(connectionServiceProvider).sendPtyInput(sid, data);
  }

  @override
  void dispose() {
    _ptySub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_starting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFC08818)),
            SizedBox(height: 12),
            Text('Starting terminal…',
                style: TextStyle(color: Color(0xFF8A7A60), fontSize: 12)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Color(0xFFC03828), fontSize: 12),
        ),
      );
    }

    return LayoutBuilder(builder: (ctx, constraints) {
      // Notify server of size changes
      final cols = (constraints.maxWidth / 8).floor().clamp(40, 220);
      final rows = (constraints.maxHeight / 16).floor().clamp(10, 80);
      final sid = _sessionId;
      if (sid != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(connectionServiceProvider).sendPtyResize(sid, cols, rows);
        });
      }

      return xterm.TerminalView(
        _terminal,
        controller: _controller,
        theme: _theme,
        textStyle: const xterm.TerminalStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 13,
        ),
        autofocus: true,
        backgroundOpacity: 1.0,
        padding: const EdgeInsets.all(8),
      );
    });
  }
}
