import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/app_translations.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  int _currentPage = 0;
  String _selectedLang = 'fr';
  String _userName = '';

  // ── Animations par page ──
  late final List<AnimationController> _fadeControllers;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  // ── Animations flottantes pour les icônes ──
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  // ── Animation de scale pour le logo ──
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoController.forward();

    _fadeControllers = List.generate(4, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    });
    _fadeAnims = _fadeControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _slideAnims = _fadeControllers
        .map((c) => Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();

    // Animer la première page
    _fadeControllers[0].forward();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _goToPage(_currentPage + 1);
    } else {
      _finish();
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fadeControllers[page].forward();
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _userName = '');
      return;
    }

    final settings = Hive.box('settings');
    await settings.put('appLocale', _selectedLang);
    await settings.put('userName', name);
    await settings.put('onboardingDone', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (a, b, c) => const HomeScreen(),
        transitionsBuilder: (a, anim, b, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    _floatController.dispose();
    _logoController.dispose();
    for (final c in _fadeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      locale: _selectedLang,
      child: Builder(
        builder: (context) {
          final t = AppLocalizations.of(context);
          return Scaffold(
            backgroundColor: AppColors.bgDark,
            body: SafeArea(
              child: Column(
                children: [
                  // ── Skip button ──
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        t.onboardingSkip,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  // ── Pages ──
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildPage1(t),
                        _buildPage2(t),
                        _buildPage3(t),
                        _buildPage4(t),
                      ],
                    ),
                  ),

                  // ── Dots + bouton ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Row(
                      children: [
                        ...List.generate(4, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentPage == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? AppColors.cyan
                                  : AppColors.bgCardLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                        const Spacer(),
                        GestureDetector(
                          onTap: _nextPage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.cyan,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cyan.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              _currentPage == 3
                                  ? t.onboardingStart
                                  : t.onboardingNext,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PAGE 1 — Bienvenue + Logo animé
  // ══════════════════════════════════════════════════════════════
  Widget _buildPage1(AppLocalizations t) {
    return FadeTransition(
      opacity: _fadeAnims[0],
      child: SlideTransition(
        position: _slideAnims[0],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animé
              ScaleTransition(
                scale: _logoScale,
                child: AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (context, _) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bgCard,
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              Text(
                t.onboardingTitle1,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quotient',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t.onboardingSubtitle1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PAGE 2 — Fonctionnalités avec icônes animées
  // ══════════════════════════════════════════════════════════════
  Widget _buildPage2(AppLocalizations t) {
    return FadeTransition(
      opacity: _fadeAnims[1],
      child: SlideTransition(
        position: _slideAnims[1],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo plus petit
              AnimatedBuilder(
                animation: _floatAnim,
                builder: (context, _) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnim.value * 0.5),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgCard,
                        border: Border.all(
                          color: AppColors.cyan.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              _AnimatedFeatureCard(
                icon: Icons.add_task_rounded,
                label: t.isFrench ? 'Créer des tâches' : 'Create tasks',
                subtitle: t.isFrench
                    ? 'Ajoutez vos activités quotidiennes'
                    : 'Add your daily activities',
                color: AppColors.cyan,
                delay: 0,
              ),
              const SizedBox(height: 12),
              _AnimatedFeatureCard(
                icon: Icons.schedule_rounded,
                label: t.isFrench ? 'Planifier des heures' : 'Schedule times',
                subtitle: t.isFrench
                    ? 'Définissez les horaires de chaque tâche'
                    : 'Set the schedule for each task',
                color: AppColors.success,
                delay: 100,
              ),
              const SizedBox(height: 12),
              _AnimatedFeatureCard(
                icon: Icons.check_circle_rounded,
                label: t.isFrench ? 'Suivre vos progrès' : 'Track progress',
                subtitle: t.isFrench
                    ? 'Visualisez votre quotient de productivité'
                    : 'See your productivity quotient',
                color: AppColors.warning,
                delay: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PAGE 3 — Sélection langue
  // ══════════════════════════════════════════════════════════════
  Widget _buildPage3(AppLocalizations t) {
    return FadeTransition(
      opacity: _fadeAnims[2],
      child: SlideTransition(
        position: _slideAnims[2],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _floatAnim,
                builder: (context, _) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnim.value * 0.7),
                    child: const Icon(
                      Icons.language_rounded,
                      size: 80,
                      color: AppColors.cyan,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                t.onboardingTitle3,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.onboardingSubtitle3,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _LangButton(
                      label: 'Français',
                      flag: '🇫🇷',
                      isSelected: _selectedLang == 'fr',
                      onTap: () => setState(() => _selectedLang = 'fr'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LangButton(
                      label: 'English',
                      flag: '🇬🇧',
                      isSelected: _selectedLang == 'en',
                      onTap: () => setState(() => _selectedLang = 'en'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PAGE 4 — Prénom / Pseudo
  // ══════════════════════════════════════════════════════════════
  Widget _buildPage4(AppLocalizations t) {
    return FadeTransition(
      opacity: _fadeAnims[3],
      child: SlideTransition(
        position: _slideAnims[3],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar animé
              AnimatedBuilder(
                animation: _floatAnim,
                builder: (context, _) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgCard,
                        border: Border.all(
                          color: AppColors.cyan.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: _userName.isNotEmpty
                          ? Center(
                              child: Text(
                                _userName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cyan,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                t.onboardingTitle4,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.onboardingSubtitle4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              // Champ de saisie
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _nameFocus.hasFocus
                        ? AppColors.cyan
                        : AppColors.bgCardLight,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  onChanged: (v) => setState(() => _userName = v),
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    hintText: t.onboardingNameHint,
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Carte de fonctionnalité avec animation d'entrée décalée ──
class _AnimatedFeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final int delay;

  const _AnimatedFeatureCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bouton de sélection de langue ──
class _LangButton extends StatelessWidget {
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.bgCardLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
