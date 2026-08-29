import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../services/activity_provider.dart';
import '../services/app_translations.dart';
import '../services/notification_service.dart';
import '../services/locale_service.dart';
import '../theme/app_colors.dart';
import '../widgets/activity_card.dart';
import '../widgets/quotient_indicator.dart';
import 'add_activity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filter = 'all';
  int _selectedNav = 0;
  int _selectedDateIndex = 3;
  DateTime _selectedCalendarDate = DateTime.now();
  late final ScrollController _scrollController;

  bool get _selectedCalendarDateIsPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedCalendarDate.year,
      _selectedCalendarDate.month,
      _selectedCalendarDate.day,
    );
    return selected.isBefore(today);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted = await NotificationService.requestPermissions();
      if (!mounted) return;
      final provider = context.read<ActivityProvider>();
      await provider.loadActivities();
      if (granted && mounted) {
        await NotificationService.rescheduleAllNotifications(
          provider.activities,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openAddActivity({DateTime? initialDate}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddActivityScreen(initialDate: initialDate),
      ),
    );
  }

  Future<void> _openEditActivity(Activity activity) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddActivityScreen(activity: activity)),
    );
  }

  List<Activity> _visibleActivities(ActivityProvider provider) {
    switch (_filter) {
      case 'done':
        return provider.completedToday;
      case 'pending':
        return provider.pendingToday;
      default:
        return provider.todayActivities;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = Hive.box('settings');
    final userName = settings.get('userName', defaultValue: '') as String;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        bottom: false,
        child: Consumer<ActivityProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              );
            }

            final activities = _visibleActivities(provider);
            final now = DateTime.now();
            final dates = List.generate(
              7,
              (index) => DateTime(now.year, now.month, now.day + index - 3),
            );
            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: _buildSlivers(
                context,
                provider,
                t,
                userName,
                dates,
                activities,
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedNav == 1 && _selectedCalendarDateIsPast
            ? null
            : () => _openAddActivity(
                initialDate: _selectedNav == 1 ? _selectedCalendarDate : null,
              ),
        backgroundColor: _selectedNav == 1 && _selectedCalendarDateIsPast
            ? AppColors.textMuted
            : AppColors.purple,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  List<Widget> _buildSlivers(
    BuildContext context,
    ActivityProvider provider,
    AppLocalizations t,
    String userName,
    List<DateTime> dates,
    List<Activity> activities,
  ) {
    if (_selectedNav == 1) {
      return _buildCalendarSlivers(context, provider, t, userName, dates);
    }
    if (_selectedNav == 2) {
      return _buildProgressSlivers(context, provider, t, userName);
    }
    if (_selectedNav == 3) {
      return _buildProfileSlivers(context, provider, t, userName);
    }

    return [
      SliverToBoxAdapter(child: _buildHeader(userName, t)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: QuotientIndicator(
            onViewTasks: () => _scrollController.animateTo(
              280,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _buildSectionHeader(t, provider.todayActivities.length),
      ),
      SliverToBoxAdapter(child: _buildFilters(t)),
      if (activities.isEmpty)
        SliverToBoxAdapter(child: _buildEmptyState(t))
      else
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final activity = activities[index];
            return ActivityCard(
              activity: activity,
              completed: activity.isCompletedToday,
              onToggle: () => provider.toggleActivityCompletion(activity.id),
              onDelete: () => _showDeleteDialog(context, provider, activity.id),
              onEdit: () => _openEditActivity(activity),
            );
          }, childCount: activities.length),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 112)),
    ];
  }

  List<Widget> _buildCalendarSlivers(
    BuildContext context,
    ActivityProvider provider,
    AppLocalizations t,
    String userName,
    List<DateTime> dates,
  ) {
    final selectedDate = dates[_selectedDateIndex];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = selectedDate.isBefore(today);
    final activities = provider.activitiesForDate(selectedDate);
    final isToday = selectedDate == today;
    return [
      SliverToBoxAdapter(child: _buildHeader(userName, t)),
      SliverToBoxAdapter(
        child: _buildTabTitle(
          t.isFrench ? 'Calendrier' : 'Calendar',
          t.isFrench
              ? 'Organisez vos habitudes sur la semaine.'
              : 'Organize your habits across the week.',
        ),
      ),
      SliverToBoxAdapter(child: _buildDateStrip(dates, t)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
          child: Text(
            isPast
                ? (t.isFrench
                      ? 'Historique du ${selectedDate.day} ${t.monthName(selectedDate.month)}'
                      : 'History for ${t.monthName(selectedDate.month)} ${selectedDate.day}')
                : activities.isEmpty
                ? (isToday
                      ? (t.isFrench
                            ? 'Aucune tâche prévue aujourd’hui'
                            : 'No tasks planned today')
                      : (t.isFrench
                            ? 'Aucune tâche pour cette date'
                            : 'No tasks for this date'))
                : (isToday
                      ? (t.isFrench
                            ? 'Tâches prévues aujourd’hui'
                            : 'Tasks planned today')
                      : '${selectedDate.day} ${t.monthName(selectedDate.month)}'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      if (activities.isEmpty)
        SliverToBoxAdapter(child: _buildEmptyState(t))
      else
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final activity = activities[index];
            return ActivityCard(
              activity: activity,
              completed: activity.isCompletedOn(selectedDate),
              onToggle: isPast
                  ? null
                  : () => provider.toggleActivityCompletion(
                      activity.id,
                      date: selectedDate,
                    ),
              onDelete: isPast
                  ? null
                  : () => _showDeleteDialog(context, provider, activity.id),
              onEdit: isPast ? null : () => _openEditActivity(activity),
            );
          }, childCount: activities.length),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 112)),
    ];
  }

  List<Widget> _buildProgressSlivers(
    BuildContext context,
    ActivityProvider provider,
    AppLocalizations t,
    String userName,
  ) {
    return [
      SliverToBoxAdapter(child: _buildHeader(userName, t)),
      SliverToBoxAdapter(
        child: _buildTabTitle(
          t.isFrench ? 'Ma progression' : 'My progress',
          t.isFrench
              ? 'Un aperçu simple de vos habitudes du jour.'
              : 'A simple overview of today’s habits.',
        ),
      ),
      SliverToBoxAdapter(child: _buildProgressCard(provider, t)),
      SliverToBoxAdapter(child: _buildWeekSummary(provider, t)),
      const SliverToBoxAdapter(child: SizedBox(height: 112)),
    ];
  }

  List<Widget> _buildProfileSlivers(
    BuildContext context,
    ActivityProvider provider,
    AppLocalizations t,
    String userName,
  ) {
    final localeService = context.read<LocaleService>();
    final settings = Hive.box('settings');
    final gender = settings.get('userGender', defaultValue: 'female') as String;
    return [
      SliverToBoxAdapter(child: _buildHeader(userName, t)),
      SliverToBoxAdapter(
        child: _buildTabTitle(
          t.isFrench ? 'Profil & réglages' : 'Profile & settings',
          t.isFrench
              ? 'Personnalisez votre expérience Quotient.'
              : 'Personalize your Quotient experience.',
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: _buildProfileAvatarCard(context, t, gender),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D24184A),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.face_retouching_natural_rounded,
                  title: t.chooseAvatar,
                  subtitle: gender == 'male' ? t.genderMale : t.genderFemale,
                  onTap: () => _showGenderDialog(context, t),
                ),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: t.isFrench ? 'Langue' : 'Language',
                  subtitle: localeService.isFrench ? 'Français' : 'English',
                  onTap: () => _showLanguageDialog(context, localeService),
                ),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: t.isFrench ? 'À propos de Quotient' : 'About Quotient',
                  subtitle: 'v1.0.0',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Quotient',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.purple,
                    ),
                    children: [
                      Text(
                        t.isFrench
                            ? 'Une routine simple pour avancer chaque jour.'
                            : 'A simple routine to help you move forward every day.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 112)),
    ];
  }

  Widget _buildTabTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(ActivityProvider provider, AppLocalizations t) {
    final total = provider.todayActivities.length;
    final done = provider.completedToday.length;
    final progress = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D24184A),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.dailyQuotient,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${provider.quotient}%',
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.purpleSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.purple,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$done ${t.done.toLowerCase()}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$total ${t.total.toLowerCase()}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSummary(ActivityProvider provider, AppLocalizations t) {
    final values = [
      provider.quotient * .35,
      provider.quotient * .65,
      provider.quotient.toDouble(),
      provider.quotient * .55,
      provider.quotient * .8,
      provider.quotient * .42,
      provider.quotient * .72,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.purpleSoft,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.isFrench ? 'Cette semaine' : 'This week',
              style: const TextStyle(
                color: AppColors.purpleDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 92,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  7,
                  (index) => Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 18,
                        height: 68 * (values[index] / 100).clamp(.08, 1),
                        decoration: BoxDecoration(
                          color: index == 2
                              ? AppColors.purple
                              : AppColors.purple.withValues(alpha: .32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.dayShort(index),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _avatarAssetFor(String gender) {
    return gender == 'male'
        ? 'assets/avatar_male.png'
        : 'assets/avatar_female.png';
  }

  Future<void> _showGenderDialog(
    BuildContext context,
    AppLocalizations t,
  ) async {
    final settings = Hive.box('settings');
    final current =
        settings.get('userGender', defaultValue: 'female') as String;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.chooseAvatar),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'female'),
            child: Row(
              children: [
                _avatarPreview('female', selected: current == 'female'),
                const SizedBox(width: 12),
                Text(t.genderFemale),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'male'),
            child: Row(
              children: [
                _avatarPreview('male', selected: current == 'male'),
                const SizedBox(width: 12),
                Text(t.genderMale),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      await settings.put('userGender', selected);
      if (mounted) setState(() {});
    }
  }

  Widget _avatarPreview(String gender, {required bool selected}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.purple : AppColors.bgCardLight,
          width: selected ? 2 : 1,
        ),
      ),
      child: ClipOval(
        child: Image.asset(_avatarAssetFor(gender), fit: BoxFit.cover),
      ),
    );
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    LocaleService localeService,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(
          localeService.isFrench ? 'Choisir la langue' : 'Choose language',
        ),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'fr'),
            child: const Text('Français'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'en'),
            child: const Text('English'),
          ),
        ],
      ),
    );
    if (selected != null) await localeService.setLocale(selected);
  }

  Widget _buildProfileAvatarCard(
    BuildContext context,
    AppLocalizations t,
    String gender,
  ) {
    final settings = Hive.box('settings');
    final userName = settings.get('userName', defaultValue: '') as String;
    return GestureDetector(
      onTap: () => _showGenderDialog(context, t),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D24184A),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            _avatarPreview(gender, selected: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName.isEmpty ? 'Quotient' : userName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t.isFrench
                        ? 'Appuyez pour changer votre avatar'
                        : 'Tap to change your avatar',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, AppLocalizations t) {
    final displayName = userName.isEmpty ? 'Quotient' : userName;
    final settings = Hive.box('settings');
    final gender = settings.get('userGender', defaultValue: 'female') as String;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedNav = 3),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF8E72F2), Color(0xFF5B2DE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipOval(
                child: Image.asset(_avatarAssetFor(gender), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.isFrench ? 'Bonjour !' : 'Hello!',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(AppLocalizations t, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Text(
            t.todayTasks,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          _CountBadge(value: count),
          const Spacer(),
          Text(
            '${DateTime.now().day} ${t.monthName(DateTime.now().month)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip(List<DateTime> dates, AppLocalizations t) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = dates[index];
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final isPast = date.isBefore(today);
          final selected = index == _selectedDateIndex;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDateIndex = index;
              _selectedCalendarDate = date;
              _selectedNav = 1;
            }),
            child: Container(
              width: 62,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.purple
                    : isPast
                    ? AppColors.bgCard.withValues(alpha: 0.45)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: AppColors.purpleGlow,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t.monthName(date.month).substring(0, 3),
                    style: TextStyle(
                      color: selected
                          ? Colors.white70
                          : isPast
                          ? AppColors.textMuted.withValues(alpha: 0.55)
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : isPast
                          ? AppColors.textMuted.withValues(alpha: 0.55)
                          : AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.dayShort(date.weekday - 1),
                    style: TextStyle(
                      color: selected
                          ? Colors.white70
                          : isPast
                          ? AppColors.textMuted.withValues(alpha: 0.55)
                          : AppColors.textSecondary,
                      fontSize: 10,
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

  Widget _buildFilters(AppLocalizations t) {
    final filters = <String, String>{
      'all': t.total,
      'pending': t.pending,
      'done': t.done,
    };
    return SizedBox(
      height: 62,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final key = filters.keys.elementAt(index);
          final selected = _filter == key;
          return ChoiceChip(
            label: Text(filters[key]!),
            selected: selected,
            onSelected: (_) => setState(() => _filter = key),
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.purpleDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            backgroundColor: AppColors.purpleSoft,
            selectedColor: AppColors.purple,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.purpleSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: AppColors.purple,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.noTasks,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.noTasksHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      height: 78,
      color: Colors.white,
      elevation: 18,
      shadowColor: const Color(0x24000000),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              selected: _selectedNav == 0,
              onTap: () => setState(() => _selectedNav = 0),
            ),
            _NavItem(
              icon: Icons.calendar_month_rounded,
              selected: _selectedNav == 1,
              onTap: () => setState(() => _selectedNav = 1),
            ),
            const SizedBox(width: 52),
            _NavItem(
              icon: Icons.description_rounded,
              selected: _selectedNav == 2,
              onTap: () => setState(() => _selectedNav = 2),
            ),
            _NavItem(
              icon: Icons.group_rounded,
              selected: _selectedNav == 3,
              onTap: () => setState(() => _selectedNav = 3),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ActivityProvider provider,
    String activityId,
  ) {
    final t = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          t.deleteTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          t.deleteConfirm,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              t.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteActivity(activityId);
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(t.delete),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: AppColors.purpleSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.purple, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int value;

  const _CountBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.purpleSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          color: AppColors.purple,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: selected ? AppColors.purple : AppColors.textMuted,
        size: 24,
      ),
      tooltip: selected ? 'Selected' : null,
    );
  }
}
