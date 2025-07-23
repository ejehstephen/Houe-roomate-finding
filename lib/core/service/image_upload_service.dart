// ignore_for_file: avoid_print

import 'dart:io';
import 'package:camp_nest/core/utility/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Upload image to Supabase Storage
  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${userId}_${timestamp}.$extension';
      final filePath = '$folder/$fileName';

      print('Uploading image: $filePath'); // Debug log

      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      print('File size: ${bytes.length} bytes'); // Debug log

      // Upload to Supabase Storage
      final uploadResponse = await _client.storage
          .from('room-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: true,
            ),
          );

      print('Upload response: $uploadResponse'); // Debug log

      // Get public URL
      final publicUrl = _client.storage
          .from('room-images')
          .getPublicUrl(filePath);

      print('Public URL: $publicUrl'); // Debug log

      return publicUrl;
    } catch (e) {
      print('Upload error: $e'); // Debug log
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  // Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  // Upload multiple images with better error handling
  Future<List<String>> uploadMultipleImages(
    List<File> imageFiles,
    String folder,
  ) async {
    final List<String> uploadedUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        print('Uploading image ${i + 1} of ${imageFiles.length}'); // Debug log
        final url = await uploadImage(imageFiles[i], '$folder/image_$i');
        uploadedUrls.add(url);
        print('Successfully uploaded image ${i + 1}: $url'); // Debug log
      } catch (e) {
        print('Failed to upload image ${i + 1}: $e'); // Debug log
        // Continue uploading other images even if one fails
      }
    }

    return uploadedUrls;
  }

  // Test storage connection
  Future<bool> testStorageConnection() async {
    try {
      final buckets = await _client.storage.listBuckets();
      print('Available buckets: ${buckets.map((b) => b.name).toList()}');
      return buckets.any((bucket) => bucket.name == 'room-images');
    } catch (e) {
      print('Storage connection test failed: $e');
      return false;
    }
  }

  // Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('room-images');
      if (bucketIndex == -1) return;

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await _client.storage.from('room-images').remove([filePath]);
    } catch (e) {
      print('Failed to delete image: $e');
      throw Exception('Failed to delete image: ${e.toString()}');
    }
  }
}
