import 'package:flutter/material.dart';

class AlertBadge extends StatelessWidget {
  final String alertType;
  final bool isAcknowledged;

  const AlertBadge({
    super.key,
    required this.alertType,
    required this.isAcknowledged,
  });

  @override
  Widget build(BuildContext context) {
    if (isAcknowledged) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'RESOLVED',
          style: TextStyle(
            color: Color(0xFF10B981),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final isHigh = alertType.toUpperCase() == 'HIGH';
    final color = isHigh ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        isHigh ? 'CRITICAL HIGH' : 'WARNING LOW',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
