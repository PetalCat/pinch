import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart' as xterm;

import '../../models/session_event.dart';

/// Terminal view — renders session events through xterm.dart
/// to look like the real Claude Code CLI output.
class PinchTerminalView extends StatefulWidget {
  final List<SessionEvent> events;

  const PinchTerminalView({super.key, required this.events});

  @override
  State<PinchTerminalView> createState() => _PinchTerminalViewState();
}

class _PinchTerminalViewState extends State<PinchTerminalView> {
  late xterm.Terminal _terminal;
  int _lastRendered = 0;

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
    _renderNew();
  }

  @override
  void didUpdateWidget(PinchTerminalView old) {
    super.didUpdateWidget(old);
    if (widget.events.length > _lastRendered) {
      _renderNew();
    }
  }

  void _renderNew() {
    for (int i = _lastRendered; i < widget.events.length; i++) {
      _writeEvent(widget.events[i]);
    }
    _lastRendered = widget.events.length;
  }

  void _w(String s) => _terminal.write(s);

  // ANSI helpers
  static const _reset = '\x1b[0m';
  static const _bold = '\x1b[1m';
  static const _dim = '\x1b[2m';
  // Colors matching Claude Code's theme
  static const _clawd = '\x1b[38;2;215;119;87m'; // clawd orange
  static const _amber = '\x1b[38;2;192;136;24m';
  static const _green = '\x1b[38;2;82;144;44m';
  static const _teal = '\x1b[38;2;62;132;128m';
  static const _rust = '\x1b[38;2;139;46;18m';
  static const _purple = '\x1b[38;2;136;85;204m';
  static const _txt2 = '\x1b[38;2;154;136;104m';
  static const _txt3 = '\x1b[38;2;90;78;58m';

  void _writeEvent(SessionEvent e) {
    switch (e.type) {
      case EventType.sessionStart:
        final model = e.data['model'] as String? ?? '';
        final cwd = e.data['cwd'] as String? ?? '';
        _w('$_bold${_clawd}Claude Code$_reset');
        if (model.isNotEmpty) _w('  $_txt3$model$_reset');
        _w('\r\n');
        if (cwd.isNotEmpty) _w('$_txt3$cwd$_reset\r\n');
        _w('$_txt3${'─' * 60}$_reset\r\n\r\n');

      case EventType.userMessage:
        final text = e.data['text'] as String? ?? '';
        _w('$_bold${_amber}❯$_reset $text\r\n\r\n');

      case EventType.assistantThinking:
        final text = e.data['thinking'] as String? ?? '';
        if (text.isNotEmpty) {
          _w('$_dim$_purple✦ $text$_reset\r\n');
        }

      case EventType.assistantText:
        final text = e.data['text'] as String? ?? '';
        // Render Claude's response with word wrapping
        for (final line in text.split('\n')) {
          _w('$_clawd$line$_reset\r\n');
        }
        _w('\r\n');

      case EventType.toolUse:
        final name = e.data['toolName'] as String? ?? '';
        final input = e.data['input'] as Map<String, dynamic>? ?? {};
        final target = input['file_path'] ?? input['path'] ?? input['command'] ?? input['pattern'] ?? '';
        final color = _toolColor(name);
        _w('  $color$_bold$name$_reset $_txt2$target$_reset\r\n');

      case EventType.toolResult:
        final success = e.data['success'] as bool? ?? true;
        final output = e.data['output'] as String? ?? '';
        final duration = e.data['duration'] as num?;
        if (output.isNotEmpty) {
          final color = success ? _green : _rust;
          final lines = output.split('\n');
          final display = lines.length > 20 ? [...lines.take(20), '... (${lines.length - 20} more lines)'] : lines;
          for (final line in display) {
            _w('  $color$line$_reset\r\n');
          }
        }
        if (duration != null && duration > 0) {
          _w('  $_txt3${(duration / 1000).toStringAsFixed(1)}s$_reset\r\n');
        }

      case EventType.permissionRequest:
        final name = e.data['toolName'] as String? ?? '';
        _w('\r\n$_amber⚠  Permission required: $name$_reset\r\n\r\n');

      case EventType.error:
        final msg = e.data['message'] as String? ?? '';
        _w('$_rust✗ $msg$_reset\r\n');

      case EventType.turnComplete:
        final cost = (e.data['cost'] as num?)?.toStringAsFixed(4) ?? '0';
        _w('$_txt3(\$$cost)$_reset\r\n\r\n');

      case EventType.sessionEnd:
        final reason = e.data['reason'] as String? ?? '';
        final cost = (e.data['cost'] as num?)?.toStringAsFixed(4) ?? '0';
        _w('\r\n$_txt3─── session $reason · \$$cost ───$_reset\r\n');

      default:
        break;
    }
  }

  String _toolColor(String name) {
    return switch (name) {
      'Read' || 'Glob' || 'Grep' => _teal,
      'Edit' || 'Write' => _green,
      'Bash' => _amber,
      _ => _txt2,
    };
  }

  @override
  Widget build(BuildContext context) {
    return xterm.TerminalView(
      _terminal,
      theme: _theme,
      textStyle: const xterm.TerminalStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 10,
        height: 1.9,
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      cursorType: xterm.TerminalCursorType.block,
    );
  }
}
