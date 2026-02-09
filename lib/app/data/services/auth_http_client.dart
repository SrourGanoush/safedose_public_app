import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Custom HTTP client that removes API key and uses OAuth for per-user Gemini quota
class AuthHttpClient extends http.BaseClient {
  final AuthService _authService;
  final http.Client _inner = http.Client();

  AuthHttpClient(this._authService);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('DEBUG [AuthHttpClient]: Request to ${request.url}');

    // REMOVE the API key header - we want OAuth-only authentication
    request.headers.remove('x-goog-api-key');

    // Add OAuth headers for per-user quota
    final headers = await _authService.getAuthHeaders();
    if (headers != null) {
      request.headers.addAll(headers);
      print('DEBUG [AuthHttpClient]: Using OAuth only (API key removed)');
    } else {
      print('DEBUG [AuthHttpClient]: ERROR - No OAuth token available');
      throw 'Authentication required. Please log out and log in again.';
    }

    final response = await _inner.send(request);
    print('DEBUG [AuthHttpClient]: Response status: ${response.statusCode}');

    return response;
  }
}
