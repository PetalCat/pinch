import 'package:flutter/material.dart';

import '../../theme/tva_colors.dart';

/// A small file icon with scanning line, shown during reading state.
class ReadProp extends StatefulWidget {
  const ReadProp({super.key});

  @override
  State<ReadProp> createState() => _ReadPropState();
}

class _ReadPropState extends State<ReadProp>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, _) {
        return Container(
          width: 14,
          height: 18,
          decoration: BoxDecoration(
            color: TvaColors.bgInset.withValues(alpha: 0.5),
            border: Border.all(color: TvaColors.tealBr, width: 1),
          ),
          child: Stack(
            children: [
              // Content lines
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(10),
                    const SizedBox(height: 1.5),
                    _line(7),
                    const SizedBox(height: 1.5),
                    _line(9),
                    const SizedBox(height: 1.5),
                    _line(6),
                    const SizedBox(height: 1.5),
                    _line(8),
                  ],
                ),
              ),
              // Scanning line
              Positioned(
                top: _scanController.value * 16,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  color: TvaColors.tealBr,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _line(double width) {
    return Container(
      width: width,
      height: 1,
      color: TvaColors.tealBr.withValues(alpha: 0.25),
    );
  }
}

/// A tiny code block with diff lines, shown during editing state.
class EditProp extends StatefulWidget {
  const EditProp({super.key});

  @override
  State<EditProp> createState() => _EditPropState();
}

class _EditPropState extends State<EditProp>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 8,
      height: 1.2,
    );

    return AnimatedBuilder(
      animation: _cursorController,
      builder: (context, _) {
        final showCursor = _cursorController.value > 0.5;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+ exp',
              style: monoStyle.copyWith(color: TvaColors.greenBr),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+ chk',
                  style: monoStyle.copyWith(color: TvaColors.greenBr),
                ),
                const SizedBox(width: 1),
                Container(
                  width: 3,
                  height: 5,
                  color: showCursor ? TvaColors.amber : Colors.transparent,
                ),
              ],
            ),
            Text(
              '- old',
              style: monoStyle.copyWith(color: const Color(0xFFC03828)),
            ),
          ],
        );
      },
    );
  }
}

/// A small terminal box, shown during bash state.
class BashProp extends StatefulWidget {
  const BashProp({super.key});

  @override
  State<BashProp> createState() => _BashPropState();
}

class _BashPropState extends State<BashProp>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cursorController,
      builder: (context, _) {
        final showCursor = _cursorController.value > 0.5;
        return Container(
          width: 22,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0x66000000),
            border: Border.all(color: TvaColors.amberDm, width: 1),
          ),
          padding: const EdgeInsets.only(left: 2, top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '> ',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
                  color: TvaColors.amber,
                  height: 1,
                ),
              ),
              Container(
                width: 3,
                height: 4,
                color: showCursor ? TvaColors.amber : Colors.transparent,
              ),
            ],
          ),
        );
      },
    );
  }
}
