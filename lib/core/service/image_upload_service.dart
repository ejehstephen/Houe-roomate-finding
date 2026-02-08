// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient _client = Supabase.instance.client;

  // Upload image from file (mobile/desktop)
  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Map folder to bucket name
      final bucketName = _getBucketName(folder);

      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      final bytes = await imageFile.readAsBytes();

      await _client.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExt),
              upsert: false,
            ),
          );

      final imageUrl = _client.storage.from(bucketName).getPublicUrl(fileName);
      print('Image uploaded to Supabase: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('uploadImage error: $e');
      rethrow;
    }
  }

  // Upload image from bytes (web)
  Future<String> uploadImageBytes(
    Uint8List bytes,
    String filename,
    String folder,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final bucketName = _getBucketName(folder);

      final fileExt = filename.split('.').last.toLowerCase();
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _client.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExt),
              upsert: false,
            ),
          );

      final imageUrl = _client.storage.from(bucketName).getPublicUrl(fileName);
      print('Image (bytes) uploaded to Supabase: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('uploadImageBytes error: $e');
      rethrow;
    }
  }

  // Upload multiple images sequentially
  Future<List<String>> uploadMultipleImages(
    List<File> imageFiles,
    String folder,
  ) async {
    final results = <String>[];
    for (final f in imageFiles) {
      try {
        final url = await uploadImage(f, folder);
        results.add(url);
      } catch (e) {
        print('Failed to upload image ${f.path}: $e');
        // Use empty string or throw - don't add placeholder
        rethrow;
      }
    }
    return results;
  }

  // Upload multiple images from bytes (web)
  Future<List<String>> uploadMultipleBytes(
    List<Uint8List> images,
    List<String> filenames,
    String folder,
  ) async {
    final results = <String>[];
    for (var i = 0; i < images.length; i++) {
      try {
        final url = await uploadImageBytes(images[i], filenames[i], folder);
        results.add(url);
      } catch (e) {
        print('Failed to upload image bytes[$i]: $e');
        rethrow;
      }
    }
    return results;
  }

  // Map folder names to Supabase bucket names
  String _getBucketName(String folder) {
    switch (folder.toLowerCase()) {
      case 'profiles':
      case 'avatars':
        return 'avatars';
      case 'listings':
      case 'rooms':
        return 'listings';
      default:
        return 'listings'; // default bucket
    }
  }

  // Get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }

  // Test storage connection
  Future<bool> testStorageConnection() async {
    try {
      // Try to list files (won't fail even if empty)
      await _client.storage.from('avatars').list();
      return true;
    } catch (e) {
      print('Storage connection test failed: $e');
      return false;
    }
  }

  // Delete image
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract bucket and path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // URL format: .../storage/v1/object/public/{bucket}/{path}
      if (pathSegments.contains('object') && pathSegments.contains('public')) {
        final bucketIndex = pathSegments.indexOf('public') + 1;
        if (bucketIndex < pathSegments.length) {
          final bucket = pathSegments[bucketIndex];
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

          await _client.storage.from(bucket).remove([filePath]);
          print('Deleted image: $filePath from bucket: $bucket');
        }
      }
    } catch (e) {
      print('Delete image error: $e');
      // Don't rethrow - deletion failures are not critical
    }
  }
}
