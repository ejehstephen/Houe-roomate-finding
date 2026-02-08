import 'package:camp_nest/feature/presentation/screens/splash_screen.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camp_nest/core/extension/config.dart';
import 'package:camp_nest/feature/presentation/screens/update_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: RoomMatchApp()));
}

class RoomMatchApp extends ConsumerStatefulWidget {
  const RoomMatchApp({super.key});

  @override
  ConsumerState<RoomMatchApp> createState() => _RoomMatchAppState();
}

class _RoomMatchAppState extends ConsumerState<RoomMatchApp> {
  // Global key to navigate without context availability in listener
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Listen for Auth Events (Deep Linking)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // Navigate to update screen
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
        );
      } else if (event == AuthChangeEvent.signedIn) {
        // Refresh provider so UI (AuthScreen/SplashScreen) can react
        ref.read(authProvider.notifier).refreshUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'RoomMatch',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
