import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/preferences_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: MofuApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/feed', builder: (_, __) => const HomeScreen()),
  ],
);

class MofuApp extends ConsumerWidget {
  const MofuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesProvider);
    final isNight = prefsAsync.valueOrNull?.isNightMode ?? false;

    return MaterialApp.router(
      title: 'MOFU',
      debugShowCheckedModeBanner: false,
      theme: isNight ? AppTheme.night : AppTheme.light,
      routerConfig: _router,
      builder: (context, child) => OfflineBanner(child: child!),
    );
  }
}
