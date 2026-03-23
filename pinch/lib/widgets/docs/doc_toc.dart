import 'package:flutter/material.dart';
import '../../theme/tva_colors.dart';

class _Heading {
  final int level; // 2 or 3
  final String text;
  const _Heading(this.level, this.text);
}

class DocToc extends StatelessWidget {
  final String markdown;
  final ValueChanged<String>? onHeadingTap;

  const DocToc({super.key, required this.markdown, this.onHeadingTap});

  List<_Heading> _parse() {
    final headings = <_Heading>[];
    for (final line in markdown.split('\n')) {
      if (line.startsWith('### ')) {
        headings.add(_Heading(3, line.substring(4).trim()));
      } else if (line.startsWith('## ')) {
        headings.add(_Heading(2, line.substring(3).trim()));
      }
    }
    return headings;
  }

  @override
  Widget build(BuildContext context) {
    final headings = _parse();
    if (headings.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: TvaColors.brd)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTENTS',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: TvaColors.txt3,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          for (final h in headings)
            GestureDetector(
              onTap: () => onHeadingTap?.call(h.text),
              child: Padding(
                padding: EdgeInsets.only(
                    left: h.level == 3 ? 12.0 : 0, bottom: 10),
                child: Text(
                  h.text,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSans',
                    fontSize: 12,
                    color: h.level == 2 ? TvaColors.amberBr : TvaColors.txt3,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
