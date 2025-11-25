import '../../core/api_client.dart';
import '../models/bid_model.dart';

class BidService {
  final ApiClient _apiClient;

  BidService(this._apiClient);

  Future<List<Bid>> getMyBids() async {
    final response = await _apiClient.dio.get('/bids/mine');
    return (response.data as List).map((e) => Bid.fromJson(e)).toList();
  }

  Future<List<Bid>> getBidsForListing(String listingId) async {
    final response = await _apiClient.dio.get('/listings/$listingId/bids');
    return (response.data as List).map((e) => Bid.fromJson(e)).toList();
  }

  Future<void> acceptBid(String bidId) async {
    await _apiClient.dio.post('/bids/$bidId/accept');
  }

  Future<void> placeBid({
    required String listingId,
    required List<Map<String, dynamic>> items,
    String? message,
  }) async {
    await _apiClient.dio.post('/bids', data: {
      'eventListingId': listingId,
      'items': items,
      'message': message,
    });
  }
}
