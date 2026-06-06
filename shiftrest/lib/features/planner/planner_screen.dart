import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/sleep_planner_service.dart';
import '../../core/notifications.dart';
import '../../shared/widgets/sleep_window_card.dart';
import '../../shared/widgets/shift_chip.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  bool _splitSleep = false;
  bool _notificationsSet = false;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(sleepPlansProvider);
    final shiftsAsync = ref.watch(shiftsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sleep Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref
                  .read(sleepPlansProvider.notifier)
                  .generate(split: _splitSleep);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(sleepPlansProvider.notifier).generate(split: _splitSleep),
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Shift mini-timeline
                  _ShiftTimeline(shiftsAsync: shiftsAsync),
                  const SizedBox(height: 16),

                  // Controls
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text('😴', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Include split sleep',
                                style: GoogleFonts.sora(
                                  color: AppColors.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '5hr main + 90min nap option',
                                style: GoogleFonts.nunito(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _splitSleep,
                          onChanged: (val) {
                            setState(() => _splitSleep = val);
                            ref
                                .read(sleepPlansProvider.notifier)
                                .generate(split: val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Plans
                  plansAsync.when(
                    data: (plans) {
                      if (plans.isEmpty) {
                        return _EmptyPlanner(
                          onAddShift: () => context.go('/schedule'),
                        );
                      }

                      final grouped = _groupByDate(plans);
                      final widgets = <Widget>[];

                      for (final entry in grouped.entries) {
                        widgets.add(
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 8, top: 4),
                            child: Text(
                              _dateLabel(entry.key),
                              style: GoogleFonts.sora(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                        for (final plan in entry.value) {
                          widgets.add(
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 400),
                              builder: (context, value, child) =>
                                  Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              ),
                              child: SleepWindowCard(plan: plan),
                            ),
                          );
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widgets,
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    ),
                    error: (e, _) => _ErrorState(
                      onRetry: () => ref
                          .read(sleepPlansProvider.notifier)
                          .generate(split: _splitSleep),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Set reminders button
                  plansAsync.when(
                    data: (plans) => plans.isNotEmpty
                        ? _SetRemindersButton(
                            plans: plans,
                            notificationsSet: _notificationsSet,
                            onSet: () =>
                                _scheduleNotifications(plans),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<SleepPlanModel>> _groupByDate(
      List<SleepPlanModel> plans) {
    final map = <String, List<SleepPlanModel>>{};
    for (final plan in plans) {
      map.putIfAbsent(plan.forDate, () => []).add(plan);
    }
    return map;
  }

  String _dateLabel(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today =
        DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == 2) return 'Day after tomorrow';
    return DateFormat('EEE, MMM d').format(date);
  }

  Future<void> _scheduleNotifications(
      List<SleepPlanModel> plans) async {
    final granted =
        await NotificationService.instance.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Permission needed for notifications',
              style: GoogleFonts.nunito(color: Colors.white),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    await NotificationService.instance.cancelAll();

    int id = 100;
    for (final plan in plans) {
      await NotificationService.instance.scheduleBedtimeReminder(
        id: id++,
        bedtime: plan.windowStart,
        minutesBefore: 30,
      );
      await NotificationService.instance.scheduleWakeReminder(
        id: id++,
        wakeTime: plan.windowEnd,
        shiftType: plan.planType,
      );
      if (plan.caffeineDeadline != null) {
        await NotificationService.instance.scheduleCaffeineAlert(
          id: id++,
          deadline: plan.caffeineDeadline!,
        );
      }
    }

    setState(() => _notificationsSet = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminders set for ${plans.length} sleep windows',
            style: GoogleFonts.nunito(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _ShiftTimeline extends StatelessWidget {
  final AsyncValue<List<ShiftModel>> shiftsAsync;

  const _ShiftTimeline({required this.shiftsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming shifts',
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          shiftsAsync.when(
            data: (shifts) {
              if (shifts.isEmpty) {
                return Text(
                  'No shifts added yet — add your schedule to get accurate plans.',
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                );
              }

              final upcoming = shifts.take(7).toList();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: upcoming.map((shift) {
                    final date = DateTime.parse(shift.date);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('E').format(date).substring(0, 2),
                            style: GoogleFonts.nunito(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ShiftChip(
                              shiftType: shift.shiftType,
                              compact: true),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const SizedBox(
                height: 30,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlanner extends StatelessWidget {
  final VoidCallback onAddShift;

  const _EmptyPlanner({required this.onAddShift});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Add your shifts to get a personalized sleep plan',
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ShiftRest calculates your optimal sleep windows based on your actual schedule.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_month, size: 16),
            label: const Text('Add my schedule'),
            onPressed: onAddShift,
          ),
          const SizedBox(height: 12),
          Text(
            'Or viewing demo plan above ↑',
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRemindersButton extends StatelessWidget {
  final List<SleepPlanModel> plans;
  final bool notificationsSet;
  final VoidCallback onSet;

  const _SetRemindersButton({
    required this.plans,
    required this.notificationsSet,
    required this.onSet,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: notificationsSet
              ? AppColors.success.withOpacity(0.2)
              : AppColors.primary,
          foregroundColor:
              notificationsSet ? AppColors.success : Colors.white,
        ),
        icon: Icon(
          notificationsSet
              ? Icons.check_circle_outline
              : Icons.notifications_outlined,
          size: 18,
        ),
        label: Text(
          notificationsSet
              ? 'Reminders set!'
              : 'Set reminders for this plan',
          style: GoogleFonts.nunito(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
        onPressed: notificationsSet ? null : onSet,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            'Could not generate plans',
            style: GoogleFonts.sora(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
