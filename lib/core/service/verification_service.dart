import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Submit a new verification request
  Future<Map<String, dynamic>> submitVerificationRequest({
    required String fullName,
    DateTime? dateOfBirth,
    required String ninNumber,
    required String documentType,
    required XFile frontImage,
    XFile? backImage,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // 1. Upload Images to private bucket using bytes (works on web + mobile)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final frontExt = frontImage.name.split('.').last;

      // Path format: user_id/timestamp_front.jpg
      final frontPath = '$userId/${timestamp}_front.$frontExt';
      final frontBytes = await frontImage.readAsBytes();
      await _client.storage
          .from('verification_docs')
          .uploadBinary(frontPath, frontBytes);

      String? backPath;
      if (backImage != null) {
        final backExt = backImage.name.split('.').last;
        backPath = '$userId/${timestamp}_back.$backExt';
        final backBytes = await backImage.readAsBytes();
        await _client.storage
            .from('verification_docs')
            .uploadBinary(backPath, backBytes);
      }

      // 2. Insert Request Record
      // Check if a request already exists/pending?
      // For now, we allow multiple, but usually we'd check if one is pending.
      // Let's just insert a new one.

      final data = {
        'user_id': userId,
        'full_name': fullName,
        'date_of_birth': (dateOfBirth ?? DateTime.now()).toIso8601String(),
        'nin_number': ninNumber,
        'document_type': documentType,
        'front_image_url': frontPath, // Storing path, not public URL
        'back_image_url': backPath,
        'status': 'pending',
      };

      await _client.from('verification_requests').insert(data);

      return {
        'success': true,
        'message': 'Verification request submitted successfully',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to submit verification: $e'};
    }
  }

  /// Get the current verification status for the logged-in user
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {'status': 'unverified'};

      // Get the latest request
      final data =
          await _client
              .from('verification_requests')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (data == null) {
        return {'status': 'unverified'};
      }

      return {
        'status': data['status'], // pending, approved, rejected
        'rejection_reason': data['rejection_reason'],
        'submitted_at': data['created_at'],
      };
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }
}
