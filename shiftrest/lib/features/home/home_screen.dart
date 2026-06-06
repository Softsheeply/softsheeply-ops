import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../core/sleep_planner_service.dart';
import '../../core/alertness_service.dart';
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimations = List.generate(
      7,
      (i) => CurvedAnimation(
        parent: _fadeController,
        curve: Interval(i * 0.08, 0.55 + i * 0.08, curve: Curves.easeOut),
      ),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final shiftsAsync = ref.watch(shiftsProvider);
    final plansAsync = ref.watch(sleepPlansProvider);

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowStr =
        DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(shiftsProvider);
          ref.invalidate(sleepPlansProvider);
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: profileAsync.when(
                  data: (profile) => Text(
                    _greeting(profile?['name'] as String?),
                    style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    DateFormat('EEE, MMM d').format(now),
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Today's shift card
                  _buildFadeSlide(
                    _cardAnimations[0],
                    _TodayShiftCard(
                      shiftsAsync: shiftsAsync,
                      todayStr: todayStr,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tonight's sleep window
                  _buildFadeSlide(
                    _cardAnimations[1],
                    _TonightsSleepCard(
                      plansAsync: plansAsync,
                      todayStr: todayStr,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Caffeine cutoff
                  _buildFadeSlide(
                    _cardAnimations[2],
                    _CaffeineCard(
                      plansAsync: plansAsync,
                      todayStr: todayStr,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tomorrow preview
                  _buildFadeSlide(
                    _cardAnimations[3],
                    _TomorrowPreviewCard(
                      shiftsAsync: shiftsAsync,
                      plansAsync: plansAsync,
                      tomorrowStr: tomorrowStr,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sleep debt tracker
                  _buildFadeSlide(
                    _cardAnimations[4],
                    _SleepDebtCard(profileAsync: profileAsync),
                  ),
                  const SizedBox(height: 12),

                  // Alertness prediction
                  _buildFadeSlide(
                    _cardAnimations[5],
                    _AlertnessCard(
                      shiftsAsync: shiftsAsync,
                      profileAsync: profileAsync,
                      todayStr: todayStr,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick log button
                  _buildFadeSlide(
                    _cardAnimations[6],
                    _QuickLogCard(),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFadeSlide(Animation<double> anim, Widget child) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  String _greeting(String? name) {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour >= 5 && hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }
    if (name != null && name.isNotEmpty && name != 'Shift Worker') {
      return '$timeGreeting, $name';
    }
    return timeGreeting;
  }
}

class _TodayShiftCard extends ConsumerWidget {
  final AsyncValue<List<ShiftModel>> shiftsAsync;
  final String todayStr;

  const _TodayShiftCard(
      {required this.shiftsAsync, required this.todayStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return shiftsAsync.when(
      data: (shifts) {
        final todayShift = shifts.cast<ShiftModel?>().firstWhere(
              (s) => s?.date == todayStr,
              orElse: () => null,
            );

        if (todayShift == null) {
          return _NoShiftCard(onTap: () => context.go('/schedule'));
        }

        final color = AppColors.shiftColor(todayShift.shiftType);
        final emoji =
            AppConstants.shiftEmojis[todayShift.shiftType] ?? '📅';
        final label = AppConstants.shiftTypeLabels[todayShift.shiftType] ??
            todayShift.shiftType;

        String statusText = '';
        if (todayShift.startTime != null && todayShift.endTime != null) {
          final now = DateTime.now();
          final parts = todayShift.startTime!.split(':');
          final shiftStart = DateTime(now.year, now.month, now.day,
              int.parse(parts[0]), int.parse(parts[1]));
          final diff = shiftStart.difference(now);
          if (diff.isNegative) {
            final endParts = todayShift.endTime!.split(':');
            final shiftEnd = DateTime(now.year, now.month, now.day,
                int.parse(endParts[0]), int.parse(endParts[1]));
            if (now.isBefore(shiftEnd) ||
                shiftEnd.hour < shiftStart.hour) {
              statusText = 'You\'re currently on shift';
            } else {
              statusText = 'Shift completed';
            }
          } else {
            final hours = diff.inHours;
            final mins = diff.inMinutes % 60;
            if (hours > 0) {
              statusText = 'Starts in ${hours}h ${mins}m';
            } else {
              statusText = 'Starts in ${mins}m';
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.sora(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (todayShift.startTime != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${todayShift.startTime} – ${todayShift.endTime ?? "?"}',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (statusText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: GoogleFonts.nunito(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.textSecondary, size: 18),
                onPressed: () => context.go('/schedule'),
              ),
            ],
          ),
        );
      },
      loading: () => _shimmerCard(),
      error: (_, __) => _NoShiftCard(onTap: () => context.go('/schedule')),
    );
  }
}

class _NoShiftCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NoShiftCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('📅', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No shift today',
                    style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to add your schedule',
                    style: GoogleFonts.nunito(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _TonightsSleepCard extends ConsumerWidget {
  final AsyncValue<List<SleepPlanModel>> plansAsync;
  final String todayStr;

  const _TonightsSleepCard(
      {required this.plansAsync, required this.todayStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return plansAsync.when(
      data: (plans) {
        final todayPlans = plans.where((p) => p.forDate == todayStr);
        final mainPlan = todayPlans.cast<SleepPlanModel?>().firstWhere(
              (p) => p?.planType == 'main',
              orElse: () => null,
            );

        if (mainPlan == null) {
          return GestureDetector(
            onTap: () => context.go('/planner'),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'No sleep plan yet — tap to generate one',
                      style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        }

        final start = SleepPlannerService.formatTimeFromDateTime(
            mainPlan.windowStart);
        final end = SleepPlannerService.formatTimeFromDateTime(
            mainPlan.windowEnd);

        return GestureDetector(
          onTap: () => context.go('/planner'),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🌙',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      "Tonight's Sleep Window",
                      style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${mainPlan.durationHours.toStringAsFixed(1)} hrs',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Sleep $start → $end',
                  style: GoogleFonts.sora(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (mainPlan.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    mainPlan.notes,
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => _shimmerCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CaffeineCard extends ConsumerWidget {
  final AsyncValue<List<SleepPlanModel>> plansAsync;
  final String todayStr;

  const _CaffeineCard(
      {required this.plansAsync, required this.todayStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return plansAsync.when(
      data: (plans) {
        final todayPlans = plans.where((p) => p.forDate == todayStr);
        final plan = todayPlans.cast<SleepPlanModel?>().firstWhere(
              (p) => p?.caffeineDeadline != null,
              orElse: () => null,
            );

        if (plan?.caffeineDeadline == null) return const SizedBox.shrink();

        final deadline = SleepPlannerService.formatTimeFromDateTime(
            plan!.caffeineDeadline!);
        final sleepStart = SleepPlannerService.formatTimeFromDateTime(
            plan.windowStart);
        final now = DateTime.now();
        final isUrgent = plan.caffeineDeadline!
            .difference(now)
            .inMinutes < 60 && plan.caffeineDeadline!.isAfter(now);
        final isPast = plan.caffeineDeadline!.isBefore(now);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isUrgent || isPast)
                  ? AppColors.warning.withOpacity(0.4)
                  : AppColors.surfaceVariant,
            ),
          ),
          child: Row(
            children: [
              const Text('☕', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPast
                          ? 'Caffeine cutoff passed'
                          : 'Last caffeine by $deadline',
                      style: GoogleFonts.sora(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '6hrs before your $sleepStart sleep window',
                      style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TomorrowPreviewCard extends ConsumerWidget {
  final AsyncValue<List<ShiftModel>> shiftsAsync;
  final AsyncValue<List<SleepPlanModel>> plansAsync;
  final String tomorrowStr;

  const _TomorrowPreviewCard({
    required this.shiftsAsync,
    required this.plansAsync,
    required this.tomorrowStr,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tomorrowShift = shiftsAsync.when(
      data: (shifts) => shifts.cast<ShiftModel?>().firstWhere(
            (s) => s?.date == tomorrowStr,
            orElse: () => null,
          ),
      loading: () => null,
      error: (_, __) => null,
    );

    final tomorrowPlan = plansAsync.when(
      data: (plans) => plans.cast<SleepPlanModel?>().firstWhere(
            (p) => p?.forDate == tomorrowStr && p?.planType == 'main',
            orElse: () => null,
          ),
      loading: () => null,
      error: (_, __) => null,
    );

    if (tomorrowShift == null && tomorrowPlan == null) {
      return const SizedBox.shrink();
    }

    final shiftLabel = tomorrowShift != null
        ? '${AppConstants.shiftEmojis[tomorrowShift.shiftType]} ${AppConstants.shiftTypeLabels[tomorrowShift.shiftType]}'
        : 'No shift';

    String planText = 'Sleep plan ready';
    if (tomorrowPlan != null) {
      final start = SleepPlannerService.formatTimeFromDateTime(
          tomorrowPlan.windowStart);
      planText = 'Sleep plan: $start';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tomorrow',
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shiftLabel,
                  style: GoogleFonts.sora(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              planText,
              style: GoogleFonts.nunito(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLogCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/log'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.15),
              AppColors.nightPurple.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log last night\'s sleep',
                    style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Track your quality & duration',
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ---- Sleep Debt Card ----

class _SleepDebtCard extends ConsumerWidget {
  final AsyncValue<Map<String, dynamic>?> profileAsync;
  const _SleepDebtCard({required this.profileAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(sleepLogsProvider);

    final goalHours = profileAsync.when(
      data: (p) => (p?['sleep_goal_hours'] as num?)?.toDouble() ?? 7.5,
      loading: () => 7.5,
      error: (_, __) => 7.5,
    );

    return logsAsync.when(
      data: (logs) {
        final weekDebt = _computeWeekDebt(logs, goalHours);
        final daysLogged = _daysLoggedThisWeek(logs);
        final isDeficit = weekDebt < 0;
        final color = isDeficit
            ? AppColors.warning
            : weekDebt > 1
                ? AppColors.success
                : AppColors.primary;
        final absDebt = weekDebt.abs();

        if (daysLogged == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => context.go('/history'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(isDeficit ? '😓' : '✨',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Sleep debt this week',
                      style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$daysLogged/7 days logged',
                      style: GoogleFonts.nunito(
                          color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isDeficit
                          ? '-${absDebt.toStringAsFixed(1)}h'
                          : '+${absDebt.toStringAsFixed(1)}h',
                      style: GoogleFonts.jetBrainsMono(
                        color: color,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        isDeficit ? 'behind goal' : 'ahead of goal',
                        style: GoogleFonts.nunito(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (absDebt / (goalHours * 7)).clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        color.withOpacity(0.7)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isDeficit
                      ? 'Try to recover ${absDebt.toStringAsFixed(1)}h before your next heavy week.'
                      : 'Great work — you\'re staying ahead of your sleep goal.',
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  double _computeWeekDebt(
      List<Map<String, dynamic>> logs, double goalHours) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    double actual = 0;
    int days = 0;

    for (final log in logs) {
      final dateStr = log['date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null || date.isBefore(weekAgo)) continue;

      final start = log['sleep_start'] as String?;
      final end = log['sleep_end'] as String?;
      if (start != null && end != null) {
        try {
          final s = DateTime.parse(start);
          final e = DateTime.parse(end);
          var diff = e.difference(s).inMinutes / 60.0;
          if (diff < 0) diff += 24;
          actual += diff;
          days++;
        } catch (_) {}
      }
    }

    if (days == 0) return 0;
    final goal = goalHours * days;
    return actual - goal;
  }

  int _daysLoggedThisWeek(List<Map<String, dynamic>> logs) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final dates = <String>{};
    for (final log in logs) {
      final dateStr = log['date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date != null && date.isAfter(weekAgo)) dates.add(dateStr);
    }
    return dates.length;
  }
}

// ---- Alertness Card ----

class _AlertnessCard extends ConsumerWidget {
  final AsyncValue<List<ShiftModel>> shiftsAsync;
  final AsyncValue<Map<String, dynamic>?> profileAsync;
  final String todayStr;

  const _AlertnessCard({
    required this.shiftsAsync,
    required this.profileAsync,
    required this.todayStr,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(sleepLogsProvider);

    final goalHours = profileAsync.when(
      data: (p) => (p?['sleep_goal_hours'] as num?)?.toDouble() ?? 7.5,
      loading: () => 7.5,
      error: (_, __) => 7.5,
    );

    final logs = logsAsync.asData?.value ?? [];
    if (logs.isEmpty) return const SizedBox.shrink();

    // Find today's shift start for prediction context
    final todayShift = shiftsAsync.asData?.value
        .cast<ShiftModel?>()
        .firstWhere((s) => s?.date == todayStr, orElse: () => null);

    DateTime? shiftStart;
    if (todayShift?.startTime != null) {
      final now = DateTime.now();
      final parts = todayShift!.startTime!.split(':');
      shiftStart = DateTime(
        now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
      if (shiftStart.isBefore(now)) shiftStart = null;
    }

    final prediction = AlertnessService.predict(
      now: DateTime.now(),
      lastWakeTime: _parseLastWakeTime(logs),
      recentLogs: logs,
      sleepGoalHours: goalHours,
      shiftStartTime: shiftStart,
    );

    final levelColor = Color(AlertnessService.levelHue(prediction.level).toInt());
    final levelLabel = AlertnessService.levelLabel(prediction.level);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: levelColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Alertness Prediction',
                style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  levelLabel,
                  style: GoogleFonts.nunito(
                    color: levelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${prediction.score.round()}',
                style: GoogleFonts.jetBrainsMono(
                  color: levelColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/100',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prediction.score / 100,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(levelColor.withOpacity(0.7)),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
          if (prediction.tips.isNotEmpty)
            Text(
              prediction.tips.first,
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  DateTime? _parseLastWakeTime(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return null;
    final recent = logs.first;
    final endStr = recent['sleep_end'] as String?;
    if (endStr == null) return null;
    try {
      return DateTime.parse(endStr);
    } catch (_) {
      return null;
    }
  }
}

Widget _shimmerCard() {
  return Container(
    height: 80,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
  );
}
