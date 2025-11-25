import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      final token = data['token'];
      final role = data['role'];
      final displayName = data['displayName'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', role);
      await prefs.setString('displayName', displayName);

      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? companyName,
    String? serviceCategoriesCsv,
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'displayName': displayName,
        'role': role,
        'companyName': companyName,
        'serviceCategoriesCsv': serviceCategoriesCsv,
      });

      final data = response.data;
      final token = data['token'];
      final returnedRole = data['role'];
      final returnedDisplayName = data['displayName'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      if (returnedRole is String) {
        await prefs.setString('role', returnedRole);
      }
      if (returnedDisplayName is String) {
        await prefs.setString('displayName', returnedDisplayName);
      }

      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
