import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/app_translations.dart';
import '../theme/app_colors.dart';

class ActivityCard extends StatefulWidget {
  final Activity activity;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _pressed = false;

  IconData _activityIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('sport') ||
        value.contains('gym') ||
        value.contains('exercice')) {
      return Icons.fitness_center_rounded;
    }
    if (value.contains('lecture') ||
        value.contains('lire') ||
        value.contains('livre')) {
      return Icons.menu_book_rounded;
    }
    if (value.contains('course') ||
        value.contains('achat') ||
        value.contains('magasin')) {
      return Icons.shopping_bag_rounded;
    }
    if (value.contains('travail') ||
        value.contains('code') ||
        value.contains('bureau')) {
      return Icons.work_outline_rounded;
    }
    if (value.contains('cuisine') ||
        value.contains('repas') ||
        value.contains('manger')) {
      return Icons.restaurant_rounded;
    }
    if (value.contains('médit') ||
        value.contains('medit') ||
        value.contains('yoga')) {
      return Icons.self_improvement_rounded;
    }
    if (value.contains('dorm') ||
        value.contains('sommeil') ||
        value.contains('coucher')) {
      return Icons.bedtime_rounded;
    }
    if (value.contains('marche') ||
        value.contains('promenade') ||
        value.contains('run')) {
      return Icons.directions_walk_rounded;
    }
    if (value.contains('eau') || value.contains('boire')) {
      return Icons.water_drop_rounded;
    }
    if (value.contains('étude') ||
        value.contains('etude') ||
        value.contains('apprendre')) {
      return Icons.school_rounded;
    }
    if (value.contains('ménage') ||
        value.contains('menage') ||
        value.contains('nettoy')) {
      return Icons.cleaning_services_rounded;
    }
    if (value.contains('téléphone') ||
        value.contains('telephone') ||
        value.contains('appel')) {
      return Icons.phone_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  Color _iconBackground(String name) {
    final value = name.toLowerCase();
    if (value.contains('sport') || value.contains('gym')) {
      return AppColors.pastelBlue;
    }
    if (value.contains('course') || value.contains('achat')) {
      return AppColors.pastelOrange;
    }
    if (value.contains('travail') || value.contains('code')) {
      return AppColors.pastelPink;
    }
    if (value.contains('dorm') ||
        value.contains('sommeil') ||
        value.contains('coucher')) {
      return AppColors.pastelBlue;
    }
    if (value.contains('cuisine') ||
        value.contains('repas') ||
        value.contains('manger')) {
      return AppColors.pastelYellow;
    }
    if (value.contains('ménage') ||
        value.contains('menage') ||
        value.contains('nettoy')) {
      return AppColors.pastelOrange;
    }
    return AppColors.purpleSoft;
  }

  Color _iconColor(String name) {
    final value = name.toLowerCase();
    if (value.contains('sport') || value.contains('gym')) {
      return const Color(0xFF269CE8);
    }
    if (value.contains('course') || value.contains('achat')) {
      return const Color(0xFFE89A3D);
    }
    if (value.contains('travail') || value.contains('code')) {
      return const Color(0xFFE676A0);
    }
    if (value.contains('dorm') ||
        value.contains('sommeil') ||
        value.contains('coucher')) {
      return const Color(0xFF269CE8);
    }
    if (value.contains('cuisine') ||
        value.contains('repas') ||
        value.contains('manger')) {
      return const Color(0xFFE1A43E);
    }
    if (value.contains('ménage') ||
        value.contains('menage') ||
        value.contains('nettoy')) {
      return const Color(0xFFE89A3D);
    }
    return AppColors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final activity = widget.activity;
    final completed = activity.isCompletedToday;
    final iconColor = _iconColor(activity.name);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: AnimatedScale(
        scale: _pressed ? .98 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
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
              GestureDetector(
                onTap: widget.onEdit,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _iconBackground(activity.name),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _activityIcon(activity.name),
                    color: iconColor,
                    size: 23,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onEdit,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.description?.isNotEmpty == true
                            ? activity.description!
                            : (t.isFrench
                                  ? 'Activité quotidienne'
                                  : 'Daily activity'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: completed
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: iconColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            activity.scheduledTimeFormatted,
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') widget.onEdit();
                      if (value == 'delete') widget.onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(t.editTask)),
                      PopupMenuItem(value: 'delete', child: Text(t.delete)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    button: true,
                    label: completed
                        ? (t.isFrench ? 'Tâche terminée' : 'Completed task')
                        : (t.isFrench
                              ? 'Marquer comme terminée'
                              : 'Mark as completed'),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _pressed = true),
                      onTapCancel: () => setState(() => _pressed = false),
                      onTap: () {
                        setState(() => _pressed = false);
                        widget.onToggle();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: completed
                              ? AppColors.purple
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: completed
                                ? AppColors.purple
                                : AppColors.textMuted,
                            width: 2,
                          ),
                          boxShadow: completed
                              ? const [
                                  BoxShadow(
                                    color: AppColors.purpleGlow,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: completed
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
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
}
