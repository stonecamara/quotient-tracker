import 'package:flutter/material.dart';

/// Centralisation de toutes les chaînes traduites de l'app.
/// Utilisation : `AppLocalizations.of(context).someKey`
class AppLocalizations {
  final String locale;
  const AppLocalizations(this.locale);

  bool get _fr => locale == 'fr';
  bool get isFrench => locale == 'fr';

  static AppLocalizations of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_LocaleInherited>()!
        .localizations;
  }

  // ── Onboarding ──
  String get onboardingTitle1 => _fr ? 'Bienvenue sur' : 'Welcome to';
  String get onboardingSubtitle1 => _fr
      ? 'Suivez vos activités quotidiennes et maximisez votre quotient de productivité'
      : 'Track your daily activities and maximize your productivity quotient';
  String get onboardingTitle2 =>
      _fr ? 'Planifiez vos journées' : 'Plan your days';
  String get onboardingSubtitle2 => _fr
      ? 'Créez des tâches récurrentes, définissez des heures et laissez l\'app vous guider'
      : 'Create recurring tasks, set times and let the app guide you';
  String get onboardingTitle3 =>
      _fr ? 'Choisissez votre langue' : 'Choose your language';
  String get onboardingSubtitle3 => _fr
      ? 'Vous pourrez changer la langue plus tard dans les paramètres'
      : 'You can change the language later in settings';
  String get onboardingNext => _fr ? 'Suivant' : 'Next';
  String get onboardingStart => _fr ? 'Commencer' : 'Get Started';
  String get onboardingSkip => _fr ? 'Passer' : 'Skip';
  String get onboardingTitle4 =>
      _fr ? 'Comment vous appelez-vous ?' : 'What\'s your name?';
  String get onboardingSubtitle4 => _fr
      ? 'Entrez votre prénom ou pseudo pour personnaliser votre expérience'
      : 'Enter your first name or nickname to personalize your experience';
  String get onboardingNameHint => _fr ? 'Votre prénom...' : 'Your name...';
  String get onboardingNameRequired =>
      _fr ? 'Veuillez entrer votre prénom' : 'Please enter your name';

  // ── Home Screen ──
  String greeting(String name) {
    return _fr ? 'Salut, $name 👋' : 'Hey, $name 👋';
  }

  String get todayTasks => _fr ? 'Tâches du jour' : 'Today\'s Tasks';
  String get addTask => _fr ? 'Ajouter' : 'Add New';
  String get done => _fr ? 'Fait' : 'Done';
  String get pending => _fr ? 'En cours' : 'Pending';
  String get total => _fr ? 'Total' : 'Total';
  String get noTasks => _fr ? 'Aucune tâche' : 'No tasks yet';
  String get noTasksHint => _fr
      ? 'Ajoutez votre première tâche pour commencer'
      : 'Add your first task to start tracking';
  String get notificationTest =>
      _fr ? 'Notification test envoyée !' : 'Test notification sent!';
  String get batteryHint => _fr
      ? 'Paramètres > Batterie > Quotient > Non restreint'
      : 'Settings > Battery > Quotient > Unrestricted';

  // ── Delete Dialog ──
  String get deleteTitle => _fr ? 'Supprimer la tâche' : 'Delete Task';
  String get deleteConfirm => _fr
      ? 'Voulez-vous vraiment supprimer cette activité ?'
      : 'Are you sure you want to delete this activity?';
  String get cancel => _fr ? 'Annuler' : 'Cancel';
  String get delete => _fr ? 'Supprimer' : 'Delete';

  // ── Add/Edit Activity ──
  String get newTask => _fr ? 'Nouvelle tâche' : 'New Task';
  String get editTask => _fr ? 'Modifier la tâche' : 'Edit Task';
  String get taskName => _fr ? 'Nom de la tâche' : 'Task Name';
  String get taskNameHint =>
      _fr ? 'Lecture, Peinture, Exercice...' : 'Reading, Painting, Exercise...';
  String get taskNameRequired =>
      _fr ? 'Veuillez entrer un nom' : 'Please enter a name';
  String get description =>
      _fr ? 'Description (optionnel)' : 'Description (optional)';
  String get descriptionHint =>
      _fr ? 'Ajouter des détails...' : 'Add some details...';
  String get scheduledTime => _fr ? 'Heure prévue' : 'Scheduled Time';
  String get repeat => _fr ? 'Répéter' : 'Repeat';
  String get save => _fr ? 'Enregistrer' : 'Save Changes';
  String get finish => _fr ? 'Terminer' : 'Finish';

  // ── Quotient ──
  String get dailyQuotient => _fr ? 'Quotient du jour' : 'Daily Quotient';
  String get completedLabel => _fr ? 'terminées' : 'completed';

  String motivationalMessage(int quotient) {
    if (quotient >= 80) {
      return _fr ? 'Excellent ! Continuez !' : 'Excellent! Keep it up!';
    }
    if (quotient >= 60) {
      return _fr ? 'Super progrès aujourd\'hui !' : 'Great progress today!';
    }
    if (quotient >= 40) {
      return _fr ? 'Pas mal, continuez !' : 'Not bad, keep going!';
    }
    if (quotient >= 20) {
      return _fr ? 'Encore un petit effort !' : 'A few more to go!';
    }
    if (quotient > 0) return _fr ? 'C\'est parti !' : 'Let\'s get started!';
    return _fr ? 'Ajoutez des tâches pour commencer !' : 'Add tasks to begin!';
  }

  // ── Months FR ──
  String monthName(int month) {
    if (!_fr) {
      const enMonths = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return enMonths[month];
    }
    const frMonths = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return frMonths[month];
  }

  // ── Days ──
  String dayShort(int index) {
    if (_fr) {
      const fr = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return fr[index];
    }
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return en[index];
  }
}

// ── InheritedWidget pour propager les traductions ──
class _LocaleInherited extends InheritedWidget {
  final AppLocalizations localizations;
  const _LocaleInherited({required this.localizations, required super.child});

  @override
  bool updateShouldNotify(_LocaleInherited oldWidget) {
    return localizations.locale != oldWidget.localizations.locale;
  }
}

class LocaleProvider extends StatelessWidget {
  final String locale;
  final Widget child;

  const LocaleProvider({super.key, required this.locale, required this.child});

  @override
  Widget build(BuildContext context) {
    return _LocaleInherited(
      localizations: AppLocalizations(locale),
      child: child,
    );
  }
}
