import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/core/service/listing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListingsState {
  final List<RoomListingModel> listings;
  final bool isLoading;
  final String? error;

  ListingsState({this.listings = const [], this.isLoading = false, this.error});

  ListingsState copyWith({
    List<RoomListingModel>? listings,
    bool? isLoading,
    String? error,
  }) {
    return ListingsState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ListingsNotifier extends StateNotifier<ListingsState> {
  final ListingsService _listingsService;

  ListingsNotifier(this._listingsService) : super(ListingsState()) {
    // Auto-fetch all listings when provider is created
    loadAllListings();
  }

  /// The user's school, passed in when calling loadAllListings or loadListings.
  /// We read it at call time, NOT at construction time, so the provider
  /// doesn't need to be recreated when auth state changes.
  String? _resolveSchool;

  /// Set the school filter for future loads (called once from HomeScreen)
  void setSchool(String? school) {
    _resolveSchool = school;
  }

  Future<void> loadListings({
    double? maxPrice,
    String? location,
    String? genderPreference,
    double? minPrice,
    int page = 0,
    int size = 10,
    String sort = 'created_at',
    String order = 'desc',
    String? query,
    bool force = false,
  }) async {
    if (!force && state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final listings = await _listingsService.searchListings(
        location: location,
        minPrice: minPrice,
        maxPrice: maxPrice,
        genderPreference: genderPreference,
        page: page,
        size: size,
        sort: sort,
        order: order,
        school: _resolveSchool,
        query: query,
      );
      if (!mounted) return;

      if (page == 0) {
        state = state.copyWith(
          listings: listings,
          isLoading: false, // Ensure loading is false
          error: null,
        );
      } else {
        state = state.copyWith(
          listings: [...state.listings, ...listings],
          isLoading: false, // Ensure loading is false
          error: null,
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addListing(RoomListingModel listing) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('ListingsNotifier.addListing - listing.rules: ${listing.rules}');

      await _listingsService.createListing(listing: listing);
      if (!mounted) return;

      // After posting, refetch ALL listings from the database so the user
      // sees everyone's listings (not just their own).
      await loadAllListings(force: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> updateListing(RoomListingModel listing) async {
    try {
      final updatedListing = await _listingsService.updateListing(listing);
      if (!mounted) return;

      if (updatedListing != null) {
        final updatedListings =
            state.listings.map((l) {
              return l.id == updatedListing.id ? updatedListing : l;
            }).toList();

        state = state.copyWith(listings: updatedListings);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteListing(String listingId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _listingsService.deleteListing(listingId);
      if (!mounted) return;

      final updatedListings =
          state.listings.where((l) => l.id != listingId).toList();
      state = state.copyWith(listings: updatedListings, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  // Load all listings (no search filters)
  Future<void> loadAllListings({
    bool force = false,
    int page = 0,
    int pageSize = 10,
  }) async {
    // Don't reload if we're already loading
    if (!force && state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Try to fetch user's school listings
      var listings = await _listingsService.getAllListings(
        school: _resolveSchool,
        page: page,
        pageSize: pageSize,
      );

      // 2. If no listings found for school, fetch ALL listings (fallback)
      if (listings.isEmpty &&
          page == 0 &&
          _resolveSchool != null &&
          _resolveSchool!.isNotEmpty) {
        print(
          'INFO: No listings found for $_resolveSchool. Fetching all listings.',
        );
        listings = await _listingsService.getAllListings(
          page: page,
          pageSize: pageSize,
        );
      }

      if (!mounted) return;

      if (page == 0) {
        state = state.copyWith(
          listings: listings,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          listings: [...state.listings, ...listings],
          isLoading: false,
          error: null,
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Load only listings owned by the current user
  Future<void> loadMyListings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final listings = await _listingsService.getMyListings();
      if (!mounted) return;
      state = state.copyWith(listings: listings, isLoading: false, error: null);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  List<RoomListingModel> filterListings({
    double? maxPrice,
    String? location,
    String? gender,
  }) {
    return state.listings.where((listing) {
      if (maxPrice != null && listing.price > maxPrice) return false;
      if (location != null &&
          !listing.location.toLowerCase().contains(location.toLowerCase()))
        return false;
      if (gender != null && listing.gender != 'any' && listing.gender != gender)
        return false;
      return true;
    }).toList();
  }

  Future<void> reportListing({
    required String listingId,
    required String reason,
    String? details,
  }) async {
    try {
      await _listingsService.reportListing(
        listingId: listingId,
        reason: reason,
        details: details,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getSupportNumber() => _listingsService.fetchSupportNumber();
}

// Providers
final listingsServiceProvider = Provider<ListingsService>(
  (ref) => ListingsService(),
);

/// This provider is NOT dependent on authProvider, so it will NOT be
/// destroyed/recreated when auth state changes. The school filter is
/// set manually via setSchool() from the HomeScreen.
final listingsProvider = StateNotifierProvider<ListingsNotifier, ListingsState>(
  (ref) {
    return ListingsNotifier(ref.read(listingsServiceProvider));
  },
);

final searchListingsProvider =
    StateNotifierProvider.autoDispose<ListingsNotifier, ListingsState>((ref) {
      return ListingsNotifier(ref.read(listingsServiceProvider));
    });
