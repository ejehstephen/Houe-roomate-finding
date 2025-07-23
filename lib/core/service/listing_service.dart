import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/core/utility/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListingsService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get all active listings
  Future<List<RoomListingModel>> getListings({
    double? maxPrice,
    String? location,
    String? genderPreference,
  }) async {
    try {
      var query = _client
          .from('room_listings')
          .select('''
          *,
          user_profiles!room_listings_owner_id_fkey(name)
        ''')
          .eq('is_active', true);

      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      if (location != null && location.isNotEmpty) {
        query = query.ilike('location', '%$location%');
      }

      if (genderPreference != null && genderPreference != 'any') {
        query = query.or(
          'gender_preference.eq.any,gender_preference.eq.$genderPreference',
        );
      }

      final response = await query.order('created_at', ascending: false);

      return response.map<RoomListingModel>((json) {
        // Add owner name from the joined user_profiles table
        json['ownerName'] = json['user_profiles']['name'];
        return RoomListingModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get listings: ${e.toString()}');
    }
  }

  // Create a new listing
  Future<RoomListingModel> createListing(RoomListingModel listing) async {
    try {
      final response =
          await _client
              .from('room_listings')
              .insert({
                'title': listing.title,
                'description': listing.description,
                'price': listing.price,
                'location': listing.location,
                'images': listing.images,
                'owner_id': _client.auth.currentUser!.id,
                'amenities': listing.amenities,
                'rules': listing.rules,
                'gender_preference': listing.gender,
                'available_from': listing.availableFrom.toIso8601String(),
              })
              .select()
              .single();

      return RoomListingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create listing: ${e.toString()}');
    }
  }

  // Update a listing
  Future<RoomListingModel> updateListing(RoomListingModel listing) async {
    try {
      final response =
          await _client
              .from('room_listings')
              .update({
                'title': listing.title,
                'description': listing.description,
                'price': listing.price,
                'location': listing.location,
                'images': listing.images,
                'amenities': listing.amenities,
                'rules': listing.rules,
                'gender_preference': listing.gender,
                'available_from': listing.availableFrom.toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', listing.id)
              .select()
              .single();

      return RoomListingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update listing: ${e.toString()}');
    }
  }

  // Delete a listing
  Future<void> deleteListing(String listingId) async {
    try {
      await _client.from('room_listings').delete().eq('id', listingId);
    } catch (e) {
      throw Exception('Failed to delete listing: ${e.toString()}');
    }
  }

  // Get user's listings
  Future<List<RoomListingModel>> getUserListings(String userId) async {
    try {
      final response = await _client
          .from('room_listings')
          .select('''
            *,
            user_profiles!room_listings_owner_id_fkey(name)
          ''')
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      return response.map<RoomListingModel>((json) {
        json['ownerName'] = json['user_profiles']['name'];
        return RoomListingModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user listings: ${e.toString()}');
    }
  }
}
