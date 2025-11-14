import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _animationController.forward();

    // Debug: Check environment configuration on startup
    _checkEnvironmentConfig();
  }

  void _checkEnvironmentConfig() {
    print('🚀 DEBUG SPLASH: Environment check on startup');
    print('🚀 DEBUG SPLASH: API_BASE_URL = ${dotenv.env['API_BASE_URL']}');
    print('🚀 DEBUG SPLASH: All env vars: ${dotenv.env}');

    if (dotenv.env['API_BASE_URL']?.isEmpty ?? true) {
      print('❌ WARNING: API_BASE_URL is not set or empty!');
    } else if (!dotenv.env['API_BASE_URL']!.contains('onrender.com')) {
      print('⚠️ WARNING: API_BASE_URL does not contain onrender.com domain');
      print('⚠️ Current value: ${dotenv.env['API_BASE_URL']}');
    } else {
      print('✅ API_BASE_URL correctly configured for Render');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth > 600 ? 0 : 24.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 2),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // Responsive logo size
                            Container(
                              width: constraints.maxWidth > 600 ? 140 : 100,
                              height: constraints.maxWidth > 600 ? 140 : 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  constraints.maxWidth > 600 ? 32 : 24,
                                ),
                              ),
                              child: Icon(
                                Icons.home_rounded,
                                size: constraints.maxWidth > 600 ? 70 : 50,
                                color: const Color(0xFF5E60CE),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'CampNest',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 36 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Find your perfect RoomMate\nand ideal living space',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 18 : 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            SizedBox(
                              width:
                                  constraints.maxWidth > 600
                                      ? 300
                                      : double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const AuthScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 32,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize:
                                        constraints.maxWidth > 600 ? 18 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
