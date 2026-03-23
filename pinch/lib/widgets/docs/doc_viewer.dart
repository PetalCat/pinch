import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../theme/tva_colors.dart';

class DocViewer extends StatelessWidget {
  final String markdown;
  const DocViewer({super.key, required this.markdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TvaColors.bg,
      child: Markdown(
        data: markdown,
        padding: const EdgeInsets.all(32),
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: TvaColors.txt,
              letterSpacing: 0.5),
          h2: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TvaColors.amberBr,
              letterSpacing: 1.5,
              height: 2.5),
          h3: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TvaColors.txt),
          p: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 13,
              color: Color(0xFFC8B99A),
              height: 1.7),
          code: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              color: TvaColors.clawd,
              backgroundColor: TvaColors.bgInset),
          codeblockDecoration: BoxDecoration(
              color: TvaColors.bgInset,
              border: Border.all(color: TvaColors.brd)),
          blockquoteDecoration: const BoxDecoration(
            color: TvaColors.bgInset,
            border:
                Border(left: BorderSide(color: TvaColors.amber, width: 3)),
          ),
          listBulletPadding: const EdgeInsets.only(right: 8),
          horizontalRuleDecoration: const BoxDecoration(
              border: Border(top: BorderSide(color: TvaColors.brd))),
        ),
      ),
    );
  }
}
