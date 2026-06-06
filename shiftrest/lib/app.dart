import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'core/providers.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/planner/planner_screen.dart';
import 'features/log/sleep_log_screen.dart';
import 'features/log/sleep_history_screen.dart';
import 'features/tools/tools_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/schedule/shift_patterns_screen.dart';

class ShiftRestApp extends ConsumerWidget {
  final SharedPreferences prefs;

  const ShiftRestApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final router = _buildRouter(prefs);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      routerConfig: router,
    );
  }

  GoRouter _buildRouter(SharedPreferences prefs) {
    final onboardingDone =
        prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;

    return GoRouter(
      initialLocation: onboardingDone ? '/home' : '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/onboarding/setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              _MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/schedule',
              builder: (context, state) => const ScheduleScreen(),
              routes: [
                GoRoute(
                  path: 'patterns',
                  builder: (context, state) =>
                      const ShiftPatternsScreen(),
                ),
              ],
            ),
            GoRoute(
              path: '/planner',
              builder: (context, state) => const PlannerScreen(),
            ),
            GoRoute(
              path: '/log',
              builder: (context, state) => const SleepLogScreen(),
            ),
            GoRoute(
              path: '/history',
              builder: (context, state) => const SleepHistoryScreen(),
            ),
            GoRoute(
              path: '/tools',
              builder: (context, state) => const ToolsScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex.clamp(0, 4),
          onTap: (index) => _onTabTap(context, index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bedtime_outlined),
              activeIcon: Icon(Icons.bedtime),
              label: 'Planner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build),
              label: 'Tools',
            ),
          ],
        ),
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/home') || location.startsWith('/log')) {
      return 0;
    }
    if (location.startsWith('/schedule') ||
        location.startsWith('/schedule/patterns')) return 1;
    if (location.startsWith('/planner')) return 2;
    if (location.startsWith('/history')) return 3;
    if (location.startsWith('/tools')) return 4;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onTabTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/schedule');
        break;
      case 2:
        context.go('/planner');
        break;
      case 3:
        context.go('/history');
        break;
      case 4:
        context.go('/tools');
        break;
    }
  }
}
