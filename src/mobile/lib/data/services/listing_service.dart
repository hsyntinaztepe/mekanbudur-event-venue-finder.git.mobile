import '../../core/api_client.dart';
import '../models/listing_model.dart';

class ListingService {
  final ApiClient _apiClient;

  ListingService(this._apiClient);

  Future<List<ServiceCategory>> getCategories() async {
    final response = await _apiClient.dio.get('/categories');
    return (response.data as List)
        .map((e) => ServiceCategory.fromJson(e))
        .toList();
  }

  Future<List<Listing>> getMyListings() async {
    final response = await _apiClient.dio.get('/listings/mine');
    return (response.data as List).map((e) => Listing.fromJson(e)).toList();
  }

  Future<List<Listing>> getAllListings() async {
    final response = await _apiClient.dio.get('/listings');
    return (response.data as List).map((e) => Listing.fromJson(e)).toList();
  }

  Future<void> createListing({
    required String title,
    required String description,
    required DateTime eventDate,
    required String location,
    required List<Map<String, dynamic>> items,
    double? latitude,
    double? longitude,
    double? radius,
    String? addressLabel,
  }) async {
    await _apiClient.dio.post('/listings', data: {
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'location': location,
      'items': items,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'addressLabel': addressLabel,
    });
  }

  Future<void> updateListingVisibility({
    required String listingId,
    required int visibility,
  }) async {
    await _apiClient.dio.patch('/listings/$listingId/visibility', data: {
      'visibility': visibility,
    });
  }
}
