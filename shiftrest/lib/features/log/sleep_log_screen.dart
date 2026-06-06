import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../shared/widgets/quality_stars.dart';

class SleepLogScreen extends ConsumerStatefulWidget {
  const SleepLogScreen({super.key});

  @override
  ConsumerState<SleepLogScreen> createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends ConsumerState<SleepLogScreen>
    with SingleTickerProviderStateMixin {
  DateTime _sleepDate = DateTime.now();
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 0);
  bool _isSplitSleep = false;
  TimeOfDay _splitSleepTime2 = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _splitWakeTime2 = const TimeOfDay(hour: 16, minute: 0);
  int _quality = 3;
  final _notesController = TextEditingController();
  bool _saving = false;

  late final AnimationController _successController;
  late final Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (now.hour < 12) {
      _sleepDate = now.subtract(const Duration(days: 1));
    }

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successAnim = CurvedAnimation(
        parent: _successController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isSleep, {bool isSecond = false}) async {
    TimeOfDay initial;
    if (isSleep) {
      initial = isSecond ? _splitSleepTime2 : _sleepTime;
    } else {
      initial = isSecond ? _splitWakeTime2 : _wakeTime;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
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
        if (isSleep) {
          if (isSecond) {
            _splitSleepTime2 = picked;
          } else {
            _sleepTime = picked;
          }
        } else {
          if (isSecond) {
            _splitWakeTime2 = picked;
          } else {
            _wakeTime = picked;
          }
        }
      });
    }
  }

  DateTime _buildDateTime(DateTime date, TimeOfDay time,
      {bool nextDayIfEarlierThanSleep = false}) {
    var dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (nextDayIfEarlierThanSleep) {
      final sleepDt = DateTime(
          date.year, date.month, date.day, _sleepTime.hour, _sleepTime.minute);
      if (dt.isBefore(sleepDt)) {
        dt = dt.add(const Duration(days: 1));
      }
    }
    return dt;
  }

  double _computeDuration() {
    final start =
        _buildDateTime(_sleepDate, _sleepTime);
    final end =
        _buildDateTime(_sleepDate, _wakeTime, nextDayIfEarlierThanSleep: true);
    var diff = end.difference(start).inMinutes;
    if (diff < 0) diff += 24 * 60;

    if (_isSplitSleep) {
      final start2 = _buildDateTime(_sleepDate, _splitSleepTime2);
      final end2 = _buildDateTime(_sleepDate, _splitWakeTime2,
          nextDayIfEarlierThanSleep: false);
      var diff2 = end2.difference(start2).inMinutes;
      if (diff2 < 0) diff2 += 24 * 60;
      diff += diff2;
    }

    return diff / 60.0;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final start = _buildDateTime(_sleepDate, _sleepTime);
      final end = _buildDateTime(_sleepDate, _wakeTime,
          nextDayIfEarlierThanSleep: true);

      final log = {
        'date': DateFormat('yyyy-MM-dd').format(_sleepDate),
        'sleep_start': start.toIso8601String(),
        'sleep_end': end.toIso8601String(),
        'quality': _quality,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'is_split_sleep': _isSplitSleep ? 1 : 0,
        if (_isSplitSleep) ...{
          'split_sleep_start2': _buildDateTime(
                  _sleepDate, _splitSleepTime2)
              .toIso8601String(),
          'split_sleep_end2': _buildDateTime(
                  _sleepDate, _splitWakeTime2)
              .toIso8601String(),
        },
      };

      await ref.read(sleepLogsProvider.notifier).add(log);

      // Prompt for review on every 5th log entry
      final allLogs = ref.read(sleepLogsProvider).asData?.value ?? [];
      if (allLogs.length >= 5 && allLogs.length % 5 == 0) {
        final inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
        }
      }

      await _successController.forward();
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sleep logged — ${_computeDuration().toStringAsFixed(1)} hours',
              style: GoogleFonts.nunito(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = _computeDuration();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Log Sleep')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            _SectionHeader('Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _sleepDate,
                  firstDate: DateTime.now().subtract(
                      const Duration(days: 30)),
                  lastDate: DateTime.now(),
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
                if (picked != null) setState(() => _sleepDate = picked);
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
                    const Icon(Icons.calendar_today,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMMM d').format(_sleepDate),
                      style: GoogleFonts.nunito(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Main sleep window
            _SectionHeader('Sleep window'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Fell asleep',
                    time: _sleepTime,
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePicker(
                    label: 'Woke up',
                    time: _wakeTime,
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Split sleep toggle
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('✂️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Was this split sleep?',
                      style: GoogleFonts.nunito(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: _isSplitSleep,
                    onChanged: (v) => setState(() => _isSplitSleep = v),
                  ),
                ],
              ),
            ),

            if (_isSplitSleep) ...[
              const SizedBox(height: 10),
              _SectionHeader('Second sleep window'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimePicker(
                      label: 'Fell asleep',
                      time: _splitSleepTime2,
                      onTap: () => _pickTime(true, isSecond: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePicker(
                      label: 'Woke up',
                      time: _splitWakeTime2,
                      onTap: () => _pickTime(false, isSecond: true),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Duration summary
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('⏱',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    'Total sleep: ',
                    style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 14),
                  ),
                  Text(
                    '${duration.toStringAsFixed(1)} hours',
                    style: GoogleFonts.jetBrainsMono(
                      color: duration >= 6
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quality
            _SectionHeader('How\'d you sleep?'),
            const SizedBox(height: 12),
            Center(
              child: QualityStars(
                quality: _quality,
                interactive: true,
                onChanged: (q) => setState(() => _quality = q),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            // Notes
            _SectionHeader('Notes (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              style: GoogleFonts.nunito(
                  color: AppColors.text, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Anything unusual? Stress, noise, temperature...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            // Save
            AnimatedBuilder(
              animation: _successAnim,
              builder: (context, child) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.lerp(
                      AppColors.primary,
                      AppColors.success,
                      _successAnim.value,
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                      : Text(
                          _successAnim.value > 0.5 ? 'Saved! ✓' : 'Save Sleep Log',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sora(
        color: AppColors.text,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
  });

  String _formatTime(TimeOfDay t) {
    final hour = t.hour;
    final minute = t.minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatTime(time),
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.access_time,
                    color: AppColors.textSecondary, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
