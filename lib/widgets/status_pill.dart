import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  /// true = mic is active
  final bool listening;

  const StatusPill({super.key, required this.listening});

  @override
  Widget build(BuildContext context) {
    final label = listening ? 'LISTENING' : 'VOICE DETECTED';

    return SizedBox(
      width: 305, // fixed width for the button
      height: 68, // fixed height to match padding and size
      child: OutlinedButton(
        onPressed: () {}, // no action
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white, // set background to white
          side: const BorderSide(color: Color(0xFF0D2B55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          // Remove padding as size is fixed
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0D2B55),
            fontWeight: FontWeight.w500,
            fontSize: 19,
          ),
        ),
      ),
    );
  }
}
