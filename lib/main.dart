import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'core/router/app_router.dart';
import 'features/profile/providers/settings_provider.dart';
import 'core/services/ad_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:aqua_sort/features/profile/providers/premium_provider.dart';
import 'package:aqua_sort/core/services/remote_config_service.dart';
import 'package:aqua_sort/core/services/push_notification_service.dart';

void main() async {
  debugPrint('APP STARTING');
  // usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully!');
    // Initialize remote config and updates
    await RemoteConfigService.init();
    // Initialize push notifications
    await PushNotificationService.init();
  } catch (e) {
    debugPrint('Firebase/RemoteConfig init skipped: $e');
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize AdMob SDK before the first frame
  await AdService.instance.initialize();

  runApp(const ProviderScope(child: AquaSortApp()));
}

class AquaSortApp extends ConsumerWidget {
  const AquaSortApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize settings to apply audio preferences immediately
    ref.watch(settingsProvider);
    final isPremium = ref.watch(premiumProvider);
    AdService.instance.isPremium = isPremium;
    
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Aqua Sort',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.cyanGlow,
          secondary: AppColors.tealAccent,
          surface: AppColors.midTeal,
        ),
        scaffoldBackgroundColor: AppColors.deepNavy,
        textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
      ),
    );
  }
}
