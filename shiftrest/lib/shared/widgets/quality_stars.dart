import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class QualityStars extends StatelessWidget {
  final int quality;
  final bool interactive;
  final ValueChanged<int>? onChanged;
  final double size;

  const QualityStars({
    super.key,
    required this.quality,
    this.interactive = false,
    this.onChanged,
    this.size = 28,
  });

  static const List<String> emojis = ['😫', '😕', '😐', '🙂', '😊'];
  static const List<String> labels = [
    'Awful',
    'Poor',
    'Okay',
    'Good',
    'Great'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final filled = starIndex <= quality;
            return GestureDetector(
              onTap: interactive ? () => onChanged?.call(starIndex) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? AppColors.accent : AppColors.surfaceVariant,
                  size: size,
                ),
              ),
            );
          }),
        ),
        if (quality > 0 && quality <= 5) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emojis[quality - 1],
                style: TextStyle(fontSize: size * 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                labels[quality - 1],
                style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
