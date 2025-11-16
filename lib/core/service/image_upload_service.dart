// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camp_nest/core/service/auth_service.dart';
import 'package:http/http.dart' as http;

class ImageUploadService {
  final AuthService _authService = AuthService();

  // Upload image by sending base64 payload to the backend /api/files/upload
  // Assumption: the endpoint expects JSON { "file": "<base64 string>" }
  // and returns a string (URL or path) in the response body on success.
  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final token = await _authService.getToken();
      final uri = Uri.parse('${_authService.baseUrl}/api/files/upload');

      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      // Include folder/category hint if backend supports it
      request.fields['folder'] = folder;

      final filename = imageFile.path.split(Platform.pathSeparator).last;
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      );
      request.files.add(multipartFile);

      print('Image upload POST to: $uri');
      print('Image upload request fields: '+ request.fields.toString());
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      print('Image upload POST ${resp.statusCode}: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // Server returns a plain URL string (Cloudinary controller returns plain URL)
        // Try to parse JSON or return raw body
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map && decoded.containsKey('url')) {
            return decoded['url'] as String;
          }
          if (decoded is String) return decoded;
        } catch (_) {
          return resp.body;
        }
        return resp.body;
      }

      throw Exception('Image upload failed: ${resp.statusCode} ${resp.body}');
    } catch (e) {
      print('uploadImage error: $e');
      rethrow;
    }
  }

  // Upload raw bytes (for Flutter web) via multipart
  Future<String> uploadImageBytes(Uint8List bytes, String filename, String folder) async {
    try {
      final token = await _authService.getToken();
      final uri = Uri.parse('${_authService.baseUrl}/api/files/upload');

      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields['folder'] = folder;

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      );
      request.files.add(multipartFile);

      print('Image upload (bytes) POST to: $uri');
      print('Image upload (bytes) request fields: ' + request.fields.toString());
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      print('Image upload (bytes) POST ${resp.statusCode}: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map && decoded.containsKey('url')) {
            return decoded['url'] as String;
          }
          if (decoded is String) return decoded;
        } catch (_) {
          return resp.body;
        }
        return resp.body;
      }

      throw Exception('Image upload failed: ${resp.statusCode} ${resp.body}');
    } catch (e) {
      print('uploadImageBytes error: $e');
      rethrow;
    }
  }

  // Upload multiple images sequentially and return the list of URLs
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
        results.add('/placeholder.svg?height=200&width=300');
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
        results.add('/placeholder.svg?height=200&width=300');
      }
    }
    return results;
  }

  // Test storage connection
  Future<bool> testStorageConnection() async {
    // Optionally, we could call a lightweight health endpoint. For now, assume true.
    return true;
  }

  // Delete image (optional) - depends on backend API
  Future<void> deleteImage(String imageUrl) async {
    // TODO: Implement if backend exposes a delete endpoint
  }
}
