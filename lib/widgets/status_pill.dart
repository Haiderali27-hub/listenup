import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  /// true = mic is active
  final bool listening;

  const StatusPill({super.key, required this.listening});

  @override
  Widget build(BuildContext context) {
    final label = listening ? 'LISTENING' : 'VOICE DETECTED';
    return OutlinedButton(
      onPressed: () {}, // no action
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF0D2B55)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.symmetric(vertical: 23, horizontal: 90),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0D2B55),
          fontWeight: FontWeight.w500,
          fontSize: 19,
        ),
      ),
    );
  }
}
