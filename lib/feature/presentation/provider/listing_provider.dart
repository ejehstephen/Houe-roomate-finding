// import 'dart:io';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/core/service/listing_service.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
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
  final String? _userSchool;

  ListingsNotifier(this._listingsService, this._userSchool)
    : super(ListingsState());

  Future<void> loadListings({
    double? maxPrice,
    String? location,
    String? genderPreference,
    double? minPrice,
    int page = 0,
    int size = 10,
    String sort = 'created_at',
    String order = 'desc',
    String? query, // General search query
  }) async {
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
        school: _userSchool,
        query: query,
      );
      if (!mounted) return;
      state = state.copyWith(listings: listings, isLoading: false, error: null);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addListing(RoomListingModel listing) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Debug: log rules received from UI before sending to service
      print('ListingsNotifier.addListing - listing.rules: ${listing.rules}');

      final newListing = await _listingsService.createListing(listing: listing);
      if (!mounted) return;

      if (newListing != null) {
        // ... (logic for whatsapp link fallback) ...
        String? clientWhatsapp =
            newListing.whatsappLink ?? listing.whatsappLink;
        if ((clientWhatsapp == null || clientWhatsapp.isEmpty) &&
            (newListing.ownerPhone ?? listing.ownerPhone) != null) {
          final phone = (newListing.ownerPhone ?? listing.ownerPhone)!;
          final sanitized = phone.replaceAll(RegExp(r'[\s\-()]+'), '');
          final normalized =
              sanitized.startsWith('+') ? sanitized.substring(1) : sanitized;
          clientWhatsapp =
              'https://wa.me/$normalized?text=' +
              Uri.encodeComponent(
                'Hi! I\'m interested in your room listing: "${newListing.title}".',
              );
        }

        final mergedListing = RoomListingModel(
          id: newListing.id,
          title: newListing.title,
          description: newListing.description,
          price: newListing.price,
          location: newListing.location,
          images: newListing.images,
          ownerId: newListing.ownerId,
          ownerName: newListing.ownerName,
          ownerPhone: newListing.ownerPhone ?? listing.ownerPhone,
          whatsappLink:
              newListing.whatsappLink ?? listing.whatsappLink ?? clientWhatsapp,
          amenities:
              newListing.amenities.isNotEmpty
                  ? newListing.amenities
                  : listing.amenities,
          rules:
              (newListing.rules.isNotEmpty) ? newListing.rules : listing.rules,
          gender: newListing.gender,
          availableFrom: newListing.availableFrom,
          isActive: newListing.isActive,
          school: newListing.school,
        );

        // Prepend the new listing so it appears at the top of the list immediately
        state = state.copyWith(
          listings: [mergedListing, ...state.listings],
          isLoading: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow; // Re-throw so the UI can handle it
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
      // don't persist the error into global listings state (that hides the list);
      // let callers handle the error so they can show context-appropriate UI.
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  // Load all listings (no search filters)
  Future<void> loadAllListings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final listings = await _listingsService.getAllListings(
        school: _userSchool,
      );
      if (!mounted) return;
      state = state.copyWith(listings: listings, isLoading: false, error: null);
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

  // requestVerification method removed

  Future<String> getSupportNumber() => _listingsService.fetchSupportNumber();
}

// Providers
final listingsServiceProvider = Provider<ListingsService>(
  (ref) => ListingsService(),
);

final listingsProvider = StateNotifierProvider<ListingsNotifier, ListingsState>(
  (ref) {
    final authState = ref.watch(authProvider);
    return ListingsNotifier(
      ref.read(listingsServiceProvider),
      authState.user?.school,
    );
  },
);

final searchListingsProvider =
    StateNotifierProvider.autoDispose<ListingsNotifier, ListingsState>((ref) {
      final authState = ref.watch(authProvider);
      return ListingsNotifier(
        ref.read(listingsServiceProvider),
        authState.user?.school,
      );
    });
