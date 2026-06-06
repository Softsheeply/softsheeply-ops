import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/database.dart';
import '../../core/sleep_planner_service.dart' show ShiftModel;
import '../../shared/widgets/shift_chip.dart';

// ---- Data models ----

class ShiftPatternTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<PatternDay> rotation;
  final int cycleLengthDays;

  const ShiftPatternTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rotation,
    required this.cycleLengthDays,
  });
}

class PatternDay {
  final String shiftType;
  final String? startTime;
  final String? endTime;

  const PatternDay({
    required this.shiftType,
    this.startTime,
    this.endTime,
  });
}

// ---- Predefined templates ----

const List<ShiftPatternTemplate> kPatternTemplates = [
  ShiftPatternTemplate(
    id: 'continental',
    name: 'Continental Rotation',
    description: '2 days, 2 nights, 4 off. Most common rotating pattern.',
    icon: '🔄',
    cycleLengthDays: 8,
    rotation: [
      PatternDay(shiftType: 'day', startTime: '06:00', endTime: '14:00'),
      PatternDay(shiftType: 'day', startTime: '06:00', endTime: '14:00'),
      PatternDay(shiftType: 'night', startTime: '22:00', endTime: '06:00'),
      PatternDay(shiftType: 'night', startTime: '22:00', endTime: '06:00'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
    ],
  ),
  ShiftPatternTemplate(
    id: '4on4off_nights',
    name: '4 On 4 Off (Nights)',
    description: '4 night shifts followed by 4 days off.',
    icon: '🌙',
    cycleLengthDays: 8,
    rotation: [
      PatternDay(shiftType: 'night', startTime: '22:00', endTime: '06:00'),
      PatternDay(shiftType: 'night', startTime: '22:00', endTime: '06:00'),
      PatternDay(shiftType: 'night', startTime: '22:00', endTime: '06:00'),
      PatternDay(shiftType: 'night', startTime: '22:00', endTime: '06:00'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
    ],
  ),
  ShiftPatternTemplate(
    id: '4on4off_days',
    name: '4 On 4 Off (Days)',
    description: '4 day shifts followed by 4 days off.',
    icon: '🌅',
    cycleLengthDays: 8,
    rotation: [
      PatternDay(shiftType: 'day', startTime: '07:00', endTime: '19:00'),
      PatternDay(shiftType: 'day', startTime: '07:00', endTime: '19:00'),
      PatternDay(shiftType: 'day', startTime: '07:00', endTime: '19:00'),
      PatternDay(shiftType: 'day', startTime: '07:00', endTime: '19:00'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
    ],
  ),
  ShiftPatternTemplate(
    id: 'nhs_3shift',
    name: 'NHS 3-Shift',
    description: '3 days, then 3 afternoons, then 3 nights, then 3 off.',
    icon: '🏥',
    cycleLengthDays: 12,
    rotation: [
      PatternDay(shiftType: 'day', startTime: '07:30', endTime: '15:30'),
      PatternDay(shiftType: 'day', startTime: '07:30', endTime: '15:30'),
      PatternDay(shiftType: 'day', startTime: '07:30', endTime: '15:30'),
      PatternDay(shiftType: 'afternoon', startTime: '13:30', endTime: '21:30'),
      PatternDay(shiftType: 'afternoon', startTime: '13:30', endTime: '21:30'),
      PatternDay(shiftType: 'afternoon', startTime: '13:30', endTime: '21:30'),
      PatternDay(shiftType: 'night', startTime: '21:00', endTime: '07:30'),
      PatternDay(shiftType: 'night', startTime: '21:00', endTime: '07:30'),
      PatternDay(shiftType: 'night', startTime: '21:00', endTime: '07:30'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
    ],
  ),
  ShiftPatternTemplate(
    id: '5on2off_days',
    name: '5 On 2 Off (Standard)',
    description: 'Standard Mon–Fri days with weekends off.',
    icon: '📅',
    cycleLengthDays: 7,
    rotation: [
      PatternDay(shiftType: 'day', startTime: '09:00', endTime: '17:00'),
      PatternDay(shiftType: 'day', startTime: '09:00', endTime: '17:00'),
      PatternDay(shiftType: 'day', startTime: '09:00', endTime: '17:00'),
      PatternDay(shiftType: 'day', startTime: '09:00', endTime: '17:00'),
      PatternDay(shiftType: 'day', startTime: '09:00', endTime: '17:00'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
    ],
  ),
  ShiftPatternTemplate(
    id: '3on3off',
    name: '3 On 3 Off',
    description: '12-hour shifts, 3 days on then 3 days off.',
    icon: '⚡',
    cycleLengthDays: 6,
    rotation: [
      PatternDay(shiftType: 'day', startTime: '07:00', endTime: '19:00'),
      PatternDay(shiftType: 'day', startTime: '07:00', endTime: '19:00'),
      PatternDay(shiftType: 'day', startTime: '07:00', endTime: '19:00'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
    ],
  ),
  ShiftPatternTemplate(
    id: '5on5off_nights',
    name: '5 On 5 Off (Nights)',
    description: '5 night shifts then 5 days off.',
    icon: '🌌',
    cycleLengthDays: 10,
    rotation: [
      PatternDay(shiftType: 'night', startTime: '20:00', endTime: '08:00'),
      PatternDay(shiftType: 'night', startTime: '20:00', endTime: '08:00'),
      PatternDay(shiftType: 'night', startTime: '20:00', endTime: '08:00'),
      PatternDay(shiftType: 'night', startTime: '20:00', endTime: '08:00'),
      PatternDay(shiftType: 'night', startTime: '20:00', endTime: '08:00'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
      PatternDay(shiftType: 'off'),
    ],
  ),
];

// ---- Provider ----

final recurringShiftPatternProvider =
    StateNotifierProvider<RecurringPatternNotifier, RecurringPatternState>(
  (ref) => RecurringPatternNotifier(ref),
);

class RecurringPatternState {
  final String? activePatternId;
  final DateTime? patternStartDate;
  final bool isLoading;

  const RecurringPatternState({
    this.activePatternId,
    this.patternStartDate,
    this.isLoading = false,
  });

  RecurringPatternState copyWith({
    String? activePatternId,
    DateTime? patternStartDate,
    bool? isLoading,
    bool clearPattern = false,
  }) {
    return RecurringPatternState(
      activePatternId:
          clearPattern ? null : (activePatternId ?? this.activePatternId),
      patternStartDate: clearPattern
          ? null
          : (patternStartDate ?? this.patternStartDate),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RecurringPatternNotifier
    extends StateNotifier<RecurringPatternState> {
  final Ref _ref;

  RecurringPatternNotifier(this._ref)
      : super(const RecurringPatternState()) {
    _load();
  }

  Future<void> _load() async {
    // Load from profile or shared prefs if stored
  }

  Future<void> applyPattern({
    required ShiftPatternTemplate template,
    required DateTime startDate,
    required int weeksAhead,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final totalDays = weeksAhead * 7;
      final cycleLen = template.cycleLengthDays;

      for (int day = 0; day < totalDays; day++) {
        final date = startDate.add(Duration(days: day));
        final cyclePos = day % cycleLen;
        final pattern = template.rotation[cyclePos];

        final dateStr = _fmt(date);
        final shift = ShiftModel(
          date: dateStr,
          shiftType: pattern.shiftType,
          startTime: pattern.startTime,
          endTime: pattern.endTime,
        );

        await AppDatabase.instance.insertShift(shift.toMap());
      }

      state = state.copyWith(
        activePatternId: template.id,
        patternStartDate: startDate,
        isLoading: false,
      );

      _ref.read(shiftsProvider.notifier).loadUpcoming(days: 60);
      _ref.read(sleepPlansProvider.notifier).generate();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> clearPatternShifts({
    required DateTime from,
    required int days,
  }) async {
    final db = await AppDatabase.instance.database;
    final end = from.add(Duration(days: days));
    await db.delete(
      'shifts',
      where: 'date >= ? AND date <= ?',
      whereArgs: [_fmt(from), _fmt(end)],
    );
    state = state.copyWith(clearPattern: true);
    _ref.read(shiftsProvider.notifier).loadUpcoming(days: 60);
    _ref.read(sleepPlansProvider.notifier).generate();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ---- Screen ----

class ShiftPatternsScreen extends ConsumerStatefulWidget {
  const ShiftPatternsScreen({super.key});

  @override
  ConsumerState<ShiftPatternsScreen> createState() =>
      _ShiftPatternsScreenState();
}

class _ShiftPatternsScreenState
    extends ConsumerState<ShiftPatternsScreen> {
  ShiftPatternTemplate? _selectedTemplate;
  DateTime _startDate = DateTime.now();
  int _weeksAhead = 4;

  @override
  Widget build(BuildContext context) {
    final patternState = ref.watch(recurringShiftPatternProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shift Pattern Templates'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pick your rotation pattern and ShiftRest will fill your schedule for weeks ahead — no manual entry.',
                      style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Choose your pattern',
              style: GoogleFonts.sora(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            ...kPatternTemplates.map((template) => _TemplateCard(
                  template: template,
                  isSelected: _selectedTemplate?.id == template.id,
                  onTap: () =>
                      setState(() => _selectedTemplate = template),
                )),

            const SizedBox(height: 20),

            if (_selectedTemplate != null) ...[
              _PatternPreview(template: _selectedTemplate!),
              const SizedBox(height: 20),
            ],

            Text(
              'Schedule settings',
              style: GoogleFonts.sora(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Start date
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 7)),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 30)),
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
                        setState(() => _startDate = picked);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pattern starts',
                                style: GoogleFonts.nunito(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                              Text(
                                DateFormat('EEEE, MMMM d')
                                    .format(_startDate),
                                style: GoogleFonts.sora(
                                    color: AppColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textSecondary, size: 16),
                      ],
                    ),
                  ),
                  const Divider(height: 20),

                  // Weeks ahead
                  Row(
                    children: [
                      const Icon(Icons.date_range_outlined,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Generate $_weeksAhead weeks ahead',
                          style: GoogleFonts.sora(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _weeksAhead.toDouble(),
                          min: 1,
                          max: 12,
                          divisions: 11,
                          onChanged: (v) =>
                              setState(() => _weeksAhead = v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${_weeksAhead}w',
                          style: GoogleFonts.jetBrainsMono(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedTemplate != null
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                ),
                icon: patternState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  patternState.isLoading
                      ? 'Generating shifts...'
                      : 'Generate my schedule',
                  style: GoogleFonts.nunito(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed:
                    _selectedTemplate == null || patternState.isLoading
                        ? null
                        : _apply,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.clear_all,
                    color: AppColors.textSecondary, size: 16),
                label: Text(
                  'Clear generated shifts',
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                onPressed: _clearShifts,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _apply() async {
    if (_selectedTemplate == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Apply pattern?',
            style: GoogleFonts.sora(color: AppColors.text)),
        content: Text(
          'This will add ${_selectedTemplate!.name} shifts to your schedule for $_weeksAhead weeks starting ${DateFormat('MMM d').format(_startDate)}.\n\nExisting shifts in that range will be overwritten.',
          style: GoogleFonts.nunito(
              color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Apply',
                style: GoogleFonts.nunito(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref
        .read(recurringShiftPatternProvider.notifier)
        .applyPattern(
          template: _selectedTemplate!,
          startDate: _startDate,
          weeksAhead: _weeksAhead,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_weeksAhead * 7} days of ${_selectedTemplate!.name} added ✓',
            style: GoogleFonts.nunito(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _clearShifts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Clear upcoming shifts?',
            style: GoogleFonts.sora(color: AppColors.text)),
        content: Text(
          'Remove all shifts from today for $_weeksAhead weeks? This cannot be undone.',
          style: GoogleFonts.nunito(
              color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear',
                style:
                    GoogleFonts.nunito(color: AppColors.warning)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(recurringShiftPatternProvider.notifier)
          .clearPatternShifts(
            from: DateTime.now(),
            days: _weeksAhead * 7,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shifts cleared',
                style: GoogleFonts.nunito(color: Colors.white)),
            backgroundColor: AppColors.surfaceVariant,
          ),
        );
      }
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final ShiftPatternTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(template.icon,
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: GoogleFonts.sora(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    template.description,
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PatternPreview extends StatelessWidget {
  final ShiftPatternTemplate template;
  const _PatternPreview({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${template.cycleLengthDays}-day cycle preview',
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(template.rotation.length, (i) {
                final day = template.rotation[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    children: [
                      Text(
                        'D${i + 1}',
                        style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      ShiftChip(
                          shiftType: day.shiftType, compact: true),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
