class AppConstants {
  static const String appName = 'ShiftRest';
  static const String appVersion = '1.0.0';

  static const List<String> jobTypes = [
    'nurse',
    'warehouse',
    'driver',
    'factory',
    'other',
  ];

  static const Map<String, String> jobTypeLabels = {
    'nurse': 'Nurse / Healthcare',
    'warehouse': 'Warehouse / Logistics',
    'driver': 'Truck Driver',
    'factory': 'Factory / Manufacturing',
    'other': 'Other',
  };

  static const Map<String, String> shiftTypeLabels = {
    'day': 'Day Shift',
    'afternoon': 'Afternoon Shift',
    'night': 'Night Shift',
    'rotating': 'Rotating',
    'off': 'Day Off',
  };

  static const Map<String, String> shiftEmojis = {
    'day': '🌅',
    'afternoon': '🌆',
    'night': '🌙',
    'rotating': '🔄',
    'off': '✅',
  };

  static const double defaultSleepGoal = 7.5;
  static const double minSleepGoal = 6.0;
  static const double maxSleepGoal = 9.0;

  static const int caffeineHalfLifeHours = 6;
  static const int caffeineSensitiveHours = 7;
  static const int caffeineVerySensitiveHours = 8;

  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String profileSetupKey = 'profile_setup';
}
