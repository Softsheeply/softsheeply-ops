import 'package:home_widget/home_widget.dart';
import 'database.dart';
import 'sleep_planner_service.dart';
import 'constants.dart';

class WidgetService {
  static const String _appGroupId = 'com.softsheeply.shiftrest';
  static const String _widgetName = 'ShiftRestWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> update() async {
    try {
      final now = DateTime.now();
      final todayStr = _fmt(now);

      // Today's shift
      final todayShift = await AppDatabase.instance.getShiftForDate(todayStr);
      final shiftLabel = todayShift != null
          ? '${AppConstants.shiftEmojis[todayShift['shift_type']]} ${_shortShiftLabel(todayShift['shift_type'] as String)}'
          : 'No shift today';

      // Tonight's sleep plan
      final plans = await AppDatabase.instance.getSleepPlansForDate(todayStr);
      final mainPlan = plans.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p?['plan_type'] == 'main',
            orElse: () => null,
          );

      String sleepText = 'Open app for plan';
      if (mainPlan != null) {
        final start = DateTime.parse(mainPlan['window_start'] as String);
        final end = DateTime.parse(mainPlan['window_end'] as String);
        sleepText =
            '${SleepPlannerService.formatTimeFromDateTime(start)} → ${SleepPlannerService.formatTimeFromDateTime(end)}';
      }

      // Caffeine cutoff
      String caffeineText = '';
      if (mainPlan?['caffeine_deadline'] != null) {
        final dl =
            DateTime.parse(mainPlan!['caffeine_deadline'] as String);
        caffeineText =
            'Last coffee: ${SleepPlannerService.formatTimeFromDateTime(dl)}';
      }

      await HomeWidget.saveWidgetData<String>('shift_label', shiftLabel);
      await HomeWidget.saveWidgetData<String>('sleep_window', sleepText);
      await HomeWidget.saveWidgetData<String>('caffeine_cutoff', caffeineText);
      await HomeWidget.saveWidgetData<String>(
          'last_updated', _fmtTime(now));

      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
    } catch (_) {
      // Widget update is non-critical — swallow errors
    }
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$dh:$m $ampm';
  }

  static String _shortShiftLabel(String type) {
    switch (type) {
      case 'day':
        return 'Day shift';
      case 'afternoon':
        return 'Afternoon';
      case 'night':
        return 'Night shift';
      case 'rotating':
        return 'Rotating';
      case 'off':
        return 'Day off';
      default:
        return type;
    }
  }
}
