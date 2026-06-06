class ShiftModel {
  final int? id;
  final String date;
  final String shiftType;
  final String? startTime;
  final String? endTime;
  final String? notes;

  const ShiftModel({
    this.id,
    required this.date,
    required this.shiftType,
    this.startTime,
    this.endTime,
    this.notes,
  });

  factory ShiftModel.fromMap(Map<String, dynamic> map) {
    return ShiftModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      shiftType: map['shift_type'] as String,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'shift_type': shiftType,
      'start_time': startTime,
      'end_time': endTime,
      'notes': notes,
    };
  }
}

class SleepPlanModel {
  final String forDate;
  final DateTime windowStart;
  final DateTime windowEnd;
  final double durationHours;
  final String planType;
  final bool isCompleted;
  final DateTime? caffeineDeadline;
  final String lightGuidance;
  final String notes;

  const SleepPlanModel({
    required this.forDate,
    required this.windowStart,
    required this.windowEnd,
    required this.durationHours,
    required this.planType,
    this.isCompleted = false,
    this.caffeineDeadline,
    required this.lightGuidance,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'for_date': forDate,
      'window_start': windowStart.toIso8601String(),
      'window_end': windowEnd.toIso8601String(),
      'duration_hours': durationHours,
      'plan_type': planType,
      'is_completed': isCompleted ? 1 : 0,
      'caffeine_deadline': caffeineDeadline?.toIso8601String(),
      'light_guidance': lightGuidance,
      'notes': notes,
    };
  }

  factory SleepPlanModel.fromMap(Map<String, dynamic> map) {
    return SleepPlanModel(
      forDate: map['for_date'] as String,
      windowStart: DateTime.parse(map['window_start'] as String),
      windowEnd: DateTime.parse(map['window_end'] as String),
      durationHours: (map['duration_hours'] as num).toDouble(),
      planType: map['plan_type'] as String,
      isCompleted: (map['is_completed'] as int?) == 1,
      caffeineDeadline: map['caffeine_deadline'] != null
          ? DateTime.parse(map['caffeine_deadline'] as String)
          : null,
      lightGuidance: (map['light_guidance'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
    );
  }
}

class SleepPlannerService {
  final DateTime currentDateTime;
  final double sleepGoalHours;
  final bool splitSleepEnabled;
  final String caffeineProfile;

  SleepPlannerService({
    required this.currentDateTime,
    required this.sleepGoalHours,
    this.splitSleepEnabled = false,
    this.caffeineProfile = 'normal',
  });

  int get _caffeineHours {
    switch (caffeineProfile) {
      case 'sensitive':
        return 7;
      case 'very_sensitive':
        return 8;
      default:
        return 6;
    }
  }

  List<SleepPlanModel> generatePlans(List<ShiftModel> upcomingShifts) {
    final plans = <SleepPlanModel>[];

    for (int i = 0; i < 3; i++) {
      final targetDate = currentDateTime.add(Duration(days: i));
      final dateStr = _formatDate(targetDate);

      final todayShift = _shiftForDate(upcomingShifts, dateStr);
      final tomorrowDate = _formatDate(targetDate.add(const Duration(days: 1)));
      final tomorrowShift = _shiftForDate(upcomingShifts, tomorrowDate);

      final dayPlans = _planForDay(
        targetDate,
        dateStr,
        todayShift,
        tomorrowShift,
        upcomingShifts,
      );
      plans.addAll(dayPlans);
    }

    return plans;
  }

  List<SleepPlanModel> _planForDay(
    DateTime date,
    String dateStr,
    ShiftModel? todayShift,
    ShiftModel? tomorrowShift,
    List<ShiftModel> allShifts,
  ) {
    // Determine scenario
    if (todayShift?.shiftType == 'night') {
      return _nightShiftDay(date, dateStr, todayShift!);
    }

    if (tomorrowShift?.shiftType == 'night') {
      return _prepForNightShift(date, dateStr, tomorrowShift!);
    }

    if (todayShift?.shiftType == 'off' || todayShift == null) {
      final prevShift = _previousShift(allShifts, date);
      if (prevShift?.shiftType == 'night') {
        return _nightShiftRecovery(date, dateStr, prevShift!);
      }
      return _dayOffPlan(date, dateStr);
    }

    if (todayShift.shiftType == 'day') {
      return _dayShiftPlan(date, dateStr, todayShift);
    }

    if (todayShift.shiftType == 'afternoon') {
      return _afternoonShiftPlan(date, dateStr, todayShift);
    }

    if (todayShift.shiftType == 'rotating') {
      return _rotatingShiftPlan(date, dateStr, todayShift);
    }

    return _standardPlan(date, dateStr);
  }

  List<SleepPlanModel> _prepForNightShift(
    DateTime date,
    String dateStr,
    ShiftModel nightShift,
  ) {
    final shiftStart = _parseShiftTime(date.add(const Duration(days: 1)),
        nightShift.startTime ?? '23:00');

    // Sleep during the day, end 6-8hrs before shift
    final sleepEnd = shiftStart.subtract(const Duration(hours: 7));
    final sleepStart = sleepEnd.subtract(Duration(
      hours: sleepGoalHours.round(),
      minutes: ((sleepGoalHours % 1) * 60).round(),
    ));
    final caffeineDeadline =
        sleepStart.subtract(Duration(hours: _caffeineHours));

    final plans = <SleepPlanModel>[
      SleepPlanModel(
        forDate: dateStr,
        windowStart: sleepStart,
        windowEnd: sleepEnd,
        durationHours: sleepGoalHours,
        planType: 'main',
        caffeineDeadline: caffeineDeadline,
        lightGuidance:
            'Avoid bright light after ${_formatTime(sleepEnd.subtract(const Duration(hours: 2)))}. Use blackout curtains.',
        notes:
            'Night shift prep — sleep during the day so you\'re rested and sharp for your shift.',
      ),
    ];

    // Optional pre-shift nap (90min, ends 1hr before shift)
    final napEnd = shiftStart.subtract(const Duration(hours: 1));
    final napStart = napEnd.subtract(const Duration(minutes: 90));
    if (napStart.isAfter(sleepEnd.add(const Duration(hours: 2)))) {
      plans.add(SleepPlanModel(
        forDate: dateStr,
        windowStart: napStart,
        windowEnd: napEnd,
        durationHours: 1.5,
        planType: 'nap',
        lightGuidance: 'Keep lights dim during this nap window.',
        notes: 'Optional pre-shift power nap — helps maintain alertness.',
      ));
    }

    return plans;
  }

  List<SleepPlanModel> _nightShiftDay(
    DateTime date,
    String dateStr,
    ShiftModel shift,
  ) {
    final shiftEnd = _parseShiftTime(
        date, shift.endTime ?? '07:00',
        nextDayIfEarlier: false);
    final actualEnd = shiftEnd.hour < 12
        ? date
            .copyWith(hour: shiftEnd.hour, minute: shiftEnd.minute, second: 0)
        : date.copyWith(
            hour: shiftEnd.hour, minute: shiftEnd.minute, second: 0);

    final sleepStart = actualEnd.add(const Duration(minutes: 30));
    final sleepEnd = sleepStart.add(const Duration(hours: 7));
    final caffeineDeadline =
        sleepStart.subtract(Duration(hours: _caffeineHours));

    return [
      SleepPlanModel(
        forDate: dateStr,
        windowStart: sleepStart,
        windowEnd: sleepEnd,
        durationHours: 7.0,
        planType: 'recovery',
        caffeineDeadline: caffeineDeadline,
        lightGuidance:
            'Wear sunglasses on the way home. Use blackout curtains. Keep phone on silent.',
        notes:
            'Post-night recovery. Capped at 7hrs to avoid a full schedule flip — your body will adjust gradually.',
      ),
    ];
  }

  List<SleepPlanModel> _nightShiftRecovery(
    DateTime date,
    String dateStr,
    ShiftModel lastNightShift,
  ) {
    final daysSinceShift = date
            .difference(DateTime.parse(lastNightShift.date))
            .inDays;

    // Progressive anchor recovery
    final anchorHour = daysSinceShift == 1 ? 14 : daysSinceShift == 2 ? 11 : 23;
    final sleepStart = date.copyWith(hour: anchorHour, minute: 0, second: 0);
    final sleepEnd = sleepStart.add(Duration(
      hours: sleepGoalHours.round(),
      minutes: ((sleepGoalHours % 1) * 60).round(),
    ));
    final caffeineDeadline =
        sleepStart.subtract(Duration(hours: _caffeineHours));

    return [
      SleepPlanModel(
        forDate: dateStr,
        windowStart: sleepStart,
        windowEnd: sleepEnd,
        durationHours: sleepGoalHours,
        planType: 'recovery',
        caffeineDeadline: caffeineDeadline,
        lightGuidance: daysSinceShift <= 1
            ? 'Get bright light exposure mid-morning to signal daytime to your body.'
            : 'Normal light exposure today. You\'re almost back on track.',
        notes: _recoveryNote(daysSinceShift),
      ),
    ];
  }

  List<SleepPlanModel> _dayShiftPlan(
    DateTime date,
    String dateStr,
    ShiftModel shift,
  ) {
    final shiftStart = _parseShiftTime(date, shift.startTime ?? '07:00');
    final wakeTime = shiftStart.subtract(const Duration(hours: 1));
    final sleepEnd = wakeTime;
    final sleepStart = sleepEnd.subtract(Duration(
      hours: sleepGoalHours.round(),
      minutes: ((sleepGoalHours % 1) * 60).round(),
    ));
    final previousEvening = sleepStart.subtract(const Duration(days: 1));
    final caffeineDeadline =
        previousEvening.copyWith(hour: 14, minute: 0, second: 0);

    return [
      SleepPlanModel(
        forDate: dateStr,
        windowStart: sleepStart,
        windowEnd: sleepEnd,
        durationHours: sleepGoalHours,
        planType: 'main',
        caffeineDeadline: caffeineDeadline,
        lightGuidance:
            'Wind down 1hr before bed. Dim screens. Blackout curtains if needed.',
        notes:
            'Day shift — standard evening sleep. Set your alarm and go.',
      ),
    ];
  }

  List<SleepPlanModel> _afternoonShiftPlan(
    DateTime date,
    String dateStr,
    ShiftModel shift,
  ) {
    final shiftStart = _parseShiftTime(date, shift.startTime ?? '14:00');
    final shiftEnd = _parseShiftTime(date, shift.endTime ?? '22:00',
        nextDayIfEarlier: false);

    // Sleep after shift ends
    final sleepStart = shiftEnd.add(const Duration(hours: 1));
    final sleepEnd = sleepStart.add(Duration(
      hours: sleepGoalHours.round(),
      minutes: ((sleepGoalHours % 1) * 60).round(),
    ));
    final caffeineDeadline =
        shiftStart.subtract(Duration(hours: _caffeineHours));

    return [
      SleepPlanModel(
        forDate: dateStr,
        windowStart: sleepStart,
        windowEnd: sleepEnd,
        durationHours: sleepGoalHours,
        planType: 'main',
        caffeineDeadline: caffeineDeadline,
        lightGuidance:
            'Limit screen time after ${_formatTime(sleepEnd.subtract(const Duration(hours: 1)))}.',
        notes:
            'Afternoon shift — sleep after work. Avoid the temptation to stay up scrolling.',
      ),
    ];
  }

  List<SleepPlanModel> _rotatingShiftPlan(
    DateTime date,
    String dateStr,
    ShiftModel shift,
  ) {
    if (splitSleepEnabled) {
      final mainStart = date.copyWith(hour: 23, minute: 0, second: 0);
      final mainEnd = mainStart.add(const Duration(hours: 5));
      final napStart = date.copyWith(hour: 14, minute: 0, second: 0);
      final napEnd = napStart.add(const Duration(minutes: 90));
      final caffeineDeadline = date.copyWith(hour: 8, minute: 0, second: 0);

      return [
        SleepPlanModel(
          forDate: dateStr,
          windowStart: mainStart,
          windowEnd: mainEnd,
          durationHours: 5.0,
          planType: 'main',
          caffeineDeadline: caffeineDeadline,
          lightGuidance: 'Get outdoor light in the morning to anchor your rhythm.',
          notes: 'Rotating schedule — split sleep. 5hrs main + 90min nap.',
        ),
        SleepPlanModel(
          forDate: dateStr,
          windowStart: napStart,
          windowEnd: napEnd,
          durationHours: 1.5,
          planType: 'nap',
          lightGuidance: 'Use an eye mask for this nap.',
          notes: 'Adjustment week nap — keeps your total sleep close to goal.',
        ),
      ];
    }

    return _standardPlan(date, dateStr, extraNote: 'Rotating week — your body is adjusting. Be patient with fatigue.');
  }

  List<SleepPlanModel> _dayOffPlan(DateTime date, String dateStr) {
    final sleepStart = date.copyWith(hour: 23, minute: 0, second: 0);
    final sleepEnd = sleepStart.add(Duration(
      hours: sleepGoalHours.round(),
      minutes: ((sleepGoalHours % 1) * 60).round(),
    ));
    final caffeineDeadline =
        sleepStart.subtract(Duration(hours: _caffeineHours));

    return [
      SleepPlanModel(
        forDate: dateStr,
        windowStart: sleepStart,
        windowEnd: sleepEnd,
        durationHours: sleepGoalHours,
        planType: 'main',
        caffeineDeadline: caffeineDeadline,
        lightGuidance: 'Day off — ideal time for outdoor light exposure in the morning.',
        notes:
            'Recovery anchor — staying within 2hrs of your regular sleep time prevents a bigger schedule drift on your next work week.',
      ),
    ];
  }

  List<SleepPlanModel> _standardPlan(
    DateTime date,
    String dateStr, {
    String? extraNote,
  }) {
    final sleepStart = date.copyWith(hour: 22, minute: 30, second: 0);
    final sleepEnd = sleepStart.add(Duration(
      hours: sleepGoalHours.round(),
      minutes: ((sleepGoalHours % 1) * 60).round(),
    ));
    final caffeineDeadline =
        sleepStart.subtract(Duration(hours: _caffeineHours));

    return [
      SleepPlanModel(
        forDate: dateStr,
        windowStart: sleepStart,
        windowEnd: sleepEnd,
        durationHours: sleepGoalHours,
        planType: 'main',
        caffeineDeadline: caffeineDeadline,
        lightGuidance: 'Dim screens 1hr before bed.',
        notes: extraNote ?? 'Standard sleep window based on your goal.',
      ),
    ];
  }

  String _recoveryNote(int daysSince) {
    switch (daysSince) {
      case 1:
        return 'Day 1 recovery — sleep mid-afternoon. Your body is still in night-mode.';
      case 2:
        return 'Day 2 recovery — moving toward a normal anchor. About 1 day to adjust per hour of shift.';
      default:
        return 'Day 3 recovery — back to normal anchor time tonight. You should feel more like yourself.';
    }
  }

  ShiftModel? _shiftForDate(List<ShiftModel> shifts, String date) {
    try {
      return shifts.firstWhere((s) => s.date == date);
    } catch (_) {
      return null;
    }
  }

  ShiftModel? _previousShift(List<ShiftModel> shifts, DateTime date) {
    final sorted = shifts
        .where((s) => DateTime.parse(s.date).isBefore(date))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.isNotEmpty ? sorted.first : null;
  }

  DateTime _parseShiftTime(DateTime baseDate, String timeStr,
      {bool nextDayIfEarlier = true}) {
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    var dt = baseDate.copyWith(hour: hour, minute: minute, second: 0);
    return dt;
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  static String formatTimeFromDateTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  static double computeDuration(DateTime start, DateTime end) {
    var diff = end.difference(start);
    if (diff.isNegative) diff = diff + const Duration(hours: 24);
    return diff.inMinutes / 60.0;
  }

  static List<SleepPlanModel> demoPlans() {
    final now = DateTime.now();
    final today = now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);

    return [
      SleepPlanModel(
        forDate:
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
        windowStart: today.copyWith(hour: 8),
        windowEnd: today.copyWith(hour: 16),
        durationHours: 8.0,
        planType: 'main',
        caffeineDeadline: today.copyWith(hour: 2),
        lightGuidance: 'Use blackout curtains. Night shift prep.',
        notes: 'Sample plan — add your shifts to get a personalized schedule.',
      ),
      SleepPlanModel(
        forDate:
            '${today.add(const Duration(days: 1)).year}-${today.add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${today.add(const Duration(days: 1)).day.toString().padLeft(2, '0')}',
        windowStart: today.add(const Duration(days: 1)).copyWith(hour: 7, minute: 30),
        windowEnd: today.add(const Duration(days: 1)).copyWith(hour: 15),
        durationHours: 7.5,
        planType: 'recovery',
        caffeineDeadline:
            today.add(const Duration(days: 1)).copyWith(hour: 1, minute: 30),
        lightGuidance: 'Blackout curtains. Eye mask helps.',
        notes: 'Post-night recovery sleep.',
      ),
    ];
  }
}
