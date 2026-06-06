import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../shared/widgets/sleep_chart.dart';
import '../../shared/widgets/quality_stars.dart';

class SleepHistoryScreen extends ConsumerWidget {
  const SleepHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(sleepLogsProvider);
    final profileAsync = ref.watch(profileProvider);

    final goalHours = profileAsync.when(
      data: (p) => (p?['sleep_goal_hours'] as num?)?.toDouble() ?? 7.5,
      loading: () => 7.5,
      error: (_, __) => 7.5,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sleep History')),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return _EmptyHistory();
          }

          final stats = _computeStats(logs);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Avg this week',
                            value: '${stats['weekAvgHours']?.toStringAsFixed(1) ?? "–"}h',
                            subtitle: 'duration',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Avg quality',
                            value: stats['weekAvgQuality'] != null
                                ? '${stats['weekAvgQuality']!.toStringAsFixed(1)}/5'
                                : '–',
                            subtitle: 'this week',
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Best night',
                            value: '${stats['bestHours']?.toStringAsFixed(1) ?? "–"}h',
                            subtitle: 'this month',
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Duration chart
                    Text(
                      'Duration (last 14 days)',
                      style: GoogleFonts.sora(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 3,
                          color: AppColors.success.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${goalHours.toStringAsFixed(1)}h goal',
                          style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SleepDurationChart(logs: logs, goalHours: goalHours),
                    const SizedBox(height: 20),

                    // Quality chart
                    Text(
                      'Sleep quality',
                      style: GoogleFonts.sora(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SleepQualityChart(logs: logs),
                    const SizedBox(height: 20),

                    // Log list
                    Text(
                      'All entries',
                      style: GoogleFonts.sora(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...logs.map((log) => _SleepLogRow(
                          log: log,
                          onDelete: () => ref
                              .read(sleepLogsProvider.notifier)
                              .delete(log['id'] as int),
                        )),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary))),
      ),
    );
  }

  Map<String, double?> _computeStats(List<Map<String, dynamic>> logs) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    double totalWeekHours = 0;
    double totalWeekQuality = 0;
    int weekCount = 0;
    double bestHours = 0;

    for (final log in logs) {
      final dateStr = log['date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final start = log['sleep_start'] as String?;
      final end = log['sleep_end'] as String?;
      if (start != null && end != null) {
        try {
          final s = DateTime.parse(start);
          final e = DateTime.parse(end);
          var diff = e.difference(s).inMinutes / 60.0;
          if (diff < 0) diff += 24;

          if (date.isAfter(monthAgo)) {
            if (diff > bestHours) bestHours = diff;
          }

          if (date.isAfter(weekAgo)) {
            totalWeekHours += diff;
            final q = (log['quality'] as int?) ?? 0;
            if (q > 0) {
              totalWeekQuality += q;
            }
            weekCount++;
          }
        } catch (_) {}
      }
    }

    return {
      'weekAvgHours': weekCount > 0 ? totalWeekHours / weekCount : null,
      'weekAvgQuality': weekCount > 0 ? totalWeekQuality / weekCount : null,
      'bestHours': bestHours > 0 ? bestHours : null,
    };
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _SleepLogRow extends StatelessWidget {
  final Map<String, dynamic> log;
  final VoidCallback onDelete;

  const _SleepLogRow({required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = log['date'] as String? ?? '';
    final date = DateTime.tryParse(dateStr);
    final dateLabel =
        date != null ? DateFormat('EEE, MMM d').format(date) : dateStr;

    final start = log['sleep_start'] as String?;
    final end = log['sleep_end'] as String?;
    final quality = (log['quality'] as int?) ?? 0;
    final isSplit = (log['is_split_sleep'] as int?) == 1;

    String durationStr = '—';
    if (start != null && end != null) {
      try {
        final s = DateTime.parse(start);
        final e = DateTime.parse(end);
        var diff = e.difference(s).inMinutes / 60.0;
        if (diff < 0) diff += 24;
        durationStr = '${diff.toStringAsFixed(1)}h';
      } catch (_) {}
    }

    String timeRangeStr = '';
    if (start != null && end != null) {
      try {
        final s = DateTime.parse(start);
        final e = DateTime.parse(end);
        timeRangeStr = '${_fmt(s)} – ${_fmt(e)}';
      } catch (_) {}
    }

    return Dismissible(
      key: Key('log-${log['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline,
            color: AppColors.warning),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Delete entry?',
                style: GoogleFonts.sora(color: AppColors.text)),
            content: Text('Remove sleep log for $dateLabel?',
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Delete',
                      style: GoogleFonts.nunito(
                          color: AppColors.warning))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dateLabel,
                        style: GoogleFonts.sora(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isSplit) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Split',
                            style: GoogleFonts.nunito(
                                color: AppColors.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (timeRangeStr.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      timeRangeStr,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  durationStr,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (quality > 0) ...[
                  const SizedBox(height: 2),
                  QualityStars(quality: quality, size: 14),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📊', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          Text(
            'No sleep logs yet',
            style: GoogleFonts.sora(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Log your first night\'s sleep\nto start tracking your patterns.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}
