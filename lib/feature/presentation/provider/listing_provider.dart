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

  ListingsNotifier(this._listingsService) : super(ListingsState());

  Future<void> loadListings({
    double? maxPrice,
    String? location,
    String? genderPreference,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final listings = await _listingsService.getListings(
        maxPrice: maxPrice,
        location: location,
        genderPreference: genderPreference,
      );
      state = state.copyWith(listings: listings, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addListing(RoomListingModel listing) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newListing = await _listingsService.createListing(listing);
      state = state.copyWith(
        listings: [...state.listings, newListing],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow; // Re-throw so the UI can handle it
    }
  }

  Future<void> updateListing(RoomListingModel listing) async {
    try {
      final updatedListing = await _listingsService.updateListing(listing);
      final updatedListings =
          state.listings.map((l) {
            return l.id == updatedListing.id ? updatedListing : l;
          }).toList();

      state = state.copyWith(listings: updatedListings);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteListing(String listingId) async {
    try {
      await _listingsService.deleteListing(listingId);
      final updatedListings =
          state.listings.where((l) => l.id != listingId).toList();
      state = state.copyWith(listings: updatedListings);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
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
}

// Providers
final listingsServiceProvider = Provider<ListingsService>(
  (ref) => ListingsService(),
);

final listingsProvider = StateNotifierProvider<ListingsNotifier, ListingsState>(
  (ref) {
    return ListingsNotifier(ref.read(listingsServiceProvider));
  },
);
