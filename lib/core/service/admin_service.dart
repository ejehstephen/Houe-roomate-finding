import 'package:camp_nest/core/model/report_model.dart';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/core/model/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Stats ---
  Future<Map<String, int>> getPlatformStats() async {
    try {
      final response = await _client.rpc('admin_get_stats');
      return Map<String, int>.from(response as Map);
    } catch (e) {
      print('Error getting stats: $e');
      throw Exception('Failed to get stats');
    }
  }

  // --- Users ---
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response =
          await _client
                  .from('users')
                  .select()
                  .order('created_at', ascending: false)
              as List;
      return response.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      print('Error getting users: $e');
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> banUser(String userId) async {
    try {
      await _client.rpc('admin_ban_user', params: {'target_user_id': userId});

      // Notify user
      await sendNotification(
        userId,
        'Account Suspended',
        'Your account has been suspended for violating community guidelines. Please contact support if you believe this is an error.',
      );
    } catch (e) {
      print('Error banning user: $e');
      throw Exception('Failed to ban user');
    }
  }

  Future<void> unbanUser(String userId) async {
    try {
      await _client.rpc('admin_unban_user', params: {'target_user_id': userId});

      // Notify user
      await sendNotification(
        userId,
        'Account Restored',
        'Your account has been restored. You can now access all features again.',
      );
    } catch (e) {
      print('Error unbanning user: $e');
      throw Exception('Failed to unban user');
    }
  }

  Future<void> verifyUser(String userId) async {
    try {
      await _client.rpc(
        'admin_verify_user',
        params: {'target_user_id': userId},
      );
    } catch (e) {
      print('Error verifying user: $e');
      throw Exception('Failed to verify user');
    }
  }

  // --- Listings ---
  Future<List<RoomListingModel>> getAllListings() async {
    try {
      final response =
          await _client
                  .from('room_listings')
                  .select('''
            *,
            room_listing_images (images),
            room_listing_amenities (amenities),
            room_listing_rules (rules),
            owner:users!room_listings_owner_id_fkey (name, phone_number)
          ''')
                  .order('created_at', ascending: false)
              as List;

      // We need to transform data similarly to ListingService,
      // but simpler since we just need basic info for admin usually.
      // Reusing ListingService login or copying transformation is best.
      // For now, let's assume standard transformation or simple mapping.
      // Only Issue: The join returns nested objects. ListingService handles this.
      // We should probably rely on ListingService for fetching or duplicate the logic.
      // Duplicating for robustness.

      return response.map((json) {
        final map = Map<String, dynamic>.from(json);
        if (map['room_listing_images'] is List) {
          map['images'] =
              (map['room_listing_images'] as List)
                  .map((e) => e['images']?.toString() ?? '')
                  .toList();
        }
        if (map['room_listing_amenities'] is List) {
          map['amenities'] =
              (map['room_listing_amenities'] as List)
                  .map((e) => e['amenities']?.toString() ?? '')
                  .toList();
        }
        if (map['room_listing_rules'] is List) {
          map['rules'] =
              (map['room_listing_rules'] as List)
                  .map((e) => e['rules']?.toString() ?? '')
                  .toList();
        }
        // Extract owner info
        if (map['owner'] != null) {
          map['ownerName'] = map['owner']['name'];
          map['ownerPhone'] = map['owner']['phone_number'];
        }
        return RoomListingModel.fromJson(map);
      }).toList();
    } catch (e) {
      print('Error getting listings: $e');
      throw Exception('Failed to fetch listings');
    }
  }

  Future<void> deleteListing(String listingId) async {
    try {
      await _client.rpc(
        'admin_delete_listing',
        params: {'target_listing_id': listingId},
      );
    } catch (e) {
      print('Error deleting listing: $e');
      throw Exception('Failed to delete listing');
    }
  }

  Future<void> featureListing(String listingId) async {
    try {
      await _client.rpc(
        'admin_feature_listing',
        params: {'target_listing_id': listingId},
      );
    } catch (e) {
      print('Error featuring listing: $e');
      throw Exception('Failed to feature listing');
    }
  }

  // --- Reports ---
  Future<List<ReportModel>> getAllReports() async {
    try {
      final response =
          await _client
                  .from('reports')
                  .select('''
            *,
            reporter:users!reports_reporter_id_fkey(name),
            reported_user:users!reports_reported_user_id_fkey(name),
            reported_listing:room_listings!reports_reported_listing_id_fkey(title)
          ''')
                  .order('created_at', ascending: false)
              as List;
      return response.map((e) {
        final map = Map<String, dynamic>.from(e);

        // Extract nested names/titles
        if (map['reporter'] != null) {
          map['reporter_name'] = map['reporter']['name'];
        }
        if (map['reported_user'] != null) {
          map['reported_user_name'] = map['reported_user']['name'];
        }
        if (map['reported_listing'] != null) {
          map['reported_listing_title'] = map['reported_listing']['title'];
        }

        return ReportModel.fromJson(map);
      }).toList();
    } catch (e) {
      print('Error getting reports: $e');
      throw Exception('Failed to fetch reports');
    }
  }

  Future<void> resolveReport(String reportId, String status) async {
    try {
      await _client
          .from('reports')
          .update({'status': status})
          .eq('id', reportId);
    } catch (e) {
      print('Error resolving report: $e');
      throw Exception('Failed to resolve report');
    }
  }

  // --- Notifications ---
  Future<void> sendNotification(
    String userId,
    String title,
    String message,
  ) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': message,
        'type': 'system', // or 'admin'
        'is_read': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
      throw Exception('Failed to send notification');
    }
  }

  Future<void> broadcastNotification(String title, String message) async {
    try {
      // NOTE: Using the RPC we created, or direct insert if preferred/possible
      await _client.rpc(
        'admin_broadcast_notification',
        params: {'title': title, 'body': message},
      );
    } catch (e) {
      print('Error broadcasting notification: $e');
      throw Exception('Failed to broadcast notification');
    }
  }

  // --- Verifications ---
  Future<List<Map<String, dynamic>>> getPendingVerifications() async {
    try {
      final response = await _client
          .from('verification_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting pending verifications: $e');
      throw Exception('Failed to fetch pending verifications');
    }
  }

  Future<void> approveVerification(String requestId) async {
    try {
      // 1. Update request status
      final response =
          await _client
              .from('verification_requests')
              .update({'status': 'approved'})
              .eq('id', requestId)
              .select()
              .single();

      final userId = response['user_id'];

      // 2. Update user's is_verified status via RPC (bypasses RLS)
      await verifyUser(userId);

      // 3. Notify user
      await sendNotification(
        userId,
        'Identity Verified',
        'Your identity has been successfully verified! You can now post listings.',
      );
    } catch (e) {
      print('Error approving verification: $e');
      throw Exception('Failed to approve verification');
    }
  }

  Future<void> rejectVerification(String requestId, String reason) async {
    try {
      // 1. Update request status
      final response =
          await _client
              .from('verification_requests')
              .update({'status': 'rejected', 'rejection_reason': reason})
              .eq('id', requestId)
              .select()
              .single();

      final userId = response['user_id'];

      // 2. Notify user
      await sendNotification(
        userId,
        'Verification Rejected',
        'Your identity verification was rejected. Reason: $reason',
      );
    } catch (e) {
      print('Error rejecting verification: $e');
      throw Exception('Failed to reject verification');
    }
  }

  Future<String> getSignedUrl(String path) async {
    try {
      // Generate a signed URL valid for 1 hour
      final signedUrl = await _client.storage
          .from('verification_docs')
          .createSignedUrl(path, 3600);
      return signedUrl;
    } catch (e) {
      print('Error generating signed URL: $e');
      throw Exception('Failed to generate signed URL');
    }
  }
}
