import 'package:flutter/material.dart';
import '../../data/models/bid_model.dart';
import '../../data/services/bid_service.dart';

class BidProvider extends ChangeNotifier {
  final BidService _bidService;
  
  List<Bid> _myBids = [];
  bool _isLoading = false;
  String? _error;

  BidProvider(this._bidService);

  List<Bid> get myBids => _myBids;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyBids() async {
    _isLoading = true;
    notifyListeners();
    try {
      _myBids = await _bidService.getMyBids();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Bid> _listingBids = [];
  List<Bid> get listingBids => _listingBids;

  Future<void> fetchBidsForListing(String listingId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _listingBids = await _bidService.getBidsForListing(listingId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptBid(String bidId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _bidService.acceptBid(bidId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> placeBid({
    required String listingId,
    required List<Map<String, dynamic>> items,
    String? message,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _bidService.placeBid(
        listingId: listingId,
        items: items,
        message: message,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
