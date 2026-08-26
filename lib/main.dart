import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/locale_service.dart';
import 'services/app_translations.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/activity_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await StorageService.init();
  await NotificationService.init();

  final settings = Hive.box('settings');
  final onboardingDone = settings.get('onboardingDone', defaultValue: false);
  final savedLocale = settings.get('appLocale', defaultValue: 'fr');

  runApp(MyApp(
    showOnboarding: !onboardingDone,
    initialLocale: savedLocale,
  ));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  final String initialLocale;

  const MyApp({
    super.key,
    required this.showOnboarding,
    required this.initialLocale,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => LocaleService()..setLocale(initialLocale)),
      ],
      child: Consumer<LocaleService>(
        builder: (context, localeService, _) {
          return LocaleProvider(
            locale: localeService.locale,
            child: MaterialApp(
              title: 'Quotient',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                brightness: Brightness.dark,
                scaffoldBackgroundColor: AppColors.bgDark,
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.cyan,
                  secondary: AppColors.cyanDark,
                  surface: AppColors.bgCard,
                ),
                useMaterial3: true,
                fontFamily: 'Roboto',
                appBarTheme: const AppBarTheme(
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
              ),
              home: showOnboarding
                  ? const OnboardingScreen()
                  : const NotificationInitializer(),
            ),
          );
        },
      ),
    );
  }
}

class NotificationInitializer extends StatefulWidget {
  const NotificationInitializer({super.key});

  @override
  State<NotificationInitializer> createState() => _NotificationInitializerState();
}

class _NotificationInitializerState extends State<NotificationInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted = await NotificationService.requestPermissions();
      debugPrint('Notifications permission: $granted');
      if (mounted) {
        final provider = context.read<ActivityProvider>();
        await provider.loadActivities();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
