import 'package:flutter/material.dart';
import '../models/activity.dart';
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

class _ActivityCardState extends State<ActivityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _popAnim;
  late Animation<double> _popScale;

  @override
  void initState() {
    super.initState();
    _popAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _popScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _popAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _popAnim.dispose();
    super.dispose();
  }

  void _handleToggle() {
    _popAnim.forward().then((_) => _popAnim.reverse());
    widget.onToggle();
  }

  IconData _getActivityIcon() {
    final name = widget.activity.name.toLowerCase();
    if (name.contains('sport') || name.contains('exercice') || name.contains('gym')) {
      return Icons.fitness_center;
    }
    if (name.contains('lecture') || name.contains('lire') || name.contains('livre')) {
      return Icons.menu_book_rounded;
    }
    if (name.contains('méditation') || name.contains('yoga') || name.contains('zen')) {
      return Icons.self_improvement;
    }
    if (name.contains('manger') || name.contains('repas') || name.contains('cuisine')) {
      return Icons.restaurant_rounded;
    }
    if (name.contains('dormir') || name.contains('coucher') || name.contains('sommeil')) {
      return Icons.bedtime_rounded;
    }
    if (name.contains('travail') || name.contains('bureau') || name.contains('code')) {
      return Icons.laptop_mac_rounded;
    }
    if (name.contains('course') || name.contains('achat') || name.contains('magasin')) {
      return Icons.shopping_cart_rounded;
    }
    if (name.contains('marche') || name.contains('promenade') || name.contains('run')) {
      return Icons.directions_run;
    }
    return Icons.star_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.activity.isCompletedToday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor(completed),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: completed
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.bgCardLight.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: completed
                  ? AppColors.success.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Zone cliquable pour éditer (icône + texte) ──
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onEdit,
                child: Row(
                  children: [
                    // ── Icône d'activité ──
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: completed
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.cyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getActivityIcon(),
                        color: completed ? AppColors.success : AppColors.cyan,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ── Nom + description ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: completed ? TextDecoration.lineThrough : null,
                              color: completed
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                            ),
                            child: Text(
                              widget.activity.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.activity.description != null &&
                              widget.activity.description!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.activity.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                decoration: completed ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ── Heure ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: completed
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.bgCardLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: completed ? AppColors.success : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.activity.scheduledTimeFormatted,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: completed ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── Bouton cocher (toujours visible !) ──
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleToggle,
              child: ScaleTransition(
                scale: _popScale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? AppColors.cyan : Colors.transparent,
                    border: Border.all(
                      color: completed ? AppColors.cyan : AppColors.textMuted,
                      width: 2,
                    ),
                    boxShadow: completed
                        ? [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: completed
                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
