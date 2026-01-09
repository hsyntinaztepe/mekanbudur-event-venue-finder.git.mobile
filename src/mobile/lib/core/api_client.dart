import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _prefsKey = 'apiBaseUrl';

  static String _currentBaseUrl =
      _envBaseUrl.isNotEmpty ? _envBaseUrl : 'http://10.0.2.2:8084/api';

  static Future<String>? _resolveFuture;

  /// Current effective base URL (may be resolved at runtime).
  static String get baseUrl => _currentBaseUrl;

  final Dio _dio;

  ApiClient() : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Resolve a reachable API baseUrl once, then reuse.
        final resolved = await _ensureResolvedBaseUrl();
        options.baseUrl = resolved;

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;

  static Future<String> _ensureResolvedBaseUrl() async {
    if (_envBaseUrl.isNotEmpty) {
      _currentBaseUrl = _envBaseUrl;
      return _currentBaseUrl;
    }

    _resolveFuture ??= _resolveBaseUrl();
    _currentBaseUrl = await _resolveFuture!;
    return _currentBaseUrl;
  }

  static Future<String> _resolveBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getString(_prefsKey) ?? '').trim();

    final candidates = <String>[
      if (saved.isNotEmpty) saved,
      // Docker compose defaults
      'http://10.0.2.2:8081/api',
      // Local/non-docker runs (common)
      'http://10.0.2.2:8084/api',
      // Sometimes API is reachable via localhost (desktop/web)
      'http://localhost:8081/api',
      'http://localhost:8084/api',
    ];

    final probe = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ),
    );

    for (final base in candidates) {
      try {
        final url = base.endsWith('/') ? '${base}health' : '$base/health';
        final res = await probe.get(url);
        final data = res.data;
        final isApi = data is Map && (data['service']?.toString() == 'api');

        if (res.statusCode == 200 && isApi) {
          _currentBaseUrl = base;
          await prefs.setString(_prefsKey, base);
          return base;
        }
      } catch (_) {
        // try next
      }
    }

    // Fallback: keep current default.
    return _currentBaseUrl;
  }
}
