import 'dart:convert';
import 'dart:io';
import 'package:camp_nest/core/model/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';
  String get baseUrl => _baseUrl;

  // Helper to safely truncate strings for logging
  String _safeTruncate(String? str, int maxLength) {
    if (str == null) return 'null';
    return str.length > maxLength ? '${str.substring(0, maxLength)}...' : str;
  }

  // ========================= TOKEN MANAGEMENT =========================
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print(
      '🔍 DEBUG: getToken() returning: ${token?.substring(0, 20) ?? 'null'}...',
    );
    return token;
  }

  Future<void> _storeToken(String token) async {
    print('💾 DEBUG: Storing token: ${token.substring(0, 20)}...');
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(_tokenKey, token);
    print('💾 DEBUG: Token storage success: $success');
  }

  Future<void> _clearStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ========================= USER STORAGE =========================
  Future<void> _storeUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_userKey);
    if (jsonStr != null) {
      return UserModel.fromJson(jsonDecode(jsonStr));
    }
    return null;
  }

  Future<UserModel?> setProfileImage(String imageUrl) async {
    final current = await getStoredUser();
    if (current == null) return null;

    final updated = current.copyWith(profileImage: imageUrl);
    await _storeUser(updated);
    return updated;
  }

  // Upload profile image
  Future<String> uploadProfileImage(File imageFile) async {
    final token = await getToken();
    if (token == null) throw Exception('No authentication token found');

    final bytes = await imageFile.readAsBytes();
    final base64File = base64Encode(bytes);

    final resp = await http.post(
      Uri.parse('$_baseUrl/api/users/profile/upload'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'file': base64File}),
    );

    if (resp.statusCode == 200) {
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map && decoded['url'] is String) {
          return decoded['url'] as String;
        }
        if (decoded is String) return decoded;
      } catch (_) {}
      return resp.body;
    }
    throw Exception('Profile upload failed: ${resp.statusCode} ${resp.body}');
  }

  // ========================= JWT DECODING =========================
  String? _getUserIdFromToken(String token) {
    try {
      final decoded = JwtDecoder.decode(token);
      final userId = decoded['sub']?.toString();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (e) {
      print('❌ Error decoding JWT token: $e');
      return null;
    }
  }

  // ========================= AUTH OPERATIONS =========================

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String school,
    required int age,
    required String gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'school': school,
          'age': age,
          'gender': gender,
          'phoneNumber': null, // keep if optional
        }),
      );

      // Successful response (status code 200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);

          Map<String, dynamic>? userData;
          if (data['user'] != null && data['user'] is Map<String, dynamic>) {
            userData = data['user'] as Map<String, dynamic>;
          }

          return {
            'success': true,
            'message': data['message'] ?? 'Registration successful!',
            'token': data['token'] as String? ?? '',
            'user': userData != null ? UserModel.fromJson(userData) : null,
          };
        } on FormatException {
          return {
            'success': false,
            'error':
                'Failed to parse server response. Received: ${response.body}',
          };
        }
      } else {
        // Server error (status code 400+)
        String errorMessage =
            'Registration failed with status code: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData['message'] != null) {
            errorMessage = errorData['message'] as String;
          }
        } on FormatException {
          // Non-JSON error fallback
        }
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      // Network or unknown errors
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    print('🔐 DEBUG: Starting signIn process for email: $email');
    print('🌐 DEBUG: API_BASE_URL from env: ${dotenv.env['API_BASE_URL']}');
    print('🌐 DEBUG: Using base URL: $_baseUrl');

    final loginUrl = '$_baseUrl/auth/login';
    print('📡 DEBUG: Full login URL: $loginUrl');

    final requestBody = {'email': email, 'password': password};
    final headers = {
      'Content-Type': 'application/json',
      // Add ngrok bypass header if using ngrok
      if (loginUrl.contains('ngrok')) 'ngrok-skip-browser-warning': 'true',
    };

    print('📋 DEBUG: Request headers: $headers');
    print('📤 DEBUG: Request body: $requestBody');
    print('📤 DEBUG: Request body JSON: ${jsonEncode(requestBody)}');

    try {
      final response = await http
          .post(
            Uri.parse(loginUrl),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30)); // Increased timeout

      print('📥 DEBUG: Login response status: ${response.statusCode}');
      print('📥 DEBUG: Login response headers: ${response.headers}');
      print('📥 DEBUG: Login response body: ${response.body}');

      // Verify we're hitting the correct domain
      final responseUrl = response.request?.url.toString();
      print('🔍 DEBUG: Actual request URL used: $responseUrl');

      if (!responseUrl!.contains('camp-backend-27sb.onrender.com')) {
        print('❌ WARNING: Request was NOT sent to Render backend!');
        print('❌ Expected: https://camp-backend-27sb.onrender.com');
        print('❌ Actual: $responseUrl');
      } else {
        print('✅ Confirmed: Request sent to correct Render backend');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String?;

        if (token == null || token.isEmpty) {
          print('❌ DEBUG: Token is null or empty in response');
          return {'success': false, 'error': 'No token received from server'};
        }

        print('✅ DEBUG: Token received: ${token.substring(0, 20)}...');

        // Store the token
        await _storeToken(token);
        print('✅ DEBUG: Token stored in SharedPreferences');

        // Verify token was stored
        final storedToken = await getToken();
        if (storedToken == null) {
          print('❌ DEBUG: Token was not stored properly!');
          return {
            'success': false,
            'error': 'Failed to store authentication token',
          };
        }
        print(
          '✅ DEBUG: Token verification: ${storedToken.substring(0, 20)}...',
        );

        final userId = _getUserIdFromToken(token);
        print('👤 DEBUG: User ID from token: $userId');

        UserModel? user;
        if (userId != null) {
          print('📡 DEBUG: Fetching fresh user profile for ID: $userId');
          user = await getUserProfile(userId);
          if (user != null) {
            print(
              '✅ DEBUG: User profile loaded with fresh profile image: ${user.name}',
            );
            print(
              '🖼️ DEBUG: Profile image URL: ${user.profileImage ?? 'No image'}',
            );
          } else {
            print('⚠️ DEBUG: Failed to load user profile');
          }
        }

        user ??= UserModel(
          id: userId ?? '',
          name: '',
          email: email,
          school: '',
          age: 0,
          gender: '',
          phoneNumber: null,
          preferences: [],
        );

        // Ensure we have the most up-to-date profile image
        if (userId != null && user.profileImage == null) {
          print(
            '🔄 DEBUG: No profile image found, fetching fresh user data...',
          );
          final freshUser = await getUserProfile(userId);
          if (freshUser != null && freshUser.profileImage != null) {
            print(
              '✅ DEBUG: Found profile image in fresh data: ${freshUser.profileImage}',
            );
            user = freshUser;
          }
        }

        await _storeUser(user);
        print('✅ DEBUG: User data stored with updated profile image');

        return {'success': true, 'token': token, 'user': user};
      } else if (response.statusCode == 403) {
        print('❌ DEBUG: 403 Forbidden - CORS or authentication issue');
        print('🔍 DEBUG: Response headers: ${response.headers}');
        return {
          'success': false,
          'error': 'Access denied (403). Backend CORS or authentication issue.',
        };
      } else if (response.statusCode == 404) {
        print('❌ DEBUG: 404 Not Found - Login endpoint not found');
        return {
          'success': false,
          'error': 'Login endpoint not found (404). Check backend routes.',
        };
      } else if (response.statusCode == 500) {
        print('❌ DEBUG: 500 Internal Server Error - Backend exception');
        print('🔍 DEBUG: Response body: ${response.body}');
        print('🔍 DEBUG: Response headers: ${response.headers}');
        print('💡 DEBUG: Check backend logs for stack trace and error details');

        // Try to parse error details from response
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Unknown server error';
          return {
            'success': false,
            'error':
                'Server error: $errorMessage. Check backend logs for details.',
          };
        } catch (parseError) {
          return {
            'success': false,
            'error':
                'Server error (500). Backend exception occurred. Check logs.',
          };
        }
      } else if (response.statusCode >= 500) {
        print('❌ DEBUG: Server error ${response.statusCode}');
        return {
          'success': false,
          'error':
              'Server error (${response.statusCode}). Backend may be starting up.',
        };
      }

      print('❌ DEBUG: Login failed with status ${response.statusCode}');
      return {
        'success': false,
        'error': 'Login failed: ${response.statusCode} - ${response.body}',
      };
    } catch (e) {
      print('❌ DEBUG: Login error: $e');

      // Enhanced error diagnostics
      if (e.toString().contains('Failed host lookup')) {
        print('💡 DEBUG: DNS lookup failed - try these solutions:');
        print('  1. Switch between WiFi and mobile data');
        print('  2. Change DNS to 8.8.8.8 and 1.1.1.1');
        print('  3. Check if your carrier/ISP blocks the domain');
        print('  4. Clear app cache and restart device');
        return {
          'success': false,
          'error':
              'DNS lookup failed. Check network settings or try different connection.',
        };
      } else if (e.toString().contains('Connection refused')) {
        return {
          'success': false,
          'error': 'Connection refused. Backend may be down.',
        };
      } else if (e.toString().contains('timeout')) {
        return {
          'success': false,
          'error': 'Request timeout. Check network connection or try again.',
        };
      }

      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// ✅ VERIFY OTP (POST /auth/verify)
  Future<bool> verifyOtp(String userId, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uuid': userId, 'code': code}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ OTP verify error: $e');
      return false;
    }
  }

  /// 🔁 RESEND OTP (POST /auth/resend-otp)
  Future<bool> resendOtp(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uuid': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Resend OTP error: $e');
      return false;
    }
  }

  // ========================= USER PROFILE =========================
  Future<UserModel?> getUserProfile(String userId) async {
    print('🔄 DEBUG: getUserProfile called for userId: $userId');
    try {
      final token = await getToken();
      if (token == null) return null;

      final resp = await http.get(
        Uri.parse('$_baseUrl/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          // Add ngrok bypass header if using ngrok
          if (_baseUrl.contains('ngrok')) 'ngrok-skip-browser-warning': 'true',
        },
      );

      print('📥 DEBUG: getUserProfile response status: ${resp.statusCode}');
      print('📥 DEBUG: getUserProfile response body: ${resp.body}');

      if (resp.statusCode == 200) {
        final userData = jsonDecode(resp.body);
        final user = UserModel.fromJson(userData);
        print(
          '👤 DEBUG: Parsed user profile image: ${_safeTruncate(user.profileImage, 50)}',
        );
        return user;
      }
      return null;
    } catch (e) {
      print('❌ getUserProfile error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(UserModel user) async {
    print('🔄 DEBUG: updateUserProfile called for user: ${user.name}');
    print(
      '🖼️ DEBUG: Profile image to save: ${_safeTruncate(user.profileImage, 50)}',
    );

    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'No auth token'};

      final requestBody = user.toJson();
      print('📤 DEBUG: Sending user data: $requestBody');

      final resp = await http.put(
        Uri.parse('$_baseUrl/api/users/${user.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          // Add ngrok bypass header if using ngrok
          if (_baseUrl.contains('ngrok')) 'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 DEBUG: Update response status: ${resp.statusCode}');
      print('📥 DEBUG: Update response body: ${resp.body}');

      if (resp.statusCode == 200) {
        // Parse the response to see what the backend actually saved
        final responseData = jsonDecode(resp.body);
        final updatedUser = UserModel.fromJson(responseData);
        print(
          '✅ DEBUG: Backend returned profile image: ${_safeTruncate(updatedUser.profileImage, 50)}',
        );

        await _storeUser(updatedUser);
        print(
          '💾 DEBUG: User stored locally with profile image: ${_safeTruncate(updatedUser.profileImage, 50)}',
        );
        return {'success': true, 'user': updatedUser};
      }
      return {'success': false, 'error': 'Update failed: ${resp.statusCode}'};
    } catch (e) {
      print('❌ DEBUG: updateUserProfile error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ========================= AUTH STATE =========================
  Future<UserModel?> getCurrentUser() async {
    print('🔄 DEBUG: getCurrentUser() called - fetching fresh profile image');
    final token = await getToken();
    if (token == null) {
      print('❌ DEBUG: getCurrentUser() - no token found');
      return null;
    }

    print(
      '✅ DEBUG: getCurrentUser() - token found: ${token.substring(0, 20)}...',
    );

    final userId = _getUserIdFromToken(token);
    print('👤 DEBUG: getCurrentUser() - userId: $userId');

    if (userId != null) {
      print(
        '📡 DEBUG: getCurrentUser() - fetching fresh user profile with profile image...',
      );
      final user = await getUserProfile(userId);
      if (user != null) {
        print(
          '✅ DEBUG: getCurrentUser() - fresh user profile loaded: ${user.name}',
        );
        print(
          '🖼️ DEBUG: getCurrentUser() - profile image: ${user.profileImage ?? 'No image'}',
        );
        await _storeUser(user);
        return user;
      } else {
        print('⚠️ DEBUG: getCurrentUser() - failed to fetch user profile');
      }
    }

    print('🔄 DEBUG: getCurrentUser() - falling back to stored user');
    final storedUser = await getStoredUser();
    if (storedUser != null) {
      print(
        '✅ DEBUG: getCurrentUser() - stored user found: ${storedUser.name}',
      );
      print(
        '🖼️ DEBUG: getCurrentUser() - stored profile image: ${storedUser.profileImage ?? 'No image'}',
      );

      // Even if we have stored user, try to fetch fresh profile image
      if (userId != null) {
        print(
          '🔄 DEBUG: getCurrentUser() - fetching fresh profile image for stored user...',
        );
        final freshUser = await getUserProfile(userId);
        if (freshUser != null) {
          print(
            '✅ DEBUG: getCurrentUser() - updated with fresh profile image: ${freshUser.profileImage ?? 'No image'}',
          );
          await _storeUser(freshUser);
          return freshUser;
        }
      }
    } else {
      print('❌ DEBUG: getCurrentUser() - no stored user found');
    }
    return storedUser;
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    print(
      '🔐 DEBUG: isAuthenticated() - token: ${token?.substring(0, 20) ?? 'null'}...',
    );

    if (token == null) {
      print('🔐 DEBUG: No token found');
      return false;
    }

    try {
      final isExpired = JwtDecoder.isExpired(token);
      print('🔐 DEBUG: Token expired: $isExpired');
      return !isExpired;
    } catch (e) {
      print('🔐 DEBUG: Error checking token expiry: $e');
      return false;
    }
  }

  Future<void> signOut() async => await _clearStoredData();

  /// Debug method to verify environment configuration
  Future<void> debugEnvironmentConfig() async {
    print('🔍 DEBUG: Environment Configuration Check');
    print('🔍 DEBUG: API_BASE_URL from dotenv: ${dotenv.env['API_BASE_URL']}');
    print('🔍 DEBUG: Computed base URL: $_baseUrl');

    // Check if using ngrok and try IP resolution
    if (_baseUrl.contains('ngrok')) {
      await _debugNgrokConnection();
    }

    // Test 1: Test general internet connectivity with multiple public APIs
    final publicApis = [
      'https://httpbin.org/get',
      'https://jsonplaceholder.typicode.com/posts/1',
      'https://api.github.com',
    ];

    bool hasInternet = false;
    for (final apiUrl in publicApis) {
      try {
        print('🌐 DEBUG: Testing connectivity to: $apiUrl');
        final publicResponse = await http
            .get(
              Uri.parse(apiUrl),
              headers: {
                'Content-Type': 'application/json',
                // Add ngrok bypass header if using ngrok
                if (apiUrl.contains('ngrok'))
                  'ngrok-skip-browser-warning': 'true',
              },
            )
            .timeout(const Duration(seconds: 10));

        print('✅ DEBUG: $apiUrl - Status: ${publicResponse.statusCode}');
        hasInternet = true;
        break;
      } catch (e) {
        print('❌ DEBUG: $apiUrl - Error: $e');
      }
    }

    if (!hasInternet) {
      print('❌ DEBUG: No internet connectivity detected');
      print(
        '💡 DEBUG: Check WiFi/mobile data, DNS settings, or network restrictions',
      );
      return;
    }

    // Test 2: DNS resolution test for your domain
    try {
      print(
        '🔍 DEBUG: Testing DNS resolution for camp-backend-27sb.onrender.com',
      );
      final dnsTestResponse = await http
          .head(Uri.parse('https://camp-backend-27sb.onrender.com'))
          .timeout(const Duration(seconds: 15));
      print('✅ DEBUG: DNS resolution successful');
    } catch (e) {
      print('❌ DEBUG: DNS resolution failed: $e');
      print('💡 DEBUG: Try changing DNS to 8.8.8.8 or 1.1.1.1');

      // Test alternative domains to check if it's domain-specific
      final altDomains = [
        'https://httpbin.org',
        'https://jsonplaceholder.typicode.com',
        'https://api.github.com',
      ];

      print('🔍 DEBUG: Testing alternative domains...');
      for (final domain in altDomains) {
        try {
          await http
              .head(Uri.parse(domain))
              .timeout(const Duration(seconds: 5));
          print('✅ DEBUG: $domain - Accessible');
        } catch (e) {
          print('❌ DEBUG: $domain - Error: $e');
        }
      }
      return;
    }

    // Test 3: Test specific backend endpoints
    final endpoints = ['', '/health', '/api', '/auth'];

    for (final endpoint in endpoints) {
      try {
        final testUrl = '$_baseUrl$endpoint';
        print('🔍 DEBUG: Testing endpoint: $testUrl');

        final response = await http
            .get(
              Uri.parse(testUrl),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 15));

        print('📥 DEBUG: $endpoint - Status: ${response.statusCode}');
        if (response.statusCode != 403 && response.body.isNotEmpty) {
          final truncatedBody =
              response.body.length > 100
                  ? response.body.substring(0, 100)
                  : response.body;
          print('📥 DEBUG: $endpoint - Response: $truncatedBody');
        }
      } catch (e) {
        print('❌ DEBUG: $endpoint - Error: $e');
        if (e.toString().contains('Failed host lookup')) {
          print('💡 DEBUG: DNS lookup failed - network or DNS issue');
        } else if (e.toString().contains('Connection refused')) {
          print('💡 DEBUG: Connection refused - backend may be down');
        } else if (e.toString().contains('timeout')) {
          print('💡 DEBUG: Request timeout - slow network or backend');
        }
      }
    }

    // Test 4: Test POST to login endpoint (without credentials)
    try {
      final loginUrl = '$_baseUrl/auth/login';
      print('🔍 DEBUG: Testing POST to login endpoint: $loginUrl');

      final response = await http
          .post(
            Uri.parse(loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: '{"test": "connection"}',
          )
          .timeout(const Duration(seconds: 15));

      print('📥 DEBUG: Login POST - Status: ${response.statusCode}');
      print('📥 DEBUG: Login POST - Response: ${response.body}');

      if (response.statusCode == 500) {
        print('💡 DEBUG: Backend is returning 500 errors - check backend logs');
        print(
          '💡 DEBUG: Common causes: Database connection, missing user, validation errors',
        );
      }
    } catch (e) {
      print('❌ DEBUG: Login POST - Error: $e');
    }

    // Test 5: Network diagnostics summary
    print('🎯 DEBUG NETWORK DIAGNOSTICS:');
    print('  - General internet: ${hasInternet ? "✅ Working" : "❌ Failed"}');
    print('  - DNS resolution: Test above for results');
    print('  - Backend access: Test above for results');
    print('  - Troubleshooting tips:');
    print('    * Try switching between WiFi and mobile data');
    print('    * Change DNS to 8.8.8.8 and 1.1.1.1');
    print('    * Check if carrier blocks certain domains');
    print('    * Clear app cache and restart device');
    print('    * If using ngrok, try switching to IP address');
  }

  /// Debug ngrok connection issues
  Future<void> _debugNgrokConnection() async {
    print('🔍 DEBUG: Ngrok connection diagnostics');

    try {
      // Try to get IP address for ngrok domain
      final uri = Uri.parse(_baseUrl);
      final host = uri.host;
      print('🔍 DEBUG: Ngrok host: $host');

      // Test if we can resolve the domain
      final addresses = await InternetAddress.lookup(host);
      if (addresses.isNotEmpty) {
        print('✅ DEBUG: DNS resolution successful');
        for (final addr in addresses) {
          print('  IP: ${addr.address}');
        }

        // Test direct IP connection
        final firstIp = addresses.first.address;
        final ipUrl = _baseUrl.replaceAll(host, firstIp);
        print('🔍 DEBUG: Testing direct IP connection: $ipUrl');

        try {
          final response = await http
              .get(
                Uri.parse(ipUrl),
                headers: {
                  'Host': host, // Required for ngrok to route correctly
                  'ngrok-skip-browser-warning': 'true',
                },
              )
              .timeout(const Duration(seconds: 10));

          print('✅ DEBUG: IP connection successful: ${response.statusCode}');
          print('💡 DEBUG: Consider using IP address temporarily: $ipUrl');
        } catch (e) {
          print('❌ DEBUG: IP connection failed: $e');
        }
      } else {
        print('❌ DEBUG: No IP addresses found for domain');
      }
    } catch (e) {
      print('❌ DEBUG: DNS lookup completely failed: $e');
      print('💡 DEBUG: Try these solutions:');
      print('  1. Switch to mobile data/WiFi');
      print('  2. Use different DNS (8.8.8.8)');
      print('  3. Ask for a different ngrok URL');
      print('  4. Use localhost if testing on emulator');
    }
  }

  /// Force refresh the authentication state by reloading user data and profile image
  Future<UserModel?> refreshCurrentUser() async {
    print(
      '🔄 DEBUG: refreshCurrentUser() called - fetching fresh profile image',
    );

    final token = await getToken();
    if (token == null) {
      print('❌ DEBUG: refreshCurrentUser() - no token found');
      return null;
    }

    try {
      if (JwtDecoder.isExpired(token)) {
        print('❌ DEBUG: refreshCurrentUser() - token expired');
        await _clearStoredData();
        return null;
      }

      final userId = _getUserIdFromToken(token);
      if (userId != null) {
        print(
          '📡 DEBUG: refreshCurrentUser() - fetching fresh profile data for user ID: $userId',
        );

        // Get the most up-to-date user profile including profile image
        final user = await getUserProfile(userId);
        if (user != null) {
          print(
            '🖼️ DEBUG: refreshCurrentUser() - fetched fresh profile image: ${user.profileImage ?? 'No image set'}',
          );
          print(
            '👤 DEBUG: refreshCurrentUser() - user refreshed: ${user.name}',
          );

          // Store the updated user data
          await _storeUser(user);
          print(
            '💾 DEBUG: refreshCurrentUser() - stored updated user data with fresh profile image',
          );

          return user;
        } else {
          print(
            '⚠️ DEBUG: refreshCurrentUser() - failed to fetch fresh user profile',
          );
        }
      } else {
        print(
          '❌ DEBUG: refreshCurrentUser() - could not extract user ID from token',
        );
      }
    } catch (e) {
      print(
        '❌ DEBUG: refreshCurrentUser() - error fetching fresh profile data: $e',
      );
    }

    return null;
  }

  /// Refresh only the profile image from backend while keeping other user data
  Future<UserModel?> refreshProfileImage() async {
    print(
      '🖼️ DEBUG: refreshProfileImage() called - fetching fresh profile image',
    );

    final token = await getToken();
    if (token == null) {
      print('❌ DEBUG: refreshProfileImage() - no token found');
      return null;
    }

    try {
      if (JwtDecoder.isExpired(token)) {
        print('❌ DEBUG: refreshProfileImage() - token expired');
        return null;
      }

      final userId = _getUserIdFromToken(token);
      if (userId != null) {
        print(
          '📡 DEBUG: refreshProfileImage() - fetching fresh profile image for user ID: $userId',
        );

        // Get fresh user data from backend
        final freshUser = await getUserProfile(userId);
        if (freshUser != null) {
          print(
            '🖼️ DEBUG: refreshProfileImage() - fresh profile image URL: ${freshUser.profileImage ?? 'No image set'}',
          );
          print('👤 DEBUG: refreshProfileImage() - user: ${freshUser.name}');

          // Update stored user data with fresh profile image
          await _storeUser(freshUser);
          print(
            '💾 DEBUG: refreshProfileImage() - updated stored user with fresh profile image',
          );

          return freshUser;
        } else {
          print(
            '⚠️ DEBUG: refreshProfileImage() - failed to fetch fresh user profile',
          );
        }
      } else {
        print(
          '❌ DEBUG: refreshProfileImage() - could not extract user ID from token',
        );
      }
    } catch (e) {
      print('❌ DEBUG: refreshProfileImage() - error: $e');
    }

    return null;
  }

  Stream<bool> get authStateChanges async* {
    while (true) {
      yield await isAuthenticated();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
