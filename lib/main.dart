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
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bgDark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await StorageService.init();
  await NotificationService.init();

  final settings = Hive.box('settings');
  final onboardingDone =
      settings.get('onboardingDone', defaultValue: false) as bool;
  final savedLocale = settings.get('appLocale', defaultValue: 'fr') as String;

  runApp(MyApp(showOnboarding: !onboardingDone, initialLocale: savedLocale));
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
        ChangeNotifierProvider(
          create: (_) => LocaleService()..setLocale(initialLocale),
        ),
      ],
      child: Consumer<LocaleService>(
        builder: (context, localeService, _) {
          return LocaleProvider(
            locale: localeService.locale,
            child: MaterialApp(
              title: 'Quotient',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                brightness: Brightness.light,
                scaffoldBackgroundColor: AppColors.bgDark,
                colorScheme: const ColorScheme.light(
                  primary: AppColors.purple,
                  secondary: AppColors.purpleDark,
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
              home: SplashScreen(
                nextScreen: showOnboarding
                    ? const OnboardingScreen()
                    : const HomeScreen(),
              ),
            ),
          );
        },
      ),
    );
  }
}
