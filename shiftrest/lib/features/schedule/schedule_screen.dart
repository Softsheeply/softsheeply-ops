import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../core/sleep_planner_service.dart';
import '../../shared/widgets/shift_chip.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  late final ScrollController _calendarScroll;

  @override
  void initState() {
    super.initState();
    _calendarScroll = ScrollController(
      initialScrollOffset: _todayOffset(),
    );
  }

  @override
  void dispose() {
    _calendarScroll.dispose();
    super.dispose();
  }

  double _todayOffset() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final diff = now.difference(startOfWeek).inDays;
    return (diff * 68.0) - 100;
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(shiftsProvider);
    final now = DateTime.now();

    final weekDays = List.generate(
      28,
      (i) => now.subtract(Duration(days: 7)).add(Duration(days: i)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.today, size: 16),
            label: Text('Today',
                style: GoogleFonts.nunito(fontSize: 13)),
            onPressed: () {
              setState(() => _selectedDate = now);
              _calendarScroll.animateTo(
                _todayOffset(),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddShiftSheet(context, _selectedDate),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Calendar strip
          Container(
            height: 90,
            color: AppColors.surface,
            child: shiftsAsync.when(
              data: (shifts) => ListView.builder(
                controller: _calendarScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                itemCount: weekDays.length,
                itemBuilder: (context, i) {
                  final day = weekDays[i];
                  final dateStr = DateFormat('yyyy-MM-dd').format(day);
                  final isToday = _isSameDay(day, now);
                  final isSelected = _isSameDay(day, _selectedDate);
                  final shift = shifts.cast<ShiftModel?>().firstWhere(
                        (s) => s?.date == dateStr,
                        orElse: () => null,
                      );
                  final shiftColor = shift != null
                      ? AppColors.shiftColor(shift.shiftType)
                      : Colors.transparent;

                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedDate = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : isToday
                                  ? AppColors.primary.withOpacity(0.4)
                                  : Colors.transparent,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E').format(day).substring(0, 2),
                            style: GoogleFonts.nunito(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            day.day.toString(),
                            style: GoogleFonts.sora(
                              color: isToday
                                  ? AppColors.accent
                                  : isSelected
                                      ? AppColors.primary
                                      : AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: shiftColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(
                  child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              )),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Selected day detail
          Expanded(
            child: shiftsAsync.when(
              data: (shifts) {
                final selectedStr =
                    DateFormat('yyyy-MM-dd').format(_selectedDate);
                final shift = shifts.cast<ShiftModel?>().firstWhere(
                      (s) => s?.date == selectedStr,
                      orElse: () => null,
                    );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SelectedDayHeader(
                          date: _selectedDate,
                          shift: shift,
                          onAdd: () => _showAddShiftSheet(
                              context, _selectedDate),
                          onEdit: shift != null
                              ? () => _showAddShiftSheet(
                                  context, _selectedDate,
                                  existing: shift)
                              : null,
                          onDelete: shift != null
                              ? () => _deleteShift(shift)
                              : null),
                      const SizedBox(height: 20),
                      Text(
                        'This week',
                        style: GoogleFonts.sora(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(7, (i) {
                        final weekDay = DateTime.now()
                            .subtract(const Duration(days: 1))
                            .add(Duration(days: i));
                        final dateStr =
                            DateFormat('yyyy-MM-dd').format(weekDay);
                        final weekShift = shifts
                            .cast<ShiftModel?>()
                            .firstWhere(
                              (s) => s?.date == dateStr,
                              orElse: () => null,
                            );
                        return _WeekShiftRow(
                          date: weekDay,
                          shift: weekShift,
                          onTap: () {
                            setState(() => _selectedDate = weekDay);
                            if (weekShift != null) {
                              _showAddShiftSheet(context, weekDay,
                                  existing: weekShift);
                            } else {
                              _showAddShiftSheet(context, weekDay);
                            }
                          },
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(
                color: AppColors.primary,
              )),
              error: (_, __) =>
                  const Center(child: Text('Error loading shifts')),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showAddShiftSheet(BuildContext context, DateTime date,
      {ShiftModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddShiftSheet(
        date: date,
        existing: existing,
        onSaved: () {
          ref.read(shiftsProvider.notifier).loadUpcoming();
          ref.read(sleepPlansProvider.notifier).generate();
        },
      ),
    );
  }

  void _deleteShift(ShiftModel shift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete shift?',
            style: GoogleFonts.sora(color: AppColors.text)),
        content: Text(
          'Remove ${AppConstants.shiftTypeLabels[shift.shiftType]} on ${DateFormat('MMM d').format(DateTime.parse(shift.date))}?',
          style: GoogleFonts.nunito(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.nunito(color: AppColors.warning)),
          ),
        ],
      ),
    );
    if (confirmed == true && shift.id != null) {
      await ref.read(shiftsProvider.notifier).delete(shift.id!);
      ref.read(sleepPlansProvider.notifier).generate();
    }
  }
}

class _SelectedDayHeader extends StatelessWidget {
  final DateTime date;
  final ShiftModel? shift;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SelectedDayHeader({
    required this.date,
    required this.shift,
    required this.onAdd,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(date),
            style: GoogleFonts.sora(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (shift == null) ...[
            Text(
              'No shift scheduled',
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add shift'),
              onPressed: onAdd,
            ),
          ] else ...[
            Row(
              children: [
                ShiftChip(shiftType: shift!.shiftType),
                const Spacer(),
                if (onEdit != null)
                  TextButton(onPressed: onEdit, child: const Text('Edit')),
                if (onDelete != null)
                  TextButton(
                    onPressed: onDelete,
                    child: Text('Delete',
                        style: GoogleFonts.nunito(
                            color: AppColors.warning)),
                  ),
              ],
            ),
            if (shift!.startTime != null) ...[
              const SizedBox(height: 6),
              Text(
                '${shift!.startTime} – ${shift!.endTime ?? "?"}',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
            if (shift!.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                shift!.notes!,
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WeekShiftRow extends StatelessWidget {
  final DateTime date;
  final ShiftModel? shift;
  final VoidCallback onTap;

  const _WeekShiftRow({
    required this.date,
    required this.shift,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, DateTime.now());
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday
                ? AppColors.primary.withOpacity(0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(date).substring(0, 2),
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    date.day.toString(),
                    style: GoogleFonts.sora(
                      color: isToday
                          ? AppColors.accent
                          : AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: shift == null
                  ? Text(
                      'No shift — tap to add',
                      style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 13),
                    )
                  : Row(
                      children: [
                        ShiftChip(
                            shiftType: shift!.shiftType,
                            compact: true),
                        if (shift!.startTime != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${shift!.startTime}–${shift!.endTime ?? "?"}',
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ---- Add Shift Sheet ----

class AddShiftSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final ShiftModel? existing;
  final VoidCallback? onSaved;

  const AddShiftSheet({
    super.key,
    required this.date,
    this.existing,
    this.onSaved,
  });

  @override
  ConsumerState<AddShiftSheet> createState() => _AddShiftSheetState();
}

class _AddShiftSheetState extends ConsumerState<AddShiftSheet> {
  String _shiftType = 'day';
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 15, minute: 0);
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _shiftType = e.shiftType;
      if (e.startTime != null) {
        final parts = e.startTime!.split(':');
        _startTime = TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (e.endTime != null) {
        final parts = e.endTime!.split(':');
        _endTime = TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      _notesController.text = e.notes ?? '';
    } else {
      _setDefaultTimes('day');
    }
  }

  void _setDefaultTimes(String type) {
    switch (type) {
      case 'day':
        _startTime = const TimeOfDay(hour: 7, minute: 0);
        _endTime = const TimeOfDay(hour: 15, minute: 0);
        break;
      case 'afternoon':
        _startTime = const TimeOfDay(hour: 14, minute: 0);
        _endTime = const TimeOfDay(hour: 22, minute: 0);
        break;
      case 'night':
        _startTime = const TimeOfDay(hour: 23, minute: 0);
        _endTime = const TimeOfDay(hour: 7, minute: 0);
        break;
      case 'rotating':
        _startTime = const TimeOfDay(hour: 6, minute: 0);
        _endTime = const TimeOfDay(hour: 18, minute: 0);
        break;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
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
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final shift = ShiftModel(
        id: widget.existing?.id,
        date: DateFormat('yyyy-MM-dd').format(widget.date),
        shiftType: _shiftType,
        startTime: _shiftType == 'off' ? null : _formatTime(_startTime),
        endTime: _shiftType == 'off' ? null : _formatTime(_endTime),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      await ref.read(shiftsProvider.notifier).addOrUpdate(shift);
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.existing == null
                ? 'Add Shift — ${DateFormat('EEE, MMM d').format(widget.date)}'
                : 'Edit Shift — ${DateFormat('EEE, MMM d').format(widget.date)}',
            style: GoogleFonts.sora(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text('Shift type',
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.shiftTypeLabels.keys.map((type) {
              return GestureDetector(
                onTap: () => setState(() {
                  _shiftType = type;
                  if (type != 'off') _setDefaultTimes(type);
                }),
                child: ShiftChip(
                    shiftType: type,
                    selected: _shiftType == type),
              );
            }).toList(),
          ),
          if (_shiftType != 'off') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start time',
                          style: GoogleFonts.nunito(
                              color: AppColors.textSecondary,
                              fontSize: 13)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _pickTime(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatTime(_startTime),
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End time',
                          style: GoogleFonts.nunito(
                              color: AppColors.textSecondary,
                              fontSize: 13)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _pickTime(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatTime(_endTime),
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _notesController,
            style: GoogleFonts.nunito(color: AppColors.text, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Notes (optional)',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.existing == null ? 'Save Shift' : 'Update Shift',
                      style: GoogleFonts.nunito(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
