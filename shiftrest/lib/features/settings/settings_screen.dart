import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../core/notifications.dart';
import '../../core/database.dart';
import '../../core/health_connect_service.dart';

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
  bool _importingHealth = false;

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

  Future<void> _importFromHealthConnect() async {
    setState(() => _importingHealth = true);
    try {
      final service = HealthConnectService.instance;
      final availability = await service.checkAvailability();

      if (availability == HealthConnectAvailability.unavailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Health Connect not available on this device',
                  style: GoogleFonts.nunito(color: Colors.white)),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      if (availability == HealthConnectAvailability.notInstalled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Health Connect is not installed',
                  style: GoogleFonts.nunito(color: Colors.white)),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      final granted = await service.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permission denied — enable sleep access in Health Connect',
                  style: GoogleFonts.nunito(color: Colors.white)),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      final entries = await service.fetchSleepData(days: 30);
      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No sleep data found in Health Connect (last 30 days)',
                  style: GoogleFonts.nunito(color: Colors.white)),
              backgroundColor: AppColors.textSecondary,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _HealthImportSheet(entries: entries),
      );

      ref.invalidate(sleepLogsProvider);
    } finally {
      if (mounted) setState(() => _importingHealth = false);
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
            const SizedBox(height: 16),

            // Health Connect
            _SectionTitle('Health Connect'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _importingHealth ? null : _importFromHealthConnect,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('🩺', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import sleep from Health Connect',
                            style: GoogleFonts.sora(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Import last 30 days from wearable devices',
                            style: GoogleFonts.nunito(
                                color: AppColors.textSecondary,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _importingHealth
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.chevron_right,
                            color: AppColors.primary, size: 18),
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

// ---- Health Connect import bottom sheet ----

class _HealthImportSheet extends StatefulWidget {
  final List<SleepImportEntry> entries;
  const _HealthImportSheet({required this.entries});

  @override
  State<_HealthImportSheet> createState() => _HealthImportSheetState();
}

class _HealthImportSheetState extends State<_HealthImportSheet> {
  late final List<bool> _selected;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.entries.length, true);
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final toImport = <SleepImportEntry>[];
      for (int i = 0; i < widget.entries.length; i++) {
        if (_selected[i]) toImport.add(widget.entries[i]);
      }
      final count = await HealthConnectService.instance.importEntries(toImport);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $count sleep entries',
                style: GoogleFonts.nunito(color: Colors.white)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _fmt(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$dh:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.where((s) => s).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sleep data from Health Connect',
                style: GoogleFonts.sora(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            '${widget.entries.length} entries found. Select which to import:',
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.entries.length,
              itemBuilder: (ctx, i) {
                final entry = widget.entries[i];
                return CheckboxListTile(
                  dense: true,
                  value: _selected[i],
                  onChanged: (v) => setState(() => _selected[i] = v ?? false),
                  activeColor: AppColors.primary,
                  title: Text(
                    entry.date,
                    style: GoogleFonts.sora(
                        color: AppColors.text, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${_fmt(entry.sleepStart)} → ${_fmt(entry.sleepEnd)}  '
                    '(${entry.durationHours.toStringAsFixed(1)}h)  · ${entry.source}',
                    style: GoogleFonts.nunito(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_importing || selectedCount == 0) ? null : _import,
              child: _importing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Import $selectedCount entr${selectedCount == 1 ? "y" : "ies"}',
                      style: GoogleFonts.nunito(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
