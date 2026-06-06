import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../core/sleep_planner_service.dart';
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
      5,
      (i) => CurvedAnimation(
        parent: _fadeController,
        curve: Interval(i * 0.1, 0.6 + i * 0.1, curve: Curves.easeOut),
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

                  // Quick log button
                  _buildFadeSlide(
                    _cardAnimations[4],
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

Widget _shimmerCard() {
  return Container(
    height: 80,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
  );
}
