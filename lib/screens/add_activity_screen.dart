import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../services/activity_provider.dart';
import '../services/app_translations.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_widgets.dart';

class AddActivityScreen extends StatefulWidget {
  final Activity? activity;

  const AddActivityScreen({super.key, this.activity});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedHour = TimeOfDay.now().hour;
  int _selectedMinute = TimeOfDay.now().minute;
  List<bool> _selectedDays = [true, true, true, true, true, false, false];

  bool get isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.activity!.name;
      _descriptionController.text = widget.activity!.description ?? '';
      _selectedHour = widget.activity!.hour;
      _selectedMinute = widget.activity!.minute;
      _selectedDays = List<bool>.from(widget.activity!.weeklyDays);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.bgDark),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    Text(
                      isEditing ? t.editTask : t.newTask,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isEditing)
                      GestureDetector(
                        onTap: _deleteActivity,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                            size: 18,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 34),
                  ],
                ),
              ),

              // ── Form ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom
                        SlideFadeIn(
                          duration: const Duration(milliseconds: 400),
                          child: _buildLabel(t.taskName),
                        ),
                        const SizedBox(height: 8),
                        SlideFadeIn(
                          delay: const Duration(milliseconds: 100),
                          child: _buildInput(
                            controller: _nameController,
                            hint: t.taskNameHint,
                            icon: Icons.edit_rounded,
                            validator: (v) =>
                                v == null || v.isEmpty ? t.taskNameRequired : null,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description
                        SlideFadeIn(
                          delay: const Duration(milliseconds: 200),
                          child: _buildLabel(t.description),
                        ),
                        const SizedBox(height: 8),
                        SlideFadeIn(
                          delay: const Duration(milliseconds: 300),
                          child: _buildInput(
                            controller: _descriptionController,
                            hint: t.descriptionHint,
                            icon: Icons.notes_rounded,
                            maxLines: 3,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Heure
                        SlideFadeIn(
                          delay: const Duration(milliseconds: 400),
                          child: _buildLabel(t.scheduledTime),
                        ),
                        const SizedBox(height: 8),
                        SlideFadeIn(
                          delay: const Duration(milliseconds: 500),
                          child: GestureDetector(
                            onTap: _selectTime,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.bgCardLight,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.cyan.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.access_time_rounded,
                                      color: AppColors.cyan,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Jours
                        SlideFadeIn(
                          delay: const Duration(milliseconds: 600),
                          child: _buildLabel(t.repeat),
                        ),
                        const SizedBox(height: 8),
                        SlideFadeIn(
                          delay: const Duration(milliseconds: 700),
                          child: _buildDaysSelector(t),
                        ),

                        const SizedBox(height: 32),

                        // Bouton
                        SlideFadeIn(
                          delay: const Duration(milliseconds: 800),
                          child: TapScale(
                            onTap: _saveActivity,
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.cyan,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.cyan.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  isEditing ? t.save : t.finish,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDaysSelector(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bgCardLight, width: 1),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final isSelected = _selectedDays[index];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDays[index] = !_selectedDays[index]);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.cyan : AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      t.dayShort(index),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
    );
    if (picked != null) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
      });
    }
  }

  Future<void> _saveActivity() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<ActivityProvider>();

      if (isEditing) {
        final updated = widget.activity!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          hour: _selectedHour,
          minute: _selectedMinute,
          weeklyDays: _selectedDays,
        );
        await provider.updateActivity(updated);
      } else {
        final newActivity = Activity.create(
          name: _nameController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          hour: _selectedHour,
          minute: _selectedMinute,
          weeklyDays: _selectedDays,
        );
        await provider.addActivity(newActivity);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  void _deleteActivity() {
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
        title: Text(t.deleteTitle, style: const TextStyle(color: AppColors.textPrimary)),
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
              context.read<ActivityProvider>().deleteActivity(widget.activity!.id);
              Navigator.pop(context);
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
