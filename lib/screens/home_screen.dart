import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../services/activity_provider.dart';
import '../services/app_translations.dart';
import '../services/notification_service.dart';
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
  late final ScrollController _scrollController;

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

  Future<void> _openAddActivity() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddActivityScreen()),
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
              5,
              (index) => DateTime(now.year, now.month, now.day + index - 2),
            );

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
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
                  child: _buildSectionHeader(
                    t,
                    provider.todayActivities.length,
                  ),
                ),
                SliverToBoxAdapter(child: _buildDateStrip(dates, t)),
                SliverToBoxAdapter(child: _buildFilters(t)),
                if (activities.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState(t))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final activity = activities[index];
                      return ActivityCard(
                        activity: activity,
                        onToggle: () =>
                            provider.toggleActivityCompletion(activity.id),
                        onDelete: () =>
                            _showDeleteDialog(context, provider, activity.id),
                        onEdit: () => _openEditActivity(activity),
                      );
                    }, childCount: activities.length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 112)),
              ],
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddActivity,
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(String userName, AppLocalizations t) {
    final displayName = userName.isEmpty ? 'Quotient' : userName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Container(
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
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 25,
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
          _HeaderIcon(
            icon: Icons.notifications_none_rounded,
            onTap: () async {
              await NotificationService.showTestNotification();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.notificationTest),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.textPrimary,
                ),
              );
            },
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
          final selected = index == 2;
          final date = dates[index];
          return Container(
            width: 62,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.purple : AppColors.bgCard,
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
                    color: selected ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.dayShort(date.weekday - 1),
                  style: TextStyle(
                    color: selected ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
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

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textPrimary, size: 26),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.purpleSoft,
        shape: const CircleBorder(),
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
