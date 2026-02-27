import '../core/constants.dart';
import 'api_service.dart';

class AuthResult {
  const AuthResult._({required this.success, this.errorMessage});

  const AuthResult.success() : this._(success: true);

  const AuthResult.failure(String message)
    : this._(success: false, errorMessage: message);

  final bool success;
  final String? errorMessage;
}

class AuthService {
  AuthService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return _authenticate(
      path: '/api/auth/login',
      body: <String, dynamic>{'email': email.trim(), 'password': password},
    );
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return _authenticate(
      path: '/api/auth/register',
      body: <String, dynamic>{
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
      },
    );
  }

  Future<AuthResult> _authenticate({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    try {
      final dynamic data = await _apiService.postJson(path, body);
      if (data is! Map<String, dynamic>) {
        return const AuthResult.failure(
          'Unexpected auth response from backend.',
        );
      }

      final String token = (data['token'] ?? '').toString().trim();
      if (token.isEmpty) {
        return const AuthResult.failure('Authentication token is missing.');
      }

      setApiToken(token);
      return const AuthResult.success();
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (error) {
      return AuthResult.failure(
        'Cannot reach backend at $kResolvedApiBaseUrl. $error',
      );
    }
  }
}
