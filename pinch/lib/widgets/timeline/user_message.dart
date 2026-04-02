import 'package:flutter/material.dart';

import '../../theme/tva_colors.dart';

class UserMessage extends StatelessWidget {
  final String text;

  const UserMessage({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider line
          Container(height: 1, color: TvaColors.brd),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User avatar
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TvaColors.bgInset,
                  border: Border.all(color: TvaColors.brd),
                ),
                child: const Text(
                  'Y',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: TvaColors.txt3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOU',
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 8,
                        color: TvaColors.txt3,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: TvaColors.txt,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
