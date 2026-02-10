import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:camp_nest/feature/presentation/widget/roomcard.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  // Price slider bounds
  final double _priceMin = 0; // Changed to allow 0
  final double _priceMax = 2000;
  double _maxPrice = 2000;
  String _selectedGender = 'any';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  void _applyFilters() {
    // Call the provider to load listings with current filters
    ref
        .read(searchListingsProvider.notifier)
        .loadListings(
          maxPrice: _maxPrice < _priceMax ? _maxPrice : null,
          query: _searchQuery.isNotEmpty ? _searchQuery : null,
          genderPreference: _selectedGender != 'any' ? _selectedGender : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider for changes
    final listingsState = ref.watch(searchListingsProvider);
    final _isLoading = listingsState.isLoading;
    final _filteredListings = listingsState.listings; // Using real data

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isTablet = w >= 600 && w < 1024;
          final isDesktop = w >= 1024;
          final horizontalPadding =
              isDesktop
                  ? 24.0
                  : isTablet
                  ? 20.0
                  : 16.0;
          const maxContentWidth = 1200.0;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: CustomScrollView(
                    scrollDirection: Axis.vertical,
                    slivers: [
                      // App Bar
                      SliverAppBar(
                        // leading: BackButton(),
                        title: Text(
                          'Room Listings',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        floating: true,
                        snap: true,
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        actions: [
                          IconButton(
                            onPressed: _showFilters,
                            icon: const Icon(Icons.filter_list_rounded),
                          ),
                          IconButton(
                            onPressed: _applyFilters,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),

                      // Search bar
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverToBoxAdapter(
                          child: FadeInSlide(
                            duration: 0.5,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText:
                                    'Search by title, school, location...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon:
                                    _searchQuery.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _searchQuery = '';
                                              _applyFilters();
                                            });
                                          },
                                        )
                                        : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                        ),
                      ),

                      // Listings content
                      if (_isLoading)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_filteredListings.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: FadeInSlide(
                              duration: 0.5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.home_work_outlined,
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
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _maxPrice = 2000;
                                        _selectedGender = 'any';
                                        _searchQuery = '';
                                        _applyFilters();
                                      });
                                    },
                                    child: const Text('Clear Filters'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: FadeInSlide(
                                  duration: 0.5,
                                  delay: index * 0.1,
                                  child: RoomCard(
                                    listing: _filteredListings[index],
                                  ),
                                ),
                              );
                            }, childCount: _filteredListings.length),
                          ),
                        ),

                      // Bottom padding for FAB
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 100),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Filters',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Max Price: ${_maxPrice >= _priceMax ? 'No max' : '\$${_maxPrice.round()}'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: _maxPrice,
                        min: _priceMin,
                        max: _priceMax,
                        divisions: 20,
                        onChanged: (value) {
                          setModalState(() {
                            _maxPrice = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Gender Preference',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children:
                            ['any', 'male', 'female'].map((gender) {
                              final isSelected = _selectedGender == gender;
                              return FilterChip(
                                label: Text(
                                  gender == 'any'
                                      ? 'Any'
                                      : gender.toUpperCase(),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() {
                                      _selectedGender = gender;
                                    });
                                  }
                                },
                                selectedColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.2),
                                checkmarkColor: Theme.of(context).primaryColor,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected
                                          ? Theme.of(context).primaryColor
                                          : null,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  _maxPrice = 2000;
                                  _selectedGender = 'any';
                                  _searchQuery = '';
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _maxPrice = _maxPrice;
                                  _selectedGender = _selectedGender;
                                });
                                _applyFilters();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Apply Filters'),
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
