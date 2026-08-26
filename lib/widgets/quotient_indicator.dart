import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/activity_provider.dart';
import '../services/app_translations.dart';
import '../theme/app_colors.dart';
import 'animated_widgets.dart';

class QuotientIndicator extends StatefulWidget {
  const QuotientIndicator({super.key});

  @override
  State<QuotientIndicator> createState() => _QuotientIndicatorState();
}

class _QuotientIndicatorState extends State<QuotientIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        final quotient = provider.quotient;
        final color = AppColors.quotientColor(quotient);

        return AnimatedBuilder(
          animation: _glowController,
          builder: (context, _) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withValues(
                    alpha: 0.2 + _glowController.value * 0.1,
                  ),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(
                      alpha: 0.08 + _glowController.value * 0.05,
                    ),
                    blurRadius: 24 + _glowController.value * 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ── Anneau de progression ──
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.bgCardLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.transparent,
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: quotient / 100),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            );
                          },
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedCounter(
                                value: quotient,
                                duration: const Duration(milliseconds: 800),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: color.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // ── Texte ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.dailyQuotient,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.motivationalMessage(quotient),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: quotient / 100,
                            minHeight: 6,
                            backgroundColor: AppColors.bgCardLight,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${provider.completedToday.length}/${provider.todayActivities.length} ${t.completedLabel}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
