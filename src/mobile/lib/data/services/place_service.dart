import 'package:dio/dio.dart';

import '../../core/geo_api_client.dart';
import '../models/place_model.dart';

class PlaceService {
  final GeoApiClient _geoApiClient;

  PlaceService(this._geoApiClient);

  Future<List<PlaceModel>> getPlacesByRefType(String refType) async {
    try {
      final response = await _geoApiClient.dio.get(
        '/places/by-type',
        queryParameters: {'refType': refType},
      );

      final data = response.data;
      if (data is List) {
        return data.map((json) => PlaceModel.fromJson(json)).toList();
      }
      throw const FormatException('Unexpected response shape for places');
    } on DioException catch (e) {
      final message = e.response?.data?.toString() ?? e.message;
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }
}
