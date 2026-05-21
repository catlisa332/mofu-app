import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CalmScoreBadge extends StatelessWidget {
  final double score; // 0.0 ~ 1.0

  const CalmScoreBadge({super.key, required this.score});

  Color get _color {
    if (score >= 0.7) return MofuColors.calmHigh;
    if (score >= 0.4) return MofuColors.calmMid;
    return MofuColors.calmLow;
  }

  String get _label {
    if (score >= 0.7) return 'おだやか';
    if (score >= 0.4) return 'ふつう';
    return 'やや刺激';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
