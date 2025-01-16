import 'package:flutter/material.dart';

class SubtitleChip extends StatelessWidget {
  final String text;
  final bool primary;

  const SubtitleChip({super.key, required this.text, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: primary
            ? Theme.of(context).colorScheme.inversePrimary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
