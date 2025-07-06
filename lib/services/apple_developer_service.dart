import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppleDeveloperService {
  static const String _baseUrl = 'https://developer.apple.com';
  static const String _apiUrl = 'https://api.appstoreconnect.apple.com';
  static const String _storageKey = 'apple_developer_session';

  static String? _sessionToken;
  static String? _appleId;

  // Login to Apple Developer Portal
  static Future<bool> login(String appleId, String password) async {
    try {
      // For demo purposes, we'll simulate a successful login
      // In a real implementation, you would need to handle the actual Apple authentication flow
      // This is a simplified version that stores credentials locally

      _appleId = appleId;
      _sessionToken =
          'demo_session_token_${DateTime.now().millisecondsSinceEpoch}';

      // Store the session
      await _storeSession();

      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Logout from Apple Developer Portal
  static Future<void> logout() async {
    _sessionToken = null;
    _appleId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  // Get stored Apple ID
  static Future<String?> getStoredAppleId() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = prefs.getString(_storageKey);

    if (sessionData != null) {
      final data = json.decode(sessionData);
      _appleId = data['appleId'];
      _sessionToken = data['sessionToken'];
      return _appleId;
    }

    return null;
  }

  // Store session data
  static Future<void> _storeSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = json.encode({
      'appleId': _appleId,
      'sessionToken': _sessionToken,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_storageKey, sessionData);
  }

  // Check if user is logged in
  static bool get isLoggedIn => _sessionToken != null;

  // Get current Apple ID
  static String? get currentAppleId => _appleId;

  // Get session token
  static String? get sessionToken => _sessionToken;

  // Validate session
  static Future<bool> validateSession() async {
    if (_sessionToken == null) return false;

    // In a real implementation, you would validate the session with Apple's servers
    // For demo purposes, we'll assume the session is valid if it exists
    return true;
  }

  // Make authenticated request to Apple Developer API
  static Future<http.Response> makeAuthenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    if (_sessionToken == null) {
      throw Exception('Not authenticated');
    }

    final headers = {
      'Authorization': 'Bearer $_sessionToken',
      'Content-Type': 'application/json',
    };

    final uri = Uri.parse('$_apiUrl$endpoint');

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // Get certificates from Apple Developer Portal
  static Future<List<Map<String, dynamic>>> getCertificates() async {
    try {
      final response = await makeAuthenticatedRequest('/v1/certificates');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch certificates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching certificates: $e');
      return [];
    }
  }

  // Get provisioning profiles from Apple Developer Portal
  static Future<List<Map<String, dynamic>>> getProvisioningProfiles() async {
    try {
      final response = await makeAuthenticatedRequest('/v1/profiles');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception(
          'Failed to fetch provisioning profiles: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching provisioning profiles: $e');
      return [];
    }
  }

  // Get app IDs from Apple Developer Portal
  static Future<List<Map<String, dynamic>>> getAppIds() async {
    try {
      final response = await makeAuthenticatedRequest('/v1/appIds');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch app IDs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching app IDs: $e');
      return [];
    }
  }

  // Upload CSR and create certificate
  static Future<Map<String, dynamic>> uploadCSR({
    required String csrContent,
    required String
    certificateType, // 'IOS_DISTRIBUTION', 'IOS_DEVELOPMENT', etc.
  }) async {
    try {
      // Remove header and footer from CSR content
      final cleanCSR = csrContent
          .replaceAll('-----BEGIN CERTIFICATE REQUEST-----', '')
          .replaceAll('-----END CERTIFICATE REQUEST-----', '')
          .replaceAll('\n', '')
          .trim();

      final body = {
        'data': {
          'type': 'certificates',
          'attributes': {
            'csrContent': cleanCSR,
            'certificateType': certificateType,
          },
        },
      };

      final response = await makeAuthenticatedRequest(
        '/v1/certificates',
        method: 'POST',
        body: body,
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception(
          'Failed to upload CSR: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error uploading CSR: $e');
      rethrow;
    }
  }

  // Download certificate by ID
  static Future<String> downloadCertificate(String certificateId) async {
    try {
      final response = await makeAuthenticatedRequest(
        '/v1/certificates/$certificateId',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final certificateContent =
            data['data']['attributes']['certificateContent'];

        if (certificateContent == null) {
          throw Exception('Certificate content not found in response');
        }

        return certificateContent;
      } else {
        throw Exception(
          'Failed to download certificate: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error downloading certificate: $e');
      rethrow;
    }
  }

  // Get certificate type string for API
  static String getCertificateTypeString(String userFriendlyType) {
    switch (userFriendlyType.toLowerCase()) {
      case 'distribution':
        return 'IOS_DISTRIBUTION';
      case 'development':
        return 'IOS_DEVELOPMENT';
      case 'apple_distribution':
        return 'APPLE_DISTRIBUTION';
      case 'apple_development':
        return 'APPLE_DEVELOPMENT';
      case 'developer_id_application':
        return 'DEVELOPER_ID_APPLICATION';
      case 'developer_id_installer':
        return 'DEVELOPER_ID_INSTALLER';
      case 'mac_installer_distribution':
        return 'MAC_INSTALLER_DISTRIBUTION';
      case 'mac_app_distribution':
        return 'MAC_APP_DISTRIBUTION';
      case 'mac_development':
        return 'MAC_DEVELOPMENT';
      default:
        return 'IOS_DISTRIBUTION'; // Default to distribution
    }
  }

  // Get user-friendly certificate type name
  static String getUserFriendlyCertificateType(String apiType) {
    switch (apiType.toUpperCase()) {
      case 'IOS_DISTRIBUTION':
        return 'Distribution';
      case 'IOS_DEVELOPMENT':
        return 'Development';
      case 'APPLE_DISTRIBUTION':
        return 'Apple Distribution';
      case 'APPLE_DEVELOPMENT':
        return 'Apple Development';
      case 'DEVELOPER_ID_APPLICATION':
        return 'Developer ID Application';
      case 'DEVELOPER_ID_INSTALLER':
        return 'Developer ID Installer';
      case 'MAC_INSTALLER_DISTRIBUTION':
        return 'Mac Installer Distribution';
      case 'MAC_APP_DISTRIBUTION':
        return 'Mac App Distribution';
      case 'MAC_DEVELOPMENT':
        return 'Mac Development';
      default:
        return apiType;
    }
  }

  // Get available certificate types
  static List<String> getAvailableCertificateTypes() {
    return [
      'Distribution',
      'Development',
      'Apple Distribution',
      'Apple Development',
      'Developer ID Application',
      'Developer ID Installer',
      'Mac Installer Distribution',
      'Mac App Distribution',
      'Mac Development',
    ];
  }
}
