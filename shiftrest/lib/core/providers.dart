import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';
import 'sleep_planner_service.dart';
import 'widget_service.dart';
import '../core/constants.dart';

// ---- Shared Preferences ----
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// ---- Profile ----
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<Map<String, dynamic>?>>(
  (ref) => ProfileNotifier(ref),
);

class ProfileNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  ProfileNotifier(Ref ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await AppDatabase.instance.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    await AppDatabase.instance.saveProfile(data);
    await _load();
  }

  Future<void> reload() => _load();
}

// ---- Onboarding ----
final onboardingCompletedProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
});

// ---- Shifts ----
final shiftsProvider =
    StateNotifierProvider<ShiftsNotifier, AsyncValue<List<ShiftModel>>>(
  (ref) => ShiftsNotifier(),
);

class ShiftsNotifier
    extends StateNotifier<AsyncValue<List<ShiftModel>>> {
  ShiftsNotifier() : super(const AsyncValue.loading()) {
    loadUpcoming();
  }

  Future<void> loadUpcoming({int days = 30}) async {
    try {
      final maps = await AppDatabase.instance.getUpcomingShifts(days);
      state = AsyncValue.data(maps.map(ShiftModel.fromMap).toList());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addOrUpdate(ShiftModel shift) async {
    if (shift.id != null) {
      await AppDatabase.instance.updateShift(shift.id!, shift.toMap());
    } else {
      await AppDatabase.instance.insertShift(shift.toMap());
    }
    await loadUpcoming();
    WidgetService.update();
  }

  Future<void> delete(int id) async {
    await AppDatabase.instance.deleteShift(id);
    await loadUpcoming();
    WidgetService.update();
  }
}

// ---- Sleep Plans ----
final sleepPlansProvider =
    StateNotifierProvider<SleepPlansNotifier, AsyncValue<List<SleepPlanModel>>>(
  (ref) => SleepPlansNotifier(ref),
);

class SleepPlansNotifier
    extends StateNotifier<AsyncValue<List<SleepPlanModel>>> {
  SleepPlansNotifier(Ref ref) : super(const AsyncValue.loading()) {
    generate();
  }

  bool splitEnabled = false;

  Future<void> generate({bool split = false}) async {
    splitEnabled = split;
    try {
      final profile = await AppDatabase.instance.getProfile();
      final sleepGoal =
          (profile?['sleep_goal_hours'] as num?)?.toDouble() ??
              AppConstants.defaultSleepGoal;

      final shiftMaps = await AppDatabase.instance.getUpcomingShifts(7);
      final shifts = shiftMaps.map(ShiftModel.fromMap).toList();

      final service = SleepPlannerService(
        currentDateTime: DateTime.now(),
        sleepGoalHours: sleepGoal,
        splitSleepEnabled: split,
      );

      List<SleepPlanModel> plans;
      if (shifts.isEmpty) {
        plans = SleepPlannerService.demoPlans();
      } else {
        plans = service.generatePlans(shifts);
      }

      // Persist plans
      for (final plan in plans) {
        await AppDatabase.instance.upsertSleepPlan(plan.toMap());
      }

      state = AsyncValue.data(plans);
      WidgetService.update();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

// ---- Sleep Logs ----
final sleepLogsProvider =
    StateNotifierProvider<SleepLogsNotifier, AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => SleepLogsNotifier(),
);

class SleepLogsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  SleepLogsNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final logs = await AppDatabase.instance.getRecentSleepLogs(60);
      state = AsyncValue.data(logs);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> add(Map<String, dynamic> log) async {
    await AppDatabase.instance.insertSleepLog(log);
    await load();
  }

  Future<void> update(int id, Map<String, dynamic> log) async {
    await AppDatabase.instance.updateSleepLog(id, log);
    await load();
  }

  Future<void> delete(int id) async {
    await AppDatabase.instance.deleteSleepLog(id);
    await load();
  }
}

// ---- Settings ----
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>(
  (ref) => ThemeNotifier(ref),
);

class ThemeNotifier extends StateNotifier<bool> {
  final Ref _ref;
  ThemeNotifier(this._ref)
      : super(
          _ref.read(sharedPreferencesProvider).getBool('dark_mode') ?? true,
        );

  Future<void> toggle() async {
    state = !state;
    await _ref
        .read(sharedPreferencesProvider)
        .setBool('dark_mode', state);
  }
}
