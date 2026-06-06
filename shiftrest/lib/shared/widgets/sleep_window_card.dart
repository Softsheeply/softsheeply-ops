import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/sleep_planner_service.dart';

class SleepWindowCard extends StatelessWidget {
  final SleepPlanModel plan;
  final VoidCallback? onTap;

  const SleepWindowCard({super.key, required this.plan, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(plan.planType);
    final icon = _iconForType(plan.planType);
    final label = _labelForType(plan.planType);
    final start = SleepPlannerService.formatTimeFromDateTime(plan.windowStart);
    final end = SleepPlannerService.formatTimeFromDateTime(plan.windowEnd);
    final hours = plan.durationHours.toStringAsFixed(1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: GoogleFonts.nunito(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$hours hrs',
                    style: GoogleFonts.jetBrainsMono(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          start,
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Sleep',
                          style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Icon(Icons.arrow_forward,
                            color: AppColors.textSecondary, size: 16),
                        _buildTimeBar(plan.durationHours, color),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          end,
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Wake',
                          style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (plan.caffeineDeadline != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('☕', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(
                        'Last caffeine by ${SleepPlannerService.formatTimeFromDateTime(plan.caffeineDeadline!)}',
                        style: GoogleFonts.nunito(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (plan.lightGuidance.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        plan.lightGuidance,
                        style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (plan.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  plan.notes,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBar(double hours, Color color) {
    final width = (hours / 9.0).clamp(0.0, 1.0) * 80;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      height: 4,
      width: width,
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'main':
        return AppColors.primary;
      case 'nap':
        return AppColors.accent;
      case 'recovery':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _iconForType(String type) {
    switch (type) {
      case 'main':
        return '🌙';
      case 'nap':
        return '😴';
      case 'recovery':
        return '💚';
      default:
        return '🌙';
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'main':
        return 'Main Sleep';
      case 'nap':
        return 'Power Nap';
      case 'recovery':
        return 'Recovery Sleep';
      default:
        return 'Sleep';
    }
  }
}
