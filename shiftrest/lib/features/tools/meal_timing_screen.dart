import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class MealTimingTab extends StatefulWidget {
  const MealTimingTab({super.key});

  @override
  State<MealTimingTab> createState() => _MealTimingTabState();
}

class _MealTimingTabState extends State<MealTimingTab> {
  String _shiftType = 'night';
  TimeOfDay _shiftStart = const TimeOfDay(hour: 23, minute: 0);
  bool _showPlan = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(),
          const SizedBox(height: 16),

          _InputCard(
            shiftType: _shiftType,
            shiftStart: _shiftStart,
            onShiftTypeChanged: (t) => setState(() => _shiftType = t),
            onShiftStartChanged: (t) => setState(() => _shiftStart = t),
            onGenerate: () => setState(() => _showPlan = true),
          ),

          if (_showPlan) ...[
            const SizedBox(height: 20),
            _MealPlan(
              shiftType: _shiftType,
              shiftStart: _shiftStart,
            ),
            const SizedBox(height: 16),
            _NightShiftScience(),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Eating at the wrong time on night shifts raises diabetes risk by up to 50% and compounds fatigue. Timing matters.',
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final String shiftType;
  final TimeOfDay shiftStart;
  final ValueChanged<String> onShiftTypeChanged;
  final ValueChanged<TimeOfDay> onShiftStartChanged;
  final VoidCallback onGenerate;

  const _InputCard({
    required this.shiftType,
    required this.shiftStart,
    required this.onShiftTypeChanged,
    required this.onShiftStartChanged,
    required this.onGenerate,
  });

  String _fmt(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$dh:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shift type',
              style: GoogleFonts.sora(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: {
              'day': '🌅 Day',
              'afternoon': '🌆 Afternoon',
              'night': '🌙 Night',
            }.entries.map((e) {
              final sel = shiftType == e.key;
              return GestureDetector(
                onTap: () => onShiftTypeChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.warning.withOpacity(0.15)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel
                            ? AppColors.warning
                            : Colors.transparent,
                        width: 1.5),
                  ),
                  child: Text(
                    e.value,
                    style: GoogleFonts.nunito(
                      color: sel
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: sel
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Shift starts at',
              style: GoogleFonts.sora(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: shiftStart,
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
              if (picked != null) onShiftStartChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_outlined,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _fmt(shiftStart),
                    style: GoogleFonts.jetBrainsMono(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning),
              icon: const Icon(Icons.restaurant_menu, size: 16),
              label: Text('Generate meal plan',
                  style: GoogleFonts.nunito(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              onPressed: onGenerate,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealPlan extends StatelessWidget {
  final String shiftType;
  final TimeOfDay shiftStart;

  const _MealPlan({required this.shiftType, required this.shiftStart});

  @override
  Widget build(BuildContext context) {
    final meals = _generateMeals();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your meal timing plan',
          style: GoogleFonts.sora(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ...meals.map((meal) => _MealCard(meal: meal)),
      ],
    );
  }

  List<_MealEntry> _generateMeals() {
    final shiftH = shiftStart.hour + shiftStart.minute / 60.0;

    if (shiftType == 'night') {
      // Night shift: eat before shift, light snack mid-shift, nothing in danger zone 12am-4am
      final preShift1H = (shiftH - 4.0).clamp(12.0, 22.0);
      final preShift2H = (shiftH - 1.5).clamp(14.0, 23.0);
      final midShiftH = (shiftH + 3.5) % 24;
      final postShiftH = (shiftH + 9.0) % 24;

      return [
        _MealEntry(
          emoji: '🍽️',
          label: 'Main meal',
          timing: _fmtH(preShift1H),
          description:
              'Eat your biggest meal here — 3–4hrs before your shift starts. Protein + complex carbs. Gives you fuel without sitting heavy.',
          type: _MealType.eat,
        ),
        _MealEntry(
          emoji: '🥗',
          label: 'Light pre-shift snack',
          timing: _fmtH(preShift2H),
          description:
              'Small snack 1–2hrs before starting. Banana, yoghurt, or nuts. Nothing heavy — you\'ll be on your feet.',
          type: _MealType.eat,
        ),
        _MealEntry(
          emoji: '⚠️',
          label: 'Avoid eating 12 AM – 4 AM',
          timing: '12:00 AM – 4:00 AM',
          description:
              'Your body\'s digestive system is in shutdown mode. Eating now raises blood glucose and metabolic risk. If you must eat: nuts, fruit, or a small protein snack only.',
          type: _MealType.avoid,
        ),
        _MealEntry(
          emoji: '🫙',
          label: 'Mid-shift snack (if needed)',
          timing: _fmtH(midShiftH),
          description:
              'If you\'re past 4am and genuinely hungry: small protein snack only. Avoid sugar — the spike and crash will hit hard at 5am.',
          type: _MealType.caution,
        ),
        _MealEntry(
          emoji: '🌅',
          label: 'Post-shift recovery meal',
          timing: _fmtH(postShiftH),
          description:
              'After your sleep window ends. Light, balanced meal. Avoid heavy food immediately after waking — give your digestive system 30–60 min.',
          type: _MealType.eat,
        ),
      ];
    } else if (shiftType == 'afternoon') {
      final preShiftH = (shiftH - 2.0).clamp(10.0, 17.0);
      final midShiftH = (shiftH + 3.0) % 24;

      return [
        _MealEntry(
          emoji: '☀️',
          label: 'Morning meal',
          timing: _fmtH(8.0),
          description:
              'Standard breakfast. Don\'t skip it — your afternoon shift will be harder if you\'re running on empty by 2pm.',
          type: _MealType.eat,
        ),
        _MealEntry(
          emoji: '🍽️',
          label: 'Pre-shift main meal',
          timing: _fmtH(preShiftH),
          description:
              'Eat your main meal 2hrs before your shift. Protein + complex carbs. Not too heavy — you\'ll still be active.',
          type: _MealType.eat,
        ),
        _MealEntry(
          emoji: '🫙',
          label: 'Mid-shift snack',
          timing: _fmtH(midShiftH),
          description:
              'Small balanced snack if it\'s a long shift. Avoid anything sugary — the evening crash is real.',
          type: _MealType.caution,
        ),
        _MealEntry(
          emoji: '🌙',
          label: 'Late meal — keep it light',
          timing: 'After shift',
          description:
              'You\'re eating late. Keep it light: protein + vegetables. Avoid heavy carbs which will disrupt your sleep.',
          type: _MealType.caution,
        ),
      ];
    } else {
      // Day shift
      final preShiftH = (shiftH - 1.0).clamp(5.0, 9.0);
      return [
        _MealEntry(
          emoji: '☀️',
          label: 'Pre-shift breakfast',
          timing: _fmtH(preShiftH),
          description:
              'Eat before your shift. Even something small. Protein + slow carbs. Your brain needs glucose to start.',
          type: _MealType.eat,
        ),
        _MealEntry(
          emoji: '🍽️',
          label: 'Lunch',
          timing: '12:00 PM – 1:00 PM',
          description:
              'Main midday meal. Standard balanced plate — you\'re on the easiest shift for digestion.',
          type: _MealType.eat,
        ),
        _MealEntry(
          emoji: '🫙',
          label: 'Afternoon snack (optional)',
          timing: '3:00 PM – 4:00 PM',
          description:
              'If you get the 3pm dip, a small protein snack beats a coffee refill.',
          type: _MealType.caution,
        ),
        _MealEntry(
          emoji: '🌙',
          label: 'Evening meal',
          timing: '6:00 PM – 8:00 PM',
          description:
              'Normal dinner. Try to eat at least 2–3hrs before your planned bedtime.',
          type: _MealType.eat,
        ),
      ];
    }
  }

  String _fmtH(double h) {
    h = h % 24;
    final hour = h.floor();
    final min = ((h - hour) * 60).round();
    final ampm = hour < 12 ? 'AM' : 'PM';
    final dh = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$dh:${min.toString().padLeft(2, '0')} $ampm';
  }
}

enum _MealType { eat, avoid, caution }

class _MealEntry {
  final String emoji;
  final String label;
  final String timing;
  final String description;
  final _MealType type;

  const _MealEntry({
    required this.emoji,
    required this.label,
    required this.timing,
    required this.description,
    required this.type,
  });
}

class _MealCard extends StatelessWidget {
  final _MealEntry meal;
  const _MealCard({required this.meal});

  Color get _color {
    switch (meal.type) {
      case _MealType.eat:
        return AppColors.success;
      case _MealType.avoid:
        return const Color(0xFFE53935);
      case _MealType.caution:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(meal.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Container(
                width: 3,
                height: 40,
                color: _color.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meal.label,
                        style: GoogleFonts.sora(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        meal.timing,
                        style: GoogleFonts.jetBrainsMono(
                            color: _color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  meal.description,
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NightShiftScience extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔬 Why meal timing matters for shift workers',
            style: GoogleFonts.sora(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...[
            'Insulin sensitivity drops 40–50% during night hours — the same food causes a bigger blood sugar spike at 2am than at 2pm.',
            'Your digestive system follows its own circadian rhythm. Stomach acid, digestive enzymes, and gut motility all slow at night.',
            'Night shift workers who eat during the 12am–4am window have significantly higher rates of metabolic syndrome, regardless of what they eat.',
            'Keeping meal times consistent (even on off days) helps anchor your circadian rhythm faster than any supplement.',
          ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•',
                        style: GoogleFonts.nunito(
                            color: AppColors.primary, fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t,
                          style: GoogleFonts.nunito(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.5)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
