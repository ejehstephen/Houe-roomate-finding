import 'package:camp_nest/feature/presentation/screens/auth_screen.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Find Compatible\nRoommates',
      description:
          'Connect with people who share your lifestyle, habits, and preferences for a harmonious living experience.',
      image: 'assets/images/students-sharing-apartment.webp',
    ),
    OnboardingContent(
      title: 'Find Your\nPerfect Room',
      description:
          'Discover verified listings and premium amenities that match your standards and comfort.',
      image: 'assets/images/istockphoto-.jpg',
    ),
    OnboardingContent(
      title: 'Join a\nThriving Community',
      description:
          'Be part of a vibrant student community where connections are made and shared experiences last a lifetime.',
      image: 'assets/images/student-org-african-student-.png',
    ),
  ];

  void _nextPage() {
    if (_currentIndex < _contents.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _navigateToAuth();
    }
  }

  Future<void> _navigateToAuth() async {
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Image with Gradient Overlay
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: Container(
                key: ValueKey<int>(_currentIndex),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_contents[_currentIndex].image),
                    fit: BoxFit.contain,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 16),
                    child: TextButton(
                      onPressed: _navigateToAuth,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Page Content
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInSlide(
                        key: ValueKey('title_$_currentIndex'),
                        duration: 0.6,
                        child: Text(
                          _contents[_currentIndex].title,
                          textAlign: TextAlign.left,
                          style: Theme.of(
                            context,
                          ).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeInSlide(
                        key: ValueKey('desc_$_currentIndex'),
                        duration: 0.6,
                        delay: 0.2,
                        child: Text(
                          _contents[_currentIndex].description,
                          textAlign: TextAlign.left,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Navigation Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicators
                      Row(
                        children: List.generate(
                          _contents.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 4,
                            width: _currentIndex == index ? 32 : 12,
                            decoration: BoxDecoration(
                              color:
                                  _currentIndex == index
                                      ? Theme.of(context).primaryColor
                                      : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                      // Next/Get Started Button
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          elevation: 0,
                        ),
                        child: Icon(
                          _currentIndex == _contents.length - 1
                              ? Icons.check
                              : Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String image;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.image,
  });
}
