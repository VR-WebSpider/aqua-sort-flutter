import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'core/router/app_router.dart';
import 'features/profile/providers/settings_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  debugPrint('APP STARTING');
  // usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Supabase.initialize(
      url: 'https://zpwwjdiwcucwfuzyuiqu.supabase.co',
      anonKey: 'sb_publishable_RshKP0PKYrNinhh8xcKuqA_3CjMiKhq',
    );
  } catch (e) {
    debugPrint('Supabase init skipped: $e');
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ProviderScope(child: AquaSortApp()));
}

class AquaSortApp extends ConsumerWidget {
  const AquaSortApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize settings to apply audio preferences immediately
    ref.watch(settingsProvider);
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
