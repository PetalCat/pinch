import 'package:flutter/material.dart';

import '../../theme/tva_colors.dart';

class DiffBlock extends StatelessWidget {
  final String filename;
  final int added;
  final int removed;
  final List<String> lines;

  const DiffBlock({
    super.key,
    required this.filename,
    required this.added,
    required this.removed,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        border: Border.all(color: TvaColors.brd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: TvaColors.bgInset,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  filename,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: TvaColors.txt2,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '+$added',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: TvaColors.greenBr,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '-$removed',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFFC03828),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TvaColors.brd),
          // Lines
          ...lines.asMap().entries.map(
                (entry) => _DiffLine(
                  lineNum: entry.key + 1,
                  line: entry.value,
                ),
              ),
        ],
      ),
    );
  }
}

class _DiffLine extends StatelessWidget {
  final int lineNum;
  final String line;

  const _DiffLine({required this.lineNum, required this.line});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;

    if (line.startsWith('+')) {
      bgColor = const Color(0x0A52902C);
      textColor = TvaColors.greenBr;
    } else if (line.startsWith('-')) {
      bgColor = const Color(0x0AC03828);
      textColor = const Color(0xFFC03828);
    } else {
      bgColor = Colors.transparent;
      textColor = TvaColors.txt3;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: bgColor,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$lineNum',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0x4D5A4E3A),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 16,
            color: const Color(0x0AFFFFFF),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: Text(
              line,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
