import 'dart:math';

enum AlertnessLevel { critical, low, moderate, good, optimal }

class AlertnessPrediction {
  final double score; // 0–100
  final AlertnessLevel level;
  final String headline;
  final String detail;
  final List<String> tips;
  final double sleepDebtHours;
  final double hoursAwake;
  final double circadianBoost;

  const AlertnessPrediction({
    required this.score,
    required this.level,
    required this.headline,
    required this.detail,
    required this.tips,
    required this.sleepDebtHours,
    required this.hoursAwake,
    required this.circadianBoost,
  });
}

class AlertnessService {
  // Two-Process model of sleep regulation (simplified Borbély/Daan model)
  // Process S: homeostatic sleep pressure (rises while awake, falls during sleep)
  // Process C: circadian oscillation (24hr sinusoidal rhythm)
  // Alertness = Process C component minus sleep debt adjustment

  static AlertnessPrediction predict({
    required DateTime now,
    required DateTime? lastWakeTime,
    required List<Map<String, dynamic>> recentLogs,
    required double sleepGoalHours,
    DateTime? shiftStartTime,
  }) {
    // --- Process S: sleep debt ---
    final debt = _computeSleepDebt(recentLogs, sleepGoalHours);

    // --- Hours awake since last sleep ---
    double hoursAwake = 16.0; // default if no data
    if (lastWakeTime != null) {
      hoursAwake = now.difference(lastWakeTime).inMinutes / 60.0;
      hoursAwake = hoursAwake.clamp(0, 36);
    }

    // --- Process C: circadian factor ---
    final circadian = _circadianFactor(now);

    // --- Combine ---
    // Base alertness from circadian (0–40 points)
    final circadianPoints = ((circadian + 1) / 2.0) * 40;

    // Sleep debt penalty (0–30 points deducted)
    final debtPenalty = (debt.clamp(0, 10) / 10.0) * 30;

    // Hours awake penalty — beyond 16hrs it degrades rapidly
    final awakePenalty = hoursAwake > 16
        ? ((hoursAwake - 16).clamp(0, 8) / 8.0) * 25
        : (hoursAwake / 16.0) * 10;

    // Base pool
    final raw = (circadianPoints + 60 - debtPenalty - awakePenalty)
        .clamp(0.0, 100.0);

    final score = raw;
    final level = _level(score);

    // If evaluating for a future shift time, recalculate circadian for that time
    double shiftCircadian = circadian;
    if (shiftStartTime != null) {
      shiftCircadian = _circadianFactor(shiftStartTime);
    }

    return AlertnessPrediction(
      score: score,
      level: level,
      headline: _headline(level, shiftStartTime != null),
      detail: _detail(score, debt, hoursAwake, shiftStartTime),
      tips: _tips(level, debt, hoursAwake, shiftStartTime),
      sleepDebtHours: debt,
      hoursAwake: hoursAwake,
      circadianBoost: shiftCircadian,
    );
  }

  // Circadian factor: +1.0 = peak alertness, -1.0 = trough
  // Lowest: 3–5am. Secondary dip: 2–4pm. Peaks: 10am, 8pm.
  static double _circadianFactor(DateTime dt) {
    final hourDecimal = dt.hour + dt.minute / 60.0;
    // Primary rhythm (24hr): peak around 10am (phase offset -2hrs from noon)
    final primary = cos((hourDecimal - 10) * 2 * pi / 24);
    // Secondary harmonic (12hr): secondary dip at ~3pm
    final secondary = 0.3 * cos((hourDecimal - 10) * 2 * pi / 12);
    return (primary + secondary).clamp(-1.0, 1.0);
  }

  static double _computeSleepDebt(
    List<Map<String, dynamic>> logs,
    double goalHours,
  ) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    double actual = 0;
    int count = 0;

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
          count++;
        } catch (_) {}
      }
    }
    if (count == 0) return 0;
    return ((goalHours * count) - actual).clamp(0, 20);
  }

  static AlertnessLevel _level(double score) {
    if (score >= 75) return AlertnessLevel.optimal;
    if (score >= 60) return AlertnessLevel.good;
    if (score >= 45) return AlertnessLevel.moderate;
    if (score >= 30) return AlertnessLevel.low;
    return AlertnessLevel.critical;
  }

  static String _headline(AlertnessLevel level, bool forShift) {
    final prefix = forShift ? 'Predicted shift alertness' : 'Current alertness';
    switch (level) {
      case AlertnessLevel.optimal:
        return '$prefix: Optimal';
      case AlertnessLevel.good:
        return '$prefix: Good';
      case AlertnessLevel.moderate:
        return '$prefix: Moderate';
      case AlertnessLevel.low:
        return '$prefix: Low — take precautions';
      case AlertnessLevel.critical:
        return '$prefix: Critical — do not drive';
    }
  }

  static String _detail(
    double score,
    double debt,
    double hoursAwake,
    DateTime? shiftStart,
  ) {
    final scoreStr = score.round().toString();
    if (shiftStart != null) {
      final hoursUntil = shiftStart.difference(DateTime.now()).inMinutes / 60;
      if (hoursUntil > 0) {
        return 'Predicted $scoreStr/100 for your upcoming shift in ${hoursUntil.toStringAsFixed(1)}hrs. '
            '${debt > 2 ? "Sleep debt of ${debt.toStringAsFixed(1)}h is the main drag." : ""}';
      }
    }
    return '$scoreStr/100 right now. '
        '${hoursAwake > 14 ? "You\'ve been awake ${hoursAwake.toStringAsFixed(0)}hrs — fatigue is building." : ""}';
  }

  static List<String> _tips(
    AlertnessLevel level,
    double debt,
    double hoursAwake,
    DateTime? shiftStart,
  ) {
    final tips = <String>[];
    switch (level) {
      case AlertnessLevel.critical:
      case AlertnessLevel.low:
        if (hoursAwake > 16) {
          tips.add(
              'You\'ve been awake ${hoursAwake.toStringAsFixed(0)}hrs — equivalent to being legally drunk in some countries.');
        }
        if (debt > 3) {
          tips.add(
              'Sleep debt of ${debt.toStringAsFixed(1)}hrs is significantly impacting your alertness. Prioritise recovery sleep.');
        }
        tips.add('If driving: stop and rest. A 20-min nap restores function more than caffeine.');
        tips.add(
            'Alert your supervisor if you\'re feeling unsafe at work.');
        break;
      case AlertnessLevel.moderate:
        if (debt > 2) {
          tips.add(
              'A ${debt.toStringAsFixed(1)}hr sleep deficit is showing. Aim for your full goal tonight.');
        }
        tips.add(
            'A 20-minute nap before your shift (not closer than 3hrs) can add 1–3hrs of alertness.');
        tips.add('Bright light and movement help at the start of your shift.');
        break;
      case AlertnessLevel.good:
      case AlertnessLevel.optimal:
        tips.add('Your sleep patterns are working well. Stay consistent.');
        if (shiftStart != null) {
          tips.add(
              'Eat a light meal 2–3hrs before your shift — avoid heavy food right before.');
        }
        break;
    }
    return tips;
  }

  static String levelLabel(AlertnessLevel level) {
    switch (level) {
      case AlertnessLevel.optimal:
        return 'Optimal';
      case AlertnessLevel.good:
        return 'Good';
      case AlertnessLevel.moderate:
        return 'Moderate';
      case AlertnessLevel.low:
        return 'Low';
      case AlertnessLevel.critical:
        return 'Critical';
    }
  }

  static double levelHue(AlertnessLevel level) {
    switch (level) {
      case AlertnessLevel.optimal:
        return 0xFF69F0AE; // success green
      case AlertnessLevel.good:
        return 0xFF3D5AFE; // primary blue
      case AlertnessLevel.moderate:
        return 0xFFFFAB40; // amber
      case AlertnessLevel.low:
        return 0xFFFF6D00; // orange
      case AlertnessLevel.critical:
        return 0xFFE53935; // red
    }
  }
}
