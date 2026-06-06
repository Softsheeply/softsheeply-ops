import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../core/notifications.dart';
import '../../core/database.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  String _jobType = 'other';
  double _sleepGoal = AppConstants.defaultSleepGoal;
  bool _bedtimeReminder = true;
  int _bedtimeMinutesBefore = 30;
  bool _wakeReminder = true;
  bool _shiftReminder = true;
  int _shiftHoursBefore = 2;
  bool _caffeineAlert = false;
  bool _darkMode = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final profile = await AppDatabase.instance.getProfile();
    final prefs = ref.read(sharedPreferencesProvider);

    if (mounted) {
      setState(() {
        _nameController.text = profile?['name'] as String? ?? '';
        _jobType = profile?['job_type'] as String? ?? 'other';
        _sleepGoal = (profile?['sleep_goal_hours'] as num?)?.toDouble() ??
            AppConstants.defaultSleepGoal;
        _bedtimeReminder = prefs.getBool('bedtime_reminder') ?? true;
        _bedtimeMinutesBefore =
            prefs.getInt('bedtime_minutes_before') ?? 30;
        _wakeReminder = prefs.getBool('wake_reminder') ?? true;
        _shiftReminder = prefs.getBool('shift_reminder') ?? true;
        _shiftHoursBefore = prefs.getInt('shift_hours_before') ?? 2;
        _caffeineAlert = prefs.getBool('caffeine_alert') ?? false;
        _darkMode = prefs.getBool('dark_mode') ?? true;
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).save({
        'name': _nameController.text.trim().isEmpty
            ? 'Shift Worker'
            : _nameController.text.trim(),
        'job_type': _jobType,
        'sleep_goal_hours': _sleepGoal,
      });

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('bedtime_reminder', _bedtimeReminder);
      await prefs.setInt('bedtime_minutes_before', _bedtimeMinutesBefore);
      await prefs.setBool('wake_reminder', _wakeReminder);
      await prefs.setBool('shift_reminder', _shiftReminder);
      await prefs.setInt('shift_hours_before', _shiftHoursBefore);
      await prefs.setBool('caffeine_alert', _caffeineAlert);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved',
                style: GoogleFonts.nunito(color: Colors.white)),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Clear all data?',
            style: GoogleFonts.sora(color: AppColors.text)),
        content: Text(
          'This will delete your profile, shifts, sleep logs, and plans. This cannot be undone.',
          style: GoogleFonts.nunito(
              color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Continue',
                style: GoogleFonts.nunito(color: AppColors.warning)),
          ),
        ],
      ),
    );

    if (confirmed1 != true || !mounted) return;

    final confirmed2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Are you sure?',
            style: GoogleFonts.sora(color: AppColors.text)),
        content: Text(
          'Final confirmation — all your data will be permanently deleted.',
          style: GoogleFonts.nunito(
              color: AppColors.warning, fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes, delete everything',
                style: GoogleFonts.nunito(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed2 != true || !mounted) return;

    await AppDatabase.instance.clearAllData();
    await NotificationService.instance.cancelAll();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.clear();

    ref.invalidate(profileProvider);
    ref.invalidate(shiftsProvider);
    ref.invalidate(sleepLogsProvider);
    ref.invalidate(sleepPlansProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All data cleared',
              style: GoogleFonts.nunito(color: Colors.white)),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child:
                CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : Text('Save',
                    style: GoogleFonts.nunito(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            _SectionTitle('Profile'),
            const SizedBox(height: 8),
            _SettingsCard(children: [
              TextField(
                controller: _nameController,
                style: GoogleFonts.nunito(
                    color: AppColors.text, fontSize: 15),
                decoration:
                    const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              Text(
                'Job type',
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.jobTypes.map((type) {
                  final selected = _jobType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _jobType = type),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                                .withOpacity(0.2)
                            : AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        AppConstants.jobTypeLabels[type]!,
                        style: GoogleFonts.nunito(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sleep goal',
                    style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 13),
                  ),
                  Text(
                    '${_sleepGoal.toStringAsFixed(1)} hrs',
                    style: GoogleFonts.jetBrainsMono(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Slider(
                value: _sleepGoal,
                min: AppConstants.minSleepGoal,
                max: AppConstants.maxSleepGoal,
                divisions: 6,
                onChanged: (v) => setState(() => _sleepGoal = v),
              ),
            ]),
            const SizedBox(height: 16),

            // Notifications section
            _SectionTitle('Notifications'),
            const SizedBox(height: 8),
            _SettingsCard(children: [
              _ToggleRow(
                label: 'Bedtime reminder',
                subtitle: 'Alert before your sleep window starts',
                value: _bedtimeReminder,
                onChanged: (v) =>
                    setState(() => _bedtimeReminder = v),
              ),
              if (_bedtimeReminder) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Text(
                        'How early?',
                        style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      ...[15, 30, 60].map((mins) {
                        final sel = _bedtimeMinutesBefore == mins;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _bedtimeMinutesBefore = mins),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                      .withOpacity(0.2)
                                  : AppColors.surfaceVariant,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : Colors.transparent),
                            ),
                            child: Text(
                              '${mins}m',
                              style: GoogleFonts.nunito(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const Divider(height: 24),
              _ToggleRow(
                label: 'Wake-up alarm',
                subtitle: 'Reminder when it\'s time to wake',
                value: _wakeReminder,
                onChanged: (v) =>
                    setState(() => _wakeReminder = v),
              ),
              const Divider(height: 24),
              _ToggleRow(
                label: 'Shift reminder',
                subtitle: 'Alert before your shift starts',
                value: _shiftReminder,
                onChanged: (v) =>
                    setState(() => _shiftReminder = v),
              ),
              if (_shiftReminder) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Text(
                        'How early?',
                        style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      ...[1, 2, 3].map((hrs) {
                        final sel = _shiftHoursBefore == hrs;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _shiftHoursBefore = hrs),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                      .withOpacity(0.2)
                                  : AppColors.surfaceVariant,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : Colors.transparent),
                            ),
                            child: Text(
                              '${hrs}h',
                              style: GoogleFonts.nunito(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const Divider(height: 24),
              _ToggleRow(
                label: 'Caffeine cutoff alert',
                subtitle: '30 min warning before caffeine deadline',
                value: _caffeineAlert,
                onChanged: (v) =>
                    setState(() => _caffeineAlert = v),
              ),
            ]),
            const SizedBox(height: 16),

            // App section
            _SectionTitle('App'),
            const SizedBox(height: 8),
            _SettingsCard(children: [
              _ToggleRow(
                label: 'Dark mode',
                subtitle: 'Recommended for shift workers',
                value: _darkMode,
                onChanged: (v) {
                  setState(() => _darkMode = v);
                  ref.read(themeProvider.notifier).toggle();
                },
              ),
            ]),
            const SizedBox(height: 16),

            // Danger zone
            _SectionTitle('Data'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _clearAllData,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever_outlined,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clear all data',
                            style: GoogleFonts.sora(
                                color: AppColors.warning,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Deletes profile, shifts, and sleep logs',
                            style: GoogleFonts.nunito(
                                color: AppColors.textSecondary,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.warning, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Version
            Center(
              child: Text(
                'ShiftRest v${AppConstants.appVersion}',
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Built for the people who work while the world sleeps.',
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.nunito(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 11),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
