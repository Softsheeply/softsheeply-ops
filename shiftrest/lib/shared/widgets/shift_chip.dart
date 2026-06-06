import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class ShiftChip extends StatelessWidget {
  final String shiftType;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  const ShiftChip({
    super.key,
    required this.shiftType,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.shiftColor(shiftType);
    final label = AppConstants.shiftTypeLabels[shiftType] ?? shiftType;
    final emoji = AppConstants.shiftEmojis[shiftType] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 5 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: compact ? 12 : 14)),
            const SizedBox(width: 5),
            Text(
              compact ? _shortLabel(shiftType) : label,
              style: GoogleFonts.nunito(
                color: selected ? color : AppColors.textSecondary,
                fontSize: compact ? 12 : 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortLabel(String type) {
    switch (type) {
      case 'day':
        return 'Day';
      case 'afternoon':
        return 'Aft.';
      case 'night':
        return 'Night';
      case 'rotating':
        return 'Rot.';
      case 'off':
        return 'Off';
      default:
        return type;
    }
  }
}
