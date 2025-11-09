import 'dart:convert';
import 'dart:io';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/core/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class ListingsService {
  final AuthService _authService = AuthService();

  // Get all active listings from backend
  Future<List<RoomListingModel>> getListings({
    double? maxPrice,
    String? location,
    String? genderPreference,
    double? minPrice,
    int page = 0,
    int size = 10,
    String sort = 'createdAt',
    String order = 'desc',
  }) async {
    // Delegate to the search endpoint with defaults.
    return await searchListings(
      location: location,
      minPrice: minPrice,
      maxPrice: maxPrice,
      genderPreference: genderPreference,
      page: page,
      size: size,
      sort: sort,
      order: order,
    );
  }

  // Search listings with query parameters (pagination, sorting, filters)
  Future<List<RoomListingModel>> searchListings({
    String? location,
    double? minPrice,
    double? maxPrice,
    String? genderPreference,
    int page = 0,
    int size = 10,
    String sort = 'createdAt',
    String order = 'desc',
  }) async {
    final token = await _authService.getToken();
    print(
      '🔍 DEBUG searchListings: token = ${token?.substring(0, 20) ?? 'null'}...',
    );

    if (token == null) {
      print('❌ No authentication token found in searchListings');
      throw Exception('No authentication token found');
    }

    // Check if token is expired
    try {
      if (JwtDecoder.isExpired(token)) {
        print('❌ Token is expired in searchListings');
        throw Exception('Authentication token has expired');
      }
    } catch (e) {
      print('❌ Error checking token expiry: $e');
      throw Exception('Invalid authentication token');
    }

    final baseUrl = _authService.baseUrl;
    print('🌐 DEBUG: Using base URL: $baseUrl');
    final uriBase = Uri.parse('$baseUrl/api/listings/search');

    final qp = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      'sort': sort,
      'order': order,
    };
    if (location != null && location.isNotEmpty) qp['location'] = location;
    if (minPrice != null) qp['minPrice'] = minPrice.toString();
    if (maxPrice != null) qp['maxPrice'] = maxPrice.toString();
    if (genderPreference != null && genderPreference.isNotEmpty)
      qp['genderPreference'] = genderPreference;

    final uri = uriBase.replace(queryParameters: qp);
    print('📡 GET /api/listings/search uri: $uri');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    print('📋 Headers: ${headers.keys.toList()}');

    final resp = await http.get(uri, headers: headers);

    print(
      '📥 GET /api/listings/search status ${resp.statusCode}: ${resp.body}',
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) {
        print('✅ Successfully loaded ${data.length} listings from search');
        return data
            .map<RoomListingModel>((e) => RoomListingModel.fromJson(e))
            .toList();
      }
      return [];
    } else if (resp.statusCode == 403) {
      print('❌ 403 Forbidden - Authentication failed');
      print('🔍 Response body: ${resp.body}');
      throw Exception('Authentication failed (403): ${resp.body}');
    } else if (resp.statusCode == 401) {
      print('❌ 401 Unauthorized - Token invalid or expired');
      throw Exception('Token invalid or expired (401): ${resp.body}');
    }
    throw Exception('Search listings failed: ${resp.statusCode} ${resp.body}');
  }

  // Fetch all listings (no search filters) from /api/listings
  Future<List<RoomListingModel>> getAllListings() async {
    final token = await _authService.getToken();
    print(
      '🔍 DEBUG getAllListings: token = ${token?.substring(0, 20) ?? 'null'}...',
    );

    if (token == null) {
      print('❌ No authentication token found in getAllListings');
      throw Exception('No authentication token found');
    }

    // Check if token is expired
    try {
      if (JwtDecoder.isExpired(token)) {
        print('❌ Token is expired in getAllListings');
        throw Exception('Authentication token has expired');
      }
    } catch (e) {
      print('❌ Error checking token expiry: $e');
      throw Exception('Invalid authentication token');
    }

    final baseUrl = _authService.baseUrl;
    print('🌐 DEBUG: Using base URL: $baseUrl');
    final uri = Uri.parse('$baseUrl/api/listings');
    print('📡 GET /api/listings uri: $uri');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    print('📋 Headers: ${headers.keys.toList()}');

    final resp = await http.get(uri, headers: headers);
    print('📥 GET /api/listings status ${resp.statusCode}: ${resp.body}');

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) {
        print('✅ Successfully loaded ${data.length} listings');
        return data
            .map<RoomListingModel>((e) => RoomListingModel.fromJson(e))
            .toList();
      }
      return [];
    } else if (resp.statusCode == 403) {
      print('❌ 403 Forbidden - Authentication failed');
      print('🔍 Response body: ${resp.body}');
      throw Exception('Authentication failed (403): ${resp.body}');
    } else if (resp.statusCode == 401) {
      print('❌ 401 Unauthorized - Token invalid or expired');
      throw Exception('Token invalid or expired (401): ${resp.body}');
    }
    throw Exception(
      'Fetch all listings failed: ${resp.statusCode} ${resp.body}',
    );
  }

  // Create a new listing (placeholder; replace with REST call)
  Future<RoomListingModel?> createListing({
    required RoomListingModel listing,
    List<File>? files, // if provided, send multipart/form-data
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final baseUrl = _authService.baseUrl; // same base as auth

    if (files != null && files.isNotEmpty) {
      final uri = Uri.parse('$baseUrl/api/listings');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      // listing JSON part
      final payloadMap = {
        'title': listing.title,
        'description': listing.description,
        'price': listing.price,
        'location': listing.location,
        'images': listing.images,
        'mediaUrls': <String>[],
        'amenities': listing.amenities,
        'rules': listing.rules,
        'genderPreference': listing.gender,
        'availableFrom':
            listing.availableFrom.toIso8601String().split('T').first,
        'isActive': listing.isActive,
        // ownerId is taken from JWT by backend
        // send both camelCase and snake_case variants in case backend expects one
        'ownerPhone': listing.ownerPhone,
        'owner_phone': listing.ownerPhone,
        'whatsappLink': listing.whatsappLink,
        'whatsapp_link': listing.whatsappLink,
      };

      final listingPayload = jsonEncode(payloadMap);
      // final listingJson = jsonEncode(listingPayload['listing']);
      request.fields['listing'] = listingPayload;
      print(
        'POST /api/listings (multipart) payloadMap.rules: ${payloadMap['rules']}',
      );
      print('POST /api/listings (multipart) listing JSON: ' + listingPayload);

      // attach files
      for (final f in files) {
        final multipart = await http.MultipartFile.fromPath('files[]', f.path);
        request.files.add(multipart);
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      print('Response ${response.statusCode}: ' + response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RoomListingModel.fromJson(data);
      }
      throw Exception(
        'Create listing failed: ${response.statusCode} ${response.body}',
      );
    } else {
      // JSON only (URLs already available)
      final uri = Uri.parse('$baseUrl/api/listings');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final bodyMap = {
        'title': listing.title,
        'description': listing.description,
        'price': listing.price,
        'location': listing.location,
        'images': listing.images,
        'mediaUrls': <String>[],
        'amenities': listing.amenities,
        'rules': listing.rules,
        'genderPreference': listing.gender,
        'availableFrom':
            listing.availableFrom.toIso8601String().split('T').first,
        'isActive': listing.isActive,
        // include both naming conventions so backend accepts either
        'ownerPhone': listing.ownerPhone,
        'owner_phone': listing.ownerPhone,
        'whatsappLink': listing.whatsappLink,
        'whatsapp_link': listing.whatsappLink,
      };

      final body = jsonEncode(bodyMap);

      print('POST /api/listings (json) bodyMap.rules: ${bodyMap['rules']}');
      print('POST /api/listings (json) headers: $headers');
      print('POST /api/listings (json) body: $body');

      final resp = await http.post(uri, headers: headers, body: body);
      print(
        'POST /api/listings (json) status ${resp.statusCode}: ' + resp.body,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return RoomListingModel.fromJson(data);
      }
      throw Exception('Create listing failed: ${resp.statusCode} ${resp.body}');
    }
  }

  // Update a listing (placeholder; replace with REST call)
  Future<RoomListingModel> updateListing(RoomListingModel listing) async {
    // TODO: Replace with PUT /api/listings/{id}
    return listing;
  }

  // Delete a listing (placeholder; replace with REST call)
  Future<void> deleteListing(String listingId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final uri = Uri.parse('${_authService.baseUrl}/api/listings/$listingId');
    final resp = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print(
      'DELETE /api/listings/$listingId status ${resp.statusCode}: ${resp.body}',
    );
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      return;
    }

    throw Exception('Delete listing failed: ${resp.statusCode} ${resp.body}');
  }

  // Get user's listings (placeholder; replace with REST call)
  Future<List<RoomListingModel>> getUserListings(String userId) async {
    // TODO: Replace with GET /api/users/{userId}/listings
    return await getListings();
  }

  // Debug method to check token
  Future<void> debugToken() async {
    final token = await _authService.getToken();
    if (token == null) {
      print('❌ No token found');
      return;
    }

    try {
      final decoded = JwtDecoder.decode(token);
      print('🔍 Token decoded: $decoded');
      print('🔍 Token expired: ${JwtDecoder.isExpired(token)}');
    } catch (e) {
      print('❌ Error decoding token: $e');
    }
  }
}
