import 'package:camp_nest/core/theme/app_theme.dart';
import 'package:camp_nest/core/service/auth_service.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:camp_nest/feature/presentation/screens/auth_screen.dart';
import 'package:camp_nest/feature/presentation/screens/listing_screen.dart';
import 'package:camp_nest/feature/presentation/screens/post_listing_screen.dart';
import 'package:camp_nest/feature/presentation/screens/profile_screen.dart';
import 'package:camp_nest/feature/presentation/screens/question_screen.dart';
import 'package:camp_nest/feature/presentation/widget/roomcard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load listings when home screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeWithTokenCheck();
    });
  }

  Future<void> _initializeWithTokenCheck() async {
    print('🏠 DEBUG HomeScreen: Starting initialization...');

    // First check if token is available
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      print('⏳ DEBUG HomeScreen: No token yet, waiting...');
      // Wait a bit for token to become available
      await Future.delayed(const Duration(milliseconds: 1000));

      final retryToken = await authService.getToken();
      if (retryToken != null) {
        print(
          '✅ DEBUG HomeScreen: Token available after wait, clearing error and loading listings',
        );
        // Force clear any existing error state first
        ref.read(listingsProvider.notifier).clearError();
        // Then reload listings
        ref.read(listingsProvider.notifier).loadAllListings();
      } else {
        print(
          '❌ DEBUG HomeScreen: Still no token, proceeding with load (will show error)',
        );
        ref.read(listingsProvider.notifier).loadAllListings();
      }
    } else {
      print(
        '✅ DEBUG HomeScreen: Token available immediately, clearing error and loading listings',
      );
      // Clear any existing error state first
      ref.read(listingsProvider.notifier).clearError();
      // Then load listings
      ref.read(listingsProvider.notifier).loadAllListings();
    }

    await _debugTokenStatus();
  }

  Future<void> _debugTokenStatus() async {
    final authService = AuthService();
    final token = await authService.getToken();

    print('🔍 DEBUG: Token status check');
    if (token == null) {
      print('❌ No token found - trying to refresh user state');

      // Try to refresh user state if no token
      try {
        await ref.read(authProvider.notifier).refreshUser();
        final refreshedToken = await authService.getToken();
        if (refreshedToken != null) {
          print(
            '✅ Token recovered after refresh: ${refreshedToken.substring(0, 20)}...',
          );
        } else {
          print('❌ Still no token after refresh - user needs to login');
        }
      } catch (e) {
        print('❌ Error refreshing user: $e');
      }
      return;
    }

    print('✅ Token exists: ${token.substring(0, 20)}...');

    try {
      final isExpired = JwtDecoder.isExpired(token);
      print('🕒 Token expired: $isExpired');

      if (!isExpired) {
        final decoded = JwtDecoder.decode(token);
        print('👤 Token user ID: ${decoded['sub']}');
        print(
          '⏰ Token expires at: ${DateTime.fromMillisecondsSinceEpoch(decoded['exp'] * 1000)}',
        );
      }
    } catch (e) {
      print('❌ Error decoding token: $e');
    }

    final isAuth = await authService.isAuthenticated();
    print('🔐 Is authenticated: $isAuth');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final listingsState = ref.watch(listingsProvider);

    // Debug: Log the current state to see what's being displayed
    print('🏠 DEBUG HomeScreen build:');
    print('   - isLoading: ${listingsState.isLoading}');
    print('   - error: ${listingsState.error}');
    print('   - listings count: ${listingsState.listings.length}');
    print(
      '   - Will show error: ${listingsState.error != null && listingsState.listings.isEmpty}',
    );

    // Remove conditional returns for navigation
    // Always return the HomeScreen Scaffold

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hello,',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${user?.name ?? "Student"}👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Notifications
            },
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ],
      ),
      // backgroundColor: AppTheme.textPrimary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isMobile = w < 600;
          final isTablet = w >= 600 && w < 1024;
          final isDesktop = w >= 1024;

          final horizontalPadding = isDesktop ? 24.0 : isTablet ? 20.0 : 16.0;
          const maxContentWidth = 1200.0;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 16),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionCard(
                                      title: 'Find a Room',
                                      subtitle: 'Browse available rooms',
                                      icon: Icons.home_outlined,
                                      color: Theme.of(context).colorScheme.tertiary,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const ListingsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _ActionCard(
                                      title: 'Find Roommate',
                                      subtitle: 'Take compatibility quiz',
                                      icon: Icons.people_outline,
                                      color: Theme.of(context).colorScheme.tertiary,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const QuestionnaireScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Featured listings header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Featured Rooms',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const ListingsScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('See All'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),

                      // Featured listings content as a sliver list
                      if (listingsState.isLoading)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (listingsState.error != null &&
                          listingsState.listings.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 64, color: Colors.red),
                                SizedBox(height: 16),
                                Text('Error: ${listingsState.error}'),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    print('🔄 DEBUG HomeScreen: Retry button pressed');
                                    await _debugTokenStatus();
                                    // Clear error state first, then reload
                                    ref.read(listingsProvider.notifier).clearError();
                                    ref.read(listingsProvider.notifier).loadAllListings();
                                  },
                                  child: const Text('Retry'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // Force token refresh by signing out and back in
                                    final authService = AuthService();
                                    print('🔄 Clearing stored data...');
                                    await authService.signOut();
                                    // Navigate to auth screen
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => const AuthScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  child: const Text('Sign In Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (listingsState.listings.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No rooms found'),
                                Text('Try adjusting your filters'),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              final listing = listingsState.listings[index];
                              return Container(
                                width: double.infinity,
                                height: 400,
                                margin: const EdgeInsets.only(top: 15),
                                child: RoomCard(listing: listing),
                              );
                            }, childCount: listingsState.listings.length),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ListingsScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PostListingScreen(),
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, color: Colors.grey),
            activeIcon: Icon(Icons.home, color: Colors.grey),
            label: 'Home',

            // backgroundColor: Colors.transparent,
            // backgroundColor: AppTheme.textPrimary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined, color: Colors.grey),
            activeIcon: Icon(Icons.search, color: Colors.grey),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined, color: Colors.grey),
            activeIcon: Icon(Icons.add_box, color: Colors.grey),
            label: "Post",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, color: Colors.grey),
            activeIcon: Icon(Icons.person, color: Colors.grey),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16), // Reduced padding
          constraints: const BoxConstraints(
            minHeight: 100, // Set minimum height instead of fixed height
            maxHeight: 120, // Set maximum height
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:
                MainAxisSize.min, // Important: minimize main axis size
            children: [
              Icon(
                icon,
                size: 28, // Slightly smaller icon
                color: color,
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14, // Reduced font size
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11, // Reduced font size
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
