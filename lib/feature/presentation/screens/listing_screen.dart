import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:camp_nest/feature/presentation/screens/post_listing_screen.dart';
import 'package:camp_nest/feature/presentation/widget/roomcard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  double _maxPrice = 1000;
  String _selectedGender = 'any';
  String _searchLocation = '';

  @override
  Widget build(BuildContext context) {
    final listingsState = ref.watch(listingsProvider);
    final filteredListings = ref
        .read(listingsProvider.notifier)
        .filterListings(
          maxPrice: _maxPrice,
          gender: _selectedGender == 'any' ? null : _selectedGender,
          location: _searchLocation.isEmpty ? null : _searchLocation,
        );

    return Scaffold(
      // appBar: AppBar(leading: BackButton()),
      body: CustomScrollView(
        scrollDirection: Axis.vertical,
        slivers: [
          // App Bar
          SliverAppBar(
            // leading: BackButton(),
            title: const Text('Room Listings'),
            floating: true,
            snap: true,
            actions: [
              IconButton(
                onPressed: _showFilters,
                icon: const Icon(Icons.filter_list),
              ),
              IconButton(
                onPressed:
                    () => ref.read(listingsProvider.notifier).loadListings(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          // Search bar
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by location...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchLocation = value;
                  });
                },
              ),
            ),
          ),

          // Listings content
          if (listingsState.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (listingsState.error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${listingsState.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          () =>
                              ref
                                  .read(listingsProvider.notifier)
                                  .loadListings(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredListings.isEmpty)
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RoomCard(listing: filteredListings[index]),
                  );
                }, childCount: filteredListings.length),
              ),
            ),

          // Bottom padding for FAB
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),

      // Floating Action Button for post creation
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PostListingScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Post Room'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text('Max Price: \$${_maxPrice.round()}'),
                      Slider(
                        value: _maxPrice,
                        min: 200,
                        max: 1500,
                        divisions: 26,
                        onChanged: (value) {
                          setModalState(() {
                            _maxPrice = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      const Text('Gender Preference'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            ['any', 'male', 'female'].map((gender) {
                              return ChoiceChip(
                                label: Text(
                                  gender == 'any'
                                      ? 'Any'
                                      : gender.toUpperCase(),
                                ),
                                selected: _selectedGender == gender,
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() {
                                      _selectedGender = gender;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  _maxPrice = 1000;
                                  _selectedGender = 'any';
                                  _searchLocation = '';
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {});
                                Navigator.pop(context);
                              },
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),

                      // Add bottom padding for safe area
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
          ),
    );
  }
}
