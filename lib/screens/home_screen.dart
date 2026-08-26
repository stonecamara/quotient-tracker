import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../services/activity_provider.dart';
import '../services/app_translations.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/activity_card.dart';
import '../widgets/quotient_indicator.dart';
import '../widgets/animated_widgets.dart';
import 'add_activity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().loadActivities();
    });
  }

  String _formatDate(AppLocalizations t) {
    final now = DateTime.now();
    return '${now.day} ${t.monthName(now.month)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.bgDark),
        child: SafeArea(
          bottom: false,
          child: Consumer<ActivityProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.cyan),
                );
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Header : date + actions ──
                  SliverToBoxAdapter(
                    child: SlideFadeIn(
                      duration: const Duration(milliseconds: 600),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.greeting(Hive.box('settings').get('userName', defaultValue: '')),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.cyan,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(t),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _CircleButton(
                                  icon: Icons.notifications_outlined,
                                  onTap: () async {
                                    await NotificationService.showTestNotification();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(t.notificationTest),
                                          backgroundColor: AppColors.bgCard,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                if (Platform.isAndroid) ...[
                                  const SizedBox(width: 10),
                                  _CircleButton(
                                    icon: Icons.battery_saver_outlined,
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(t.batteryHint),
                                          backgroundColor: AppColors.bgCard,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Quotient indicator ──
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: QuotientIndicator(),
                    ),
                  ),

                  // ── Section header ──
                  SliverToBoxAdapter(
                    child: SlideFadeIn(
                      delay: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t.todayTasks,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (a, b, c) =>
                                        const AddActivityScreen(),
                                    transitionsBuilder: (a, anim, b, child) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.3),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(
                                          parent: anim,
                                          curve: Curves.easeOutCubic,
                                        )),
                                        child: FadeTransition(
                                          opacity: anim,
                                          child: child,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.cyan.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      t.addTask,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Stats row ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _StatPill(
                            icon: Icons.check_circle_outline,
                            label: t.done,
                            value: provider.completedToday.length,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          _StatPill(
                            icon: Icons.schedule,
                            label: t.pending,
                            value: provider.pendingToday.length,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          _StatPill(
                            icon: Icons.list,
                            label: t.total,
                            value: provider.todayActivities.length,
                            color: AppColors.cyan,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Activity list ──
                  if (provider.todayActivities.isEmpty)
                    SliverToBoxAdapter(
                      child: SlideFadeIn(
                        delay: const Duration(milliseconds: 500),
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: AppColors.bgCard,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.cyan.withValues(alpha: 0.15),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.task_alt,
                                  size: 56,
                                  color: AppColors.cyan.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                t.noTasks,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t.noTasksHint,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final activity = provider.todayActivities[index];
                          return StaggeredAnimation(
                            index: index,
                            delay: const Duration(milliseconds: 50),
                            duration: const Duration(milliseconds: 450),
                            child: ActivityCard(
                              activity: activity,
                              onToggle: () {
                                provider.toggleActivityCompletion(activity.id);
                              },
                              onDelete: () {
                                _showDeleteDialog(context, provider, activity.id);
                              },
                              onEdit: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (a, b, c) =>
                                        AddActivityScreen(activity: activity),
                                    transitionsBuilder: (a, anim, b, child) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.3),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(
                                          parent: anim,
                                          curve: Curves.easeOutCubic,
                                        )),
                                        child: FadeTransition(
                                          opacity: anim,
                                          child: child,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: provider.todayActivities.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: PulseAnimation(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cyan,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (a, b, c) => const AddActivityScreen(),
                  transitionsBuilder: (a, anim, b, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOutCubic,
                      )),
                      child: FadeTransition(opacity: anim, child: child),
                    );
                  },
                ),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, ActivityProvider provider, String activityId) {
    final t = AppLocalizations.of(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, a1, a2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: a1, child: child),
        );
      },
      pageBuilder: (a, b, c) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteActivity(activityId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(t.delete),
          ),
        ],
      ),
    );
  }
}

// ── Bouton rond transparent ──
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.bgCardLight,
            width: 1,
          ),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}

// ── Pill de stat ──
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            AnimatedCounter(
              value: value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
