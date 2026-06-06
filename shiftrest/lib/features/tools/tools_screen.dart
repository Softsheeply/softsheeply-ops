import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'meal_timing_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tools'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.nunito(
              fontSize: 13, fontWeight: FontWeight.w600),
          isScrollable: true,
          tabs: const [
            Tab(text: '☕ Caffeine'),
            Tab(text: '💡 Light'),
            Tab(text: '🔄 Recovery'),
            Tab(text: '🌿 Melatonin'),
            Tab(text: '🍽️ Meals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CaffeineCalculatorTab(),
          LightGuideTab(),
          RecoveryPlannerTab(),
          MelatoninTimingTab(),
          MealTimingTab(),
        ],
      ),
    );
  }
}

// ---- Caffeine Calculator ----

class CaffeineCalculatorTab extends StatefulWidget {
  const CaffeineCalculatorTab({super.key});

  @override
  State<CaffeineCalculatorTab> createState() =>
      _CaffeineCalculatorTabState();
}

class _CaffeineCalculatorTabState extends State<CaffeineCalculatorTab> {
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 0);
  String _sensitivity = 'normal';

  int get _caffeineHours {
    switch (_sensitivity) {
      case 'sensitive':
        return AppConstants.caffeineSensitiveHours;
      case 'very_sensitive':
        return AppConstants.caffeineVerySensitiveHours;
      default:
        return AppConstants.caffeineHalfLifeHours;
    }
  }

  TimeOfDay get _deadline {
    int hour = _sleepTime.hour - _caffeineHours;
    if (hour < 0) hour += 24;
    return TimeOfDay(hour: hour, minute: _sleepTime.minute);
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hour;
    final minute = t.minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'When do you need to fall asleep?',
                  style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _sleepTime,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                            surface: AppColors.surface,
                            onSurface: AppColors.text,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _sleepTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bedtime_outlined,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(_sleepTime),
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Caffeine sensitivity',
                  style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _SensitivityChip(
                      label: 'Normal',
                      value: 'normal',
                      selected: _sensitivity == 'normal',
                      onTap: () =>
                          setState(() => _sensitivity = 'normal'),
                    ),
                    _SensitivityChip(
                      label: 'Sensitive',
                      value: 'sensitive',
                      selected: _sensitivity == 'sensitive',
                      onTap: () =>
                          setState(() => _sensitivity = 'sensitive'),
                    ),
                    _SensitivityChip(
                      label: 'Very Sensitive',
                      value: 'very_sensitive',
                      selected: _sensitivity == 'very_sensitive',
                      onTap: () => setState(
                          () => _sensitivity = 'very_sensitive'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Result
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withOpacity(0.2),
                  AppColors.accent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text('☕', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  'Your last caffeine should be by',
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(_deadline),
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.warning,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Caffeine has a 6-hour half-life. At ${_sensitivityLabel()} sensitivity, aim for $_caffeineHours hours before sleep.',
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sensitivityLabel() {
    switch (_sensitivity) {
      case 'sensitive':
        return 'high';
      case 'very_sensitive':
        return 'very high';
      default:
        return 'normal';
    }
  }
}

class _SensitivityChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _SensitivityChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.warning.withOpacity(0.2)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.warning
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: selected
                ? AppColors.warning
                : AppColors.textSecondary,
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---- Light Guide ----

class LightGuideTab extends ConsumerWidget {
  const LightGuideTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Light & Darkness Guide',
                  style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Light is the most powerful signal your body uses to set its internal clock. Use it strategically.',
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _LightTipCard(
            emoji: '☀️',
            title: 'Get bright light exposure',
            description:
                'Step outside within 30-60 minutes of waking up. Even on cloudy days, outdoor light is 10-100x brighter than indoor lighting. This is the strongest anchor for your circadian clock.',
            color: AppColors.accent,
            timing: 'Within 60 min of waking',
          ),
          const SizedBox(height: 12),

          _LightTipCard(
            emoji: '🌙',
            title: 'Avoid bright light before bed',
            description:
                'Dim all lights 1-2 hours before your sleep window. Bright light suppresses melatonin production. Night-shift workers: this means using blackout curtains before your daytime sleep.',
            color: AppColors.nightPurple,
            timing: '2 hrs before sleep',
          ),
          const SizedBox(height: 12),

          _LightTipCard(
            emoji: '📱',
            title: 'Blue light from screens',
            description:
                'Phone and screen light is especially disruptive. Enable night mode or use blue-light blocking glasses. Best: no screens 30-60 minutes before sleep.',
            color: AppColors.primary,
            timing: '1 hr before sleep',
          ),
          const SizedBox(height: 20),

          Text(
            'Essential checklist',
            style: GoogleFonts.sora(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          _ChecklistCard(items: const [
            '🪟 Blackout curtains (especially for day sleep)',
            '😴 Eye mask as backup',
            '👓 Blue light blocking glasses for screen time',
            '📵 Phone on do-not-disturb during sleep',
            '☀️ Outdoor light first thing after waking',
            '🔆 Bright indoor light if you can\'t get outside',
          ]),
        ],
      ),
    );
  }
}

class _LightTipCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final String timing;

  const _LightTipCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.timing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timing,
                  style: GoogleFonts.nunito(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatefulWidget {
  final List<String> items;
  const _ChecklistCard({required this.items});

  @override
  State<_ChecklistCard> createState() => _ChecklistCardState();
}

class _ChecklistCardState extends State<_ChecklistCard> {
  late final List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.items.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(widget.items.length, (i) {
          return GestureDetector(
            onTap: () =>
                setState(() => _checked[i] = !_checked[i]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _checked[i]
                          ? AppColors.success
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _checked[i]
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                    child: _checked[i]
                        ? const Icon(Icons.check,
                            color: Colors.black, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.items[i],
                      style: GoogleFonts.nunito(
                        color: _checked[i]
                            ? AppColors.textSecondary
                            : AppColors.text,
                        fontSize: 13,
                        decoration: _checked[i]
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---- Recovery Planner ----

class RecoveryPlannerTab extends StatefulWidget {
  const RecoveryPlannerTab({super.key});

  @override
  State<RecoveryPlannerTab> createState() =>
      _RecoveryPlannerTabState();
}

class _RecoveryPlannerTabState extends State<RecoveryPlannerTab> {
  int _nightShifts = 3;
  List<_RecoveryDay>? _plan;

  void _generatePlan() {
    final days = <_RecoveryDay>[];

    for (int i = 0; i < 3; i++) {
      final date =
          DateTime.now().add(Duration(days: i));
      late String sleepWindow;
      late String notes;

      if (i == 0) {
        final endHour = 7 + (_nightShifts > 3 ? 1 : 0);
        sleepWindow = '${endHour}:30 AM → ${endHour + 7}:30 PM';
        notes = 'Immediate recovery sleep. Cap at 7-8hrs to avoid full schedule flip.';
      } else if (i == 1) {
        sleepWindow = '2:00 PM → 10:00 PM';
        notes = 'Day 2 — shifting earlier. Your body clock is moving back toward normal.';
      } else {
        sleepWindow = '11:00 PM → 7:00 AM';
        notes = 'Anchor sleep — back to normal timing. This is the goal.';
      }

      days.add(_RecoveryDay(
        dayNumber: i + 1,
        date: date,
        sleepWindow: sleepWindow,
        notes: notes,
      ));
    }

    setState(() => _plan = days);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How many consecutive night shifts did you just finish?',
                  style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _nightShifts.toDouble(),
                        min: 1,
                        max: 7,
                        divisions: 6,
                        onChanged: (v) => setState(
                            () => _nightShifts = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        _nightShifts.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1',
                        style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 11)),
                    Text('7 nights',
                        style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generatePlan,
                    child: Text(
                      'Generate 3-day recovery plan',
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_plan != null) ...[
            const SizedBox(height: 20),
            Text(
              'Your recovery plan',
              style: GoogleFonts.sora(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Your body takes about 1 day to adjust per hour of time shift. After $_nightShifts night shift${_nightShifts > 1 ? "s" : ""}, give yourself 2-3 days. Be patient.',
                style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ..._plan!.map((day) => _RecoveryDayCard(day: day)),
          ],
        ],
      ),
    );
  }
}

class _RecoveryDay {
  final int dayNumber;
  final DateTime date;
  final String sleepWindow;
  final String notes;

  const _RecoveryDay({
    required this.dayNumber,
    required this.date,
    required this.sleepWindow,
    required this.notes,
  });
}

class _RecoveryDayCard extends StatelessWidget {
  final _RecoveryDay day;
  const _RecoveryDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.warning, AppColors.accent, AppColors.success];
    final color = colors[(day.dayNumber - 1).clamp(0, 2)];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'D${day.dayNumber}',
                style: GoogleFonts.sora(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.sleepWindow,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day.notes,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Melatonin Timing ----

class MelatoninTimingTab extends StatefulWidget {
  const MelatoninTimingTab({super.key});

  @override
  State<MelatoninTimingTab> createState() => _MelatoninTimingTabState();
}

class _MelatoninTimingTabState extends State<MelatoninTimingTab> {
  TimeOfDay _targetSleepTime = const TimeOfDay(hour: 22, minute: 0);
  String _shiftType = 'night';
  bool _showResult = false;

  TimeOfDay get _melatoninTime {
    // Low-dose melatonin (0.5mg) taken 2hrs before target sleep
    // High-dose (3-5mg): 30-60 min before
    int hour = _targetSleepTime.hour - 2;
    if (hour < 0) hour += 24;
    return TimeOfDay(hour: hour, minute: _targetSleepTime.minute);
  }

  TimeOfDay get _highDoseTime {
    int hour = _targetSleepTime.hour;
    int minute = _targetSleepTime.minute - 45;
    if (minute < 0) {
      minute += 60;
      hour = (hour - 1) % 24;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _fmt(TimeOfDay t) {
    final hour = t.hour;
    final minute = t.minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Melatonin Timing Calculator',
                  style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Melatonin works by timing, not by knocking you out. Most shift workers take it wrong.',
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'When do you need to fall asleep?',
                  style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _targetSleepTime,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                            surface: AppColors.surface,
                            onSurface: AppColors.text,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _targetSleepTime = picked;
                        _showResult = true;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bedtime_outlined,
                            color: AppColors.nightPurple, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _fmt(_targetSleepTime),
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Shift type',
                  style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ['day', 'night', 'off'].map((type) {
                    final labels = {
                      'day': '🌅 Day shift',
                      'night': '🌙 Night shift',
                      'off': '✅ Day off'
                    };
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _shiftType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _shiftType == type
                              ? AppColors.nightPurple.withOpacity(0.2)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _shiftType == type
                                ? AppColors.nightPurple
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          labels[type]!,
                          style: GoogleFonts.nunito(
                            color: _shiftType == type
                                ? AppColors.nightPurple
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: _shiftType == type
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.nightPurple),
                    onPressed: () => setState(() => _showResult = true),
                    child: Text(
                      'Calculate timing',
                      style: GoogleFonts.nunito(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_showResult) ...[
            const SizedBox(height: 16),

            // Low dose recommendation
            _MelatoninResultCard(
              label: 'Low dose (0.5mg) — Recommended',
              time: _melatoninTime,
              description:
                  'Most effective for circadian shifting. Take 0.5mg at ${_fmt(_melatoninTime)} — 2 hours before your target sleep. This dose mimics natural melatonin without grogginess.',
              color: AppColors.success,
              isRecommended: true,
            ),
            const SizedBox(height: 10),

            // High dose info
            _MelatoninResultCard(
              label: 'Higher dose (1–5mg)',
              time: _highDoseTime,
              description:
                  'Take 45–60 min before sleep at ${_fmt(_highDoseTime)}. May cause grogginess the next day. Start low — more melatonin is not more effective for shifting your clock.',
              color: AppColors.accent,
              isRecommended: false,
            ),
            const SizedBox(height: 16),

            _MelatoninScienceCard(shiftType: _shiftType),
            const SizedBox(height: 16),
            _MelatoninWarnings(),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _MelatoninResultCard extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final String description;
  final Color color;
  final bool isRecommended;

  const _MelatoninResultCard({
    required this.label,
    required this.time,
    required this.description,
    required this.color,
    required this.isRecommended,
  });

  String _fmt(TimeOfDay t) {
    final hour = t.hour;
    final minute = t.minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              if (isRecommended) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '✓ Best for shift workers',
                    style: GoogleFonts.nunito(
                        color: AppColors.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Take at ${_fmt(time)}',
            style: GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MelatoninScienceCard extends StatelessWidget {
  final String shiftType;
  const _MelatoninScienceCard({required this.shiftType});

  @override
  Widget build(BuildContext context) {
    final tips = shiftType == 'night'
        ? [
            'Take melatonin ~2hrs before your daytime sleep window starts.',
            'Keep the room fully dark — even small light exposure blocks melatonin.',
            'Do not take melatonin at the start of your night shift — it will make you drowsy when you need to be alert.',
            'Consistent dosing time retrains your clock faster than random use.',
          ]
        : shiftType == 'day'
            ? [
                'Take melatonin 2hrs before your target bedtime.',
                'Combine with a dim, screen-free wind-down routine.',
                'Melatonin is most useful when switching shift types — less necessary for stable schedules.',
              ]
            : [
                'Recovery day — take melatonin at your desired anchor sleep time minus 2hrs.',
                'This helps signal to your body what time you want to sleep.',
                'Use consistently for 3–4 nights to re-anchor your rhythm.',
              ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.nightPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.nightPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔬', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Science-backed tips for shift workers',
                style: GoogleFonts.sora(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•',
                        style: GoogleFonts.nunito(
                            color: AppColors.nightPurple,
                            fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _MelatoninWarnings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠️  A few things',
            style: GoogleFonts.sora(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Melatonin is a supplement, not a sleeping pill. It works best at low doses (0.5–1mg). Avoid driving or operating machinery after taking it. If you\'re on medication, check with your doctor.\n\nThis tool provides timing guidance only — not medical advice.',
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ---- Shared ----

class _ToolCard extends StatelessWidget {
  final Widget child;
  const _ToolCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
