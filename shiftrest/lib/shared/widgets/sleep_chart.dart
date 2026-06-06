import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class SleepDurationChart extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final double goalHours;

  const SleepDurationChart({
    super.key,
    required this.logs,
    required this.goalHours,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _emptyState();
    }

    final spots = <FlSpot>[];
    final recent = logs.take(14).toList().reversed.toList();

    for (int i = 0; i < recent.length; i++) {
      final log = recent[i];
      final start = log['sleep_start'] as String?;
      final end = log['sleep_end'] as String?;
      if (start != null && end != null) {
        try {
          final s = DateTime.parse(start);
          final e = DateTime.parse(end);
          var diff = e.difference(s).inMinutes / 60.0;
          if (diff < 0) diff += 24;
          spots.add(FlSpot(i.toDouble(), diff.clamp(0, 12)));
        } catch (_) {}
      }
    }

    if (spots.isEmpty) return _emptyState();

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.surfaceVariant,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 2,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}h',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < recent.length) {
                    final date = recent[idx]['date'] as String? ?? '';
                    if (date.length >= 10) {
                      return Text(
                        '${date.substring(5, 7)}/${date.substring(8)}',
                        style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 12,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.primary,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
            LineChartBarData(
              spots: spots.isNotEmpty
                  ? [
                      FlSpot(0, goalHours),
                      FlSpot(spots.last.x, goalHours),
                    ]
                  : [],
              isCurved: false,
              color: AppColors.success.withOpacity(0.6),
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              dashArray: [4, 4],
            ),
          ],
        ),
        duration: const Duration(milliseconds: 600),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'No sleep data yet.\nLog your first night to see your chart.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class SleepQualityChart extends StatelessWidget {
  final List<Map<String, dynamic>> logs;

  const SleepQualityChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No quality data yet.',
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final recent = logs.take(14).toList().reversed.toList();
    final bars = <BarChartGroupData>[];

    for (int i = 0; i < recent.length; i++) {
      final q = (recent[i]['quality'] as int?) ?? 0;
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: q.toDouble(),
            width: 12,
            color: _qualityColor(q),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          maxY: 5,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.surfaceVariant,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: bars,
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Color _qualityColor(int quality) {
    switch (quality) {
      case 5:
        return AppColors.success;
      case 4:
        return AppColors.primary;
      case 3:
        return AppColors.accent;
      case 2:
        return AppColors.warning;
      case 1:
        return const Color(0xFFE53935);
      default:
        return AppColors.textSecondary;
    }
  }
}
