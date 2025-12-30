import 'package:dio/dio.dart';

import '../../core/geo_api_client.dart';
import '../models/google_place_category.dart';
import '../models/google_place_model.dart';

class GooglePlacesService {
  GooglePlacesService(this._geoApiClient);

  final GeoApiClient _geoApiClient;

  Future<List<GooglePlaceModel>> fetchPlaces(String category) async {
    final endpoint = GooglePlaceCategory.endpointFor(category);
    if (endpoint == null) {
      throw ArgumentError('Kategori için endpoint bulunamadı: $category');
    }

    try {
      final response = await _geoApiClient.dio.get(endpoint);
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(GooglePlaceModel.fromJson)
            .toList();
      }
      throw const FormatException(
          'Google Places yanıtı beklenen formatta değil');
    } on DioException catch (e) {
      final message = e.response?.data?.toString() ?? e.message;
      throw Exception('Google Places isteği başarısız: $message');
    }
  }
}
