import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/onboarding/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _StarField(),
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: const [
              _OnboardingPage1(),
              _OnboardingPage2(),
              _OnboardingPage3(),
            ],
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage < 2 ? 'Next' : 'Set up my schedule →',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_currentPage < 2) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/onboarding/setup'),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarPainter(),
      child: Container(),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final stars = [
      Offset(size.width * 0.1, size.height * 0.05),
      Offset(size.width * 0.85, size.height * 0.08),
      Offset(size.width * 0.45, size.height * 0.12),
      Offset(size.width * 0.7, size.height * 0.18),
      Offset(size.width * 0.2, size.height * 0.22),
      Offset(size.width * 0.6, size.height * 0.04),
      Offset(size.width * 0.3, size.height * 0.09),
      Offset(size.width * 0.9, size.height * 0.15),
      Offset(size.width * 0.55, size.height * 0.25),
      Offset(size.width * 0.15, size.height * 0.3),
    ];

    for (final star in stars) {
      canvas.drawCircle(star, 1.5, paint);
    }

    final brightPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.12), 2.5,
        brightPaint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.07), 2.0,
        brightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OnboardingPage1 extends StatelessWidget {
  const _OnboardingPage1();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 100, 32, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌙', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 32),
          Text(
            'Built for the people who work while the world sleeps.',
            style: GoogleFonts.sora(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Standard sleep apps tell you to wind down at 9pm. You\'re starting your shift at 9pm. This app gets that.',
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage2 extends StatelessWidget {
  const _OnboardingPage2();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your shift changes. Your sleep plan changes with it.',
            style: GoogleFonts.sora(
              color: AppColors.text,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ShiftPreviewCard(
                  shiftLabel: '🌅 Day Shift',
                  shiftTime: '7am – 3pm',
                  sleepWindow: '10:30 PM → 6:30 AM',
                  color: AppColors.dayShift,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShiftPreviewCard(
                  shiftLabel: '🌙 Night Shift',
                  shiftTime: '11pm – 7am',
                  sleepWindow: '8:00 AM → 4:00 PM',
                  color: AppColors.nightShift,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Tell us your schedule and we\'ll tell you exactly when to sleep.',
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftPreviewCard extends StatelessWidget {
  final String shiftLabel;
  final String shiftTime;
  final String sleepWindow;
  final Color color;

  const _ShiftPreviewCard({
    required this.shiftLabel,
    required this.shiftTime,
    required this.sleepWindow,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shiftLabel,
            style: GoogleFonts.nunito(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            shiftTime,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.text,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sleep window',
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sleepWindow,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage3 extends StatelessWidget {
  const _OnboardingPage3();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 100, 32, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 32),
          Text(
            'Sleep smarter, not longer.',
            style: GoogleFonts.sora(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Split sleep, recovery days, caffeine cutoffs — all planned around YOUR shifts.',
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          _FeatureRow(
              icon: '🌙', text: 'Shift-aware sleep windows'),
          _FeatureRow(
              icon: '☕', text: 'Caffeine cutoff calculator'),
          _FeatureRow(
              icon: '💡', text: 'Light exposure timing'),
          _FeatureRow(
              icon: '📊', text: 'Sleep history & trends'),
          _FeatureRow(
              icon: '🔔', text: 'Bedtime & shift reminders'),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.nunito(
              color: AppColors.text,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Profile Setup Screen ----

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  String _selectedJobType = '';
  double _sleepGoal = AppConstants.defaultSleepGoal;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).save({
        'name': _nameController.text.trim().isEmpty
            ? 'Shift Worker'
            : _nameController.text.trim(),
        'job_type': _selectedJobType.isEmpty ? 'other' : _selectedJobType,
        'sleep_goal_hours': _sleepGoal,
        'created_at': DateTime.now().toIso8601String(),
      });

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(AppConstants.onboardingCompletedKey, true);

      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Let\'s personalize your plan',
              style: GoogleFonts.sora(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This takes 30 seconds. Your data stays on your device.',
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "What's your name?",
              style: GoogleFonts.sora(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              style: GoogleFonts.nunito(color: AppColors.text),
              decoration: const InputDecoration(
                hintText: 'Your name (optional)',
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'What kind of shift work do you do?',
              style: GoogleFonts.sora(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.jobTypes.map((type) {
                final label = AppConstants.jobTypeLabels[type]!;
                final selected = _selectedJobType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedJobType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.nunito(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sleep goal',
                  style: GoogleFonts.sora(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_sleepGoal.toStringAsFixed(1)} hrs',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Slider(
              value: _sleepGoal,
              min: AppConstants.minSleepGoal,
              max: AppConstants.maxSleepGoal,
              divisions: 6,
              onChanged: (val) => setState(() => _sleepGoal = val),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('6h',
                    style: GoogleFonts.nunito(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text('9h',
                    style: GoogleFonts.nunito(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 40),
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
                        'Start planning my sleep →',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
