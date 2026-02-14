import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/widget/roomcard.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:camp_nest/feature/presentation/screens/post_listing_screen.dart';
import 'package:camp_nest/feature/presentation/screens/verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load user's own listings on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listingsProvider.notifier).loadMyListings();
    });
  }

  Future<void> _refresh() async {
    await ref.read(listingsProvider.notifier).loadMyListings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listingsState = ref.watch(listingsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Listings'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: theme.primaryColor,
            child:
                listingsState.isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    )
                    : listingsState.listings.isEmpty
                    ? ListView(
                      // Wrap in ListView for RefreshIndicator to work
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        FadeInSlide(
                          duration: 0.8,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_work_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'You have no listings yet.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a listing to find roommates!',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: listingsState.listings.length,
                      itemBuilder: (context, index) {
                        final listing = listingsState.listings[index];
                        return FadeInSlide(
                          duration: 0.5,
                          delay: index * 0.1,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: RoomCard(listing: listing),
                          ),
                        );
                      },
                    ),
          ),
        ),
      ),
      floatingActionButton: FadeInSlide(
        duration: 0.5,
        delay: 0.5,
        child: FloatingActionButton.extended(
          onPressed: () {
            final user = ref.read(authProvider).user;
            if (user?.isVerified == true) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PostListingScreen()),
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
                              ),
                            );
                          },
                          child: const Text('Verify Identity'),
                        ),
                      ],
                    ),
              );
            }
          },
          label: const Text('Add Listing'),
          icon: const Icon(Icons.add),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
