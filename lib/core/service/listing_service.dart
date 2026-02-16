// import 'dart:io';
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
        // Use the owner's verification status from the users table
        if (map['owner']['is_verified'] == true) {
          map['is_owner_verified'] = true;
        }
      }

      return RoomListingModel.fromJson(map);
    }).toList();
  }

  // Get single listing by ID
  Future<RoomListingModel?> getListingById(String id) async {
    try {
      final response =
          await _client
              .from('room_listings')
              .select('''
            *,
            room_listing_images (images),
            room_listing_amenities (amenities),
            room_listing_rules (rules),
            owner:users!room_listings_owner_id_fkey (name, phone_number, is_verified)
          ''')
              .eq('id', id)
              .single();

      final list = _transformData([response]);
      return list.isNotEmpty ? list.first : null;
    } catch (e) {
      print('Error fetching listing by id: $e');
      return null;
    }
  }

  // Get all active listings
  Future<List<RoomListingModel>> getAllListings({
    String? school,
    int page = 0,
    int pageSize = 10,
  }) async {
    try {
      dynamic query = _client
          .from('room_listings')
          .select('''
            *,
            room_listing_images (images),
            room_listing_amenities (amenities),
            room_listing_rules (rules),
            owner:users!room_listings_owner_id_fkey (name, phone_number, is_verified)
          ''')
          .eq('is_active', true);

      if (school != null && school.trim().isNotEmpty) {
        query = query.ilike('school', '%${school.trim()}%');
      }

      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final List<RoomListingModel> listings = _transformData(response as List);

      // Sort: Verified first, then newer listings (using ID as timestamp proxy)
      listings.sort((a, b) {
        if (a.isOwnerVerified != b.isOwnerVerified) {
          return a.isOwnerVerified ? -1 : 1;
        }
        // Secondary sort: Newest first (descending ID)
        return b.id.compareTo(a.id);
      });

      return listings;
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
            owner:users!room_listings_owner_id_fkey (name, phone_number)
          ''')
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);

      final List<RoomListingModel> listings = _transformData(response as List);

      // Sort: Verified first, then newer listings
      listings.sort((a, b) {
        if (a.isOwnerVerified != b.isOwnerVerified) {
          return a.isOwnerVerified ? -1 : 1;
        }
        return b.id.compareTo(a.id);
      });

      return listings;
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
    String? query, // General search query
  }) async {
    try {
      dynamic dbQuery = _client
          .from('room_listings')
          .select('''
            *,
            room_listing_images (images),
            room_listing_amenities (amenities),
            room_listing_rules (rules),
            owner:users!room_listings_owner_id_fkey (name, phone_number, is_verified)
          ''')
          .eq('is_active', true);

      // General Text Search (Title, Description, School, Location)
      if (query != null && query.trim().isNotEmpty) {
        // Trim and collapse multiple spaces
        final q = query.trim().replaceAll(RegExp(r'\s+'), ' ');
        dbQuery = dbQuery.or(
          'title.ilike.%$q%,description.ilike.%$q%,school.ilike.%$q%,location.ilike.%$q%',
        );
      }

      if (location != null && location.trim().isNotEmpty) {
        dbQuery = dbQuery.ilike('location', '%${location.trim()}%');
      }

      if (minPrice != null) {
        dbQuery = dbQuery.gte('price', minPrice);
      }

      if (maxPrice != null) {
        dbQuery = dbQuery.lte('price', maxPrice);
      }

      if (genderPreference != null &&
          genderPreference.trim().isNotEmpty &&
          genderPreference.trim() != 'any') {
        dbQuery = dbQuery.ilike('gender_preference', genderPreference.trim());
      }

      // Filter by school if explicitly provided (e.g. user's school)
      if (school != null && school.trim().isNotEmpty) {
        dbQuery = dbQuery.ilike('school', '%${school.trim()}%');
      }

      // Handle sort
      if (sort != null) {
        dbQuery = dbQuery.order(sort, ascending: order == 'asc');
      } else {
        dbQuery = dbQuery.order('created_at', ascending: false);
      }

      // Handle pagination
      if (page != null && size != null) {
        final start = page * size;
        final end = start + size - 1;
        dbQuery = dbQuery.range(start, end);
      }

      final response = await dbQuery;
      final List<RoomListingModel> listings = _transformData(response as List);

      // Sort: Verified first, then newer listings
      listings.sort((a, b) {
        if (a.isOwnerVerified != b.isOwnerVerified) {
          return a.isOwnerVerified ? -1 : 1;
        }
        return b.id.compareTo(a.id);
      });

      return listings;
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

  // Fetch support number from app_config
  Future<String> fetchSupportNumber() async {
    try {
      final response =
          await _client
              .from('app_config')
              .select('value')
              .eq('key', 'support_whatsapp')
              .maybeSingle();

      if (response != null && response['value'] != null) {
        return response['value'] as String;
      }
      // Fallback
      return '2348134351762';
    } catch (e) {
      print('Error fetching support number: $e');
      return '2348134351762'; // Fallback
    }
  }

  // Report a listing
  Future<void> reportListing({
    required String listingId,
    required String reason,
    String? details,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Fetch the listing to get the reported_user_id (owner_id)
      final listingData =
          await _client
              .from('room_listings')
              .select('owner_id')
              .eq('id', listingId)
              .single();

      final reportedUserId = listingData['owner_id'];

      await _client.from('reports').insert({
        'reporter_id': user.id,
        'reported_listing_id': listingId,
        'reported_user_id': reportedUserId,
        'reason': reason,
        'details': details,
        'status': 'pending',
      });
    } catch (e) {
      print('Error reporting listing: $e');
      throw Exception('Failed to report listing: $e');
    }
  }

  // Request verification for a listing
  // requestVerification method removed
}
