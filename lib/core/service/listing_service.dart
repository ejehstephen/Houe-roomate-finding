import 'dart:io';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListingsService {
  final SupabaseClient _client = Supabase.instance.client;

  // Transform Supabase response to match RoomListingModel structure
  List<RoomListingModel> _transformData(List<dynamic> data) {
    return data.map((json) {
      final map = Map<String, dynamic>.from(json);

      // Transform nested relations (which come as list of objects) into flat lists of strings

      // Images
      if (map['room_listing_images'] is List) {
        map['images'] =
            (map['room_listing_images'] as List)
                .map((e) => e['images']?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
      }

      // Amenities
      if (map['room_listing_amenities'] is List) {
        map['amenities'] =
            (map['room_listing_amenities'] as List)
                .map((e) => e['amenities']?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
      }

      // Rules
      if (map['room_listing_rules'] is List) {
        map['rules'] =
            (map['room_listing_rules'] as List)
                .map((e) => e['rules']?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
      }

      // Owner info (if joined)
      if (map['owner'] != null) {
        map['ownerName'] = map['owner']['name'];
        map['ownerPhone'] = map['owner']['phone_number'];
      }

      return RoomListingModel.fromJson(map);
    }).toList();
  }

  // Get all active listings
  Future<List<RoomListingModel>> getAllListings({String? school}) async {
    try {
      dynamic query = _client
          .from('room_listings')
          .select('''
            *,
            room_listing_images (images),
            room_listing_amenities (amenities),
            room_listing_rules (rules),
            owner:users!inner (name, phone_number)
          ''')
          .eq('is_active', true);

      if (school != null && school.isNotEmpty) {
        query = query.eq('school', school);
      }

      final response = await query.order('created_at', ascending: false);

      return _transformData(response as List);
    } catch (e) {
      print('Error fetching listings: $e');
      throw Exception('Failed to fetch listings');
    }
  }

  /// Fetch listings owned by the current user
  Future<List<RoomListingModel>> getMyListings() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final response = await _client
          .from('room_listings')
          .select('''
            *,
            room_listing_images (images),
            room_listing_amenities (amenities),
            room_listing_rules (rules),
            owner:users!inner (name, phone_number)
          ''')
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);

      return _transformData(response as List);
    } catch (e) {
      print('Error fetching my listings: $e');
      throw Exception('Failed to fetch my listings');
    }
  }

  // Search listings with filters
  Future<List<RoomListingModel>> searchListings({
    String? location,
    double? minPrice,
    double? maxPrice,
    String? genderPreference,
    int? page,
    int? size,
    String? sort,
    String? order,
    String? school,
  }) async {
    try {
      dynamic query = _client
          .from('room_listings')
          .select('''
            *,
            room_listing_images (images),
            room_listing_amenities (amenities),
            room_listing_rules (rules),
            owner:users!inner (name, phone_number)
          ''')
          .eq('is_active', true);

      if (location != null && location.isNotEmpty) {
        query = query.ilike('location', '%$location%');
      }

      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }

      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      if (genderPreference != null &&
          genderPreference.isNotEmpty &&
          genderPreference != 'any') {
        query = query.eq('gender_preference', genderPreference);
      }

      if (school != null && school.isNotEmpty) {
        query = query.eq('school', school);
      }

      // Handle sort
      if (sort != null) {
        query = query.order(sort, ascending: order == 'asc');
      } else {
        query = query.order('created_at', ascending: false);
      }

      // Handle pagination
      if (page != null && size != null) {
        final start = page * size;
        final end = start + size - 1;
        query = query.range(start, end);
      }

      final response = await query;
      return _transformData(response as List);
    } catch (e) {
      print('Error searching listings: $e');
      return [];
    }
  }

  // Create a new listing
  Future<RoomListingModel?> createListing({
    required RoomListingModel listing,
    List<File>? files,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // 1. Upload Images
      List<String> imageUrls = [];
      if (files != null) {
        for (var file in files) {
          final ext = file.path.split('.').last;
          final path =
              '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
          await _client.storage.from('listing-images').upload(path, file);
          final url = _client.storage.from('listing-images').getPublicUrl(path);
          imageUrls.add(url);
        }
      } else {
        imageUrls = listing.images;
      }

      // 2. Insert Core Listing
      final listingData = listing.toJson();
      listingData['owner_id'] = user.id;
      // Remove these fields as they are in separate tables or not column names
      listingData.remove('id');
      listingData.remove('images');
      listingData.remove('amenities');
      listingData.remove('rules');
      listingData.remove('owner_name');
      listingData.remove('ownerPhone');
      listingData.remove('whatsappLink');

      final response =
          await _client
              .from('room_listings')
              .insert(listingData)
              .select()
              .single();

      final newId = response['id'];

      // 3. Insert Relations
      // Images
      if (imageUrls.isNotEmpty) {
        await _client
            .from('room_listing_images')
            .insert(
              imageUrls
                  .map((url) => {'room_listing_id': newId, 'images': url})
                  .toList(),
            );
      }

      // Amenities
      if (listing.amenities.isNotEmpty) {
        await _client
            .from('room_listing_amenities')
            .insert(
              listing.amenities
                  .map((item) => {'room_listing_id': newId, 'amenities': item})
                  .toList(),
            );
      }

      // Rules
      if (listing.rules.isNotEmpty) {
        await _client
            .from('room_listing_rules')
            .insert(
              listing.rules
                  .map((item) => {'room_listing_id': newId, 'rules': item})
                  .toList(),
            );
      }

      return listing; // Should ideally return refetched object
    } catch (e) {
      print('Error creating listing: $e');
      throw Exception('Create listing failed: $e');
    }
  }

  // Update a listing
  Future<RoomListingModel?> updateListing(RoomListingModel listing) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Update core data
      final updates = listing.toJson();
      // Remove relation fields and id
      updates.remove('id');
      updates.remove('images');
      updates.remove('amenities');
      updates.remove('rules');
      updates.remove('owner_name');
      updates.remove('ownerPhone');
      updates.remove('whatsappLink');

      await _client
          .from('room_listings')
          .update(updates)
          .eq('id', listing.id)
          .eq('owner_id', user.id); // Security check

      // Handle relations? (Complex: you delete old, insert new)
      // For migration MVP, we might skip complex relation updates or implement straightforward logic
      // e.g. delete all amenities for this listing and re-insert.

      return listing;
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  // Delete a listing
  Future<void> deleteListing(String id) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await _client
          .from('room_listings')
          .delete()
          .eq('id', id)
          .eq('owner_id', user.id);
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }
}
