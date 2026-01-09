import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple HTTP client dedicated to the Geo microservice.
class GeoApiClient {
  static const String _envBaseUrl = String.fromEnvironment('GEO_BASE_URL');
  static const String _prefsKey = 'geoBaseUrl';

  static String _currentBaseUrl =
      _envBaseUrl.isNotEmpty ? _envBaseUrl : 'http://10.0.2.2:8082/api';

  static Future<String>? _resolveFuture;

  static String get baseUrl => _currentBaseUrl;

  final Dio _dio;

  GeoApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final resolved = await _ensureResolvedBaseUrl();
        options.baseUrl = resolved;
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
      // Docker compose default
      'http://10.0.2.2:8082/api',
      // Older/alternate configs
      'http://10.0.2.2:8083/api',
      'http://localhost:8082/api',
      'http://localhost:8083/api',
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
        final isGeo = data is Map && (data['service']?.toString() == 'geo');

        if (res.statusCode == 200 && isGeo) {
          _currentBaseUrl = base;
          await prefs.setString(_prefsKey, base);
          return base;
        }
      } catch (_) {
        // try next
      }
    }

    return _currentBaseUrl;
  }
}
