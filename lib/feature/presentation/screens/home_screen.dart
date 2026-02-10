import 'package:camp_nest/core/service/auth_service.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:camp_nest/feature/presentation/screens/listing_screen.dart';
import 'package:camp_nest/feature/presentation/screens/post_listing_screen.dart';
import 'package:camp_nest/feature/presentation/screens/profile_screen.dart';
import 'package:camp_nest/feature/presentation/screens/question_screen.dart';
import 'package:camp_nest/feature/presentation/widget/roomcard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:camp_nest/feature/presentation/screens/notification.dart';
import 'package:camp_nest/feature/presentation/provider/notification_provider.dart';
import 'package:camp_nest/feature/presentation/screens/verification_screen.dart';

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
        // Check if widget is still mounted before using ref
        if (!mounted) return;

        // Force clear any existing error state first
        ref.read(listingsProvider.notifier).clearError();
        // Then reload listings
        ref.read(listingsProvider.notifier).loadAllListings();
      } else {
        print(
          '❌ DEBUG HomeScreen: Still no token, proceeding with load (will show error)',
        );
        // Check if widget is still mounted before using ref
        if (!mounted) return;

        ref.read(listingsProvider.notifier).loadAllListings();
      }
    } else {
      print(
        '✅ DEBUG HomeScreen: Token available immediately, clearing error and loading listings',
      );
      // Check if widget is still mounted before using ref
      if (!mounted) return;

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
        // Check if widget is still mounted before using ref
        if (!mounted) return;

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

    return Scaffold(
      appBar: AppBar(
        title: FadeInSlide(
          duration: 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Hello,',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${user?.name ?? "Student"} 👋',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(unreadNotificationCountProvider);

              return IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: Icon(
                    unreadCount > 0
                        ? Icons.notifications
                        : Icons.notifications_outlined,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 20.0;
          const maxContentWidth = 1200.0;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.read(listingsProvider.notifier).loadAllListings();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 24),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Main action buttons
                                FadeInSlide(
                                  duration: 0.6,
                                  delay: 0.1,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _ActionCard(
                                          title: 'Find a Room',
                                          subtitle: 'Browse available rooms',
                                          icon: Icons.search_rounded,
                                          color: Theme.of(context).primaryColor,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const ListingsScreen(),
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
                                          icon: Icons.people_alt_rounded,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                          onTap: () {
                                            final user =
                                                ref.read(authProvider).user;
                                            final hasImage =
                                                user?.profileImage != null &&
                                                user!.profileImage!.isNotEmpty;
                                            final hasPhone =
                                                user?.phoneNumber != null &&
                                                user!.phoneNumber!.isNotEmpty;

                                            if (!hasImage || !hasPhone) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: const Text(
                                                        'Complete Profile',
                                                      ),
                                                      content: const Text(
                                                        'To find a roommate, you need to add a profile picture and a phone number. This helps others trust and contact you.',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                            Navigator.of(
                                                              context,
                                                            ).push(
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const ProfileScreen(),
                                                              ),
                                                            );
                                                          },
                                                          child: const Text(
                                                            'Go to Profile',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                            } else {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          const QuestionnaireScreen(),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Featured listings header
                                FadeInSlide(
                                  duration: 0.6,
                                  delay: 0.2,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Featured Rooms',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const ListingsScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text('See All'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),

                        // Featured listings content
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
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(listingsState.error!),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      ref
                                          .read(listingsProvider.notifier)
                                          .loadAllListings();
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (listingsState.listings.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.home_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No rooms found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.only(bottom: 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final listing = listingsState.listings[index];
                                return FadeInSlide(
                                  duration: 0.5,
                                  delay:
                                      0.1 * (index + 1), // Staggered animation
                                  child: Container(
                                    width: double.infinity,
                                    height: 400,
                                    margin: const EdgeInsets.only(bottom: 24),
                                    child: RoomCard(listing: listing),
                                  ),
                                );
                              }, childCount: listingsState.listings.length),
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
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            if (index == 1) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ListingsScreen()),
              );
            } else if (index == 2) {
              final user = ref.read(authProvider).user;
              if (user?.isVerified == true) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PostListingScreen(),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Verification Required'),
                        content: const Text(
                          'To ensure trust and safety, you must verify your identity before posting a room listing.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => const VerificationScreen(),
                                ), // Needs import
                              );
                            },
                            child: const Text('Verify Identity'),
                          ),
                        ],
                      ),
                );
              }
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
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Browse',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: "Post",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
