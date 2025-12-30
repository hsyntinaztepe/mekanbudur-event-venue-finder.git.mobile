import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../models/turkiye_location_model.dart';

class TurkiyeLocationService {
  TurkiyeLocationService({Dio? dio, Dio? geoDio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://turkiyeapi.dev/api/v1',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ),
        _geoDio = geoDio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://nominatim.openstreetmap.org',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: const {
                  'User-Agent': 'MekanBudurMobile/1.0 (mekanbudur.app)',
                  'Accept-Language': 'tr',
                },
              ),
            );

  final Dio _dio;
  final Dio _geoDio;
  static List<TurkiyeProvince>? _cachedProvinces;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(hours: 12);
  static final Map<String, LatLng> _districtCoordinateCache = {};

  Future<List<TurkiyeProvince>> fetchProvinces(
      {bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isCacheValid = !forceRefresh &&
        _cachedProvinces != null &&
        _cacheTimestamp != null &&
        now.difference(_cacheTimestamp!) < _cacheTtl;
    if (isCacheValid) {
      return _cachedProvinces!;
    }

    try {
      final response = await _dio.get('/provinces');
      final body = response.data;
      if (body is Map<String, dynamic> && body['data'] is List) {
        final provinces = (body['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(TurkiyeProvince.fromJson)
            .where((province) => province.name.isNotEmpty)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        _cachedProvinces = provinces;
        _cacheTimestamp = now;
        return provinces;
      }
      throw const FormatException('Beklenmeyen il/ilçe verisi alındı');
    } on DioException catch (error) {
      final reason = error.response?.statusMessage ?? error.message;
      throw Exception(reason ?? 'İl/ilçe verisi alınamadı');
    }
  }

  Future<LatLng?> fetchDistrictCoordinates({
    required String provinceName,
    required String districtName,
  }) async {
    final cacheKey =
        '${provinceName.toLowerCase()}|${districtName.toLowerCase()}';
    final cached = _districtCoordinateCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _geoDio.get('/search', queryParameters: {
        'format': 'json',
        'countrycodes': 'tr',
        'limit': 1,
        'addressdetails': 0,
        'q': '$districtName, $provinceName, Türkiye',
      });

      final data = response.data;
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        final lat = _parseCoordinate(first['lat']);
        final lon = _parseCoordinate(first['lon'] ?? first['lng']);
        if (lat != null && lon != null) {
          final result = LatLng(lat, lon);
          _districtCoordinateCache[cacheKey] = result;
          return result;
        }
      }
      return null;
    } on DioException catch (error) {
      final reason = error.response?.statusMessage ?? error.message;
      throw Exception(reason ?? 'İlçe koordinatı alınamadı');
    }
  }

  double? _parseCoordinate(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
