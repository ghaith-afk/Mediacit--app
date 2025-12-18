// lib/widgets/stat_tile.dart
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const StatTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.accent;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: bg, size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ],
          )
        ],
      ),
    );
  }
}
