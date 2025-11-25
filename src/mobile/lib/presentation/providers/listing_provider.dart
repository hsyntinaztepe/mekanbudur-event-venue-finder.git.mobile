import 'package:flutter/material.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/listing_service.dart';

class ListingProvider extends ChangeNotifier {
  final ListingService _listingService;

  List<ServiceCategory> _categories = [];
  List<Listing> _myListings = [];
  List<Listing> _allListings = [];
  bool _isLoading = false;
  String? _error;

  ListingProvider(this._listingService);

  List<ServiceCategory> get categories => _categories;
  List<Listing> get myListings => _myListings;
  List<Listing> get allListings => _allListings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _listingService.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyListings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _myListings = await _listingService.getMyListings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllListings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allListings = await _listingService.getAllListings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createListing({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _listingService.createListing(
        title: title,
        description: description,
        eventDate: eventDate,
        location: location,
        items: items,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        addressLabel: addressLabel,
      );
      // Refresh cached lists so newly oluşturulan ilan hemen görünür
      try {
        final my = await _listingService.getMyListings();
        final all = await _listingService.getAllListings();
        _myListings = my;
        _allListings = all;
      } catch (syncError) {
        _error = syncError.toString();
      }
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

  Future<bool> updateListingVisibility(
      String listingId, ListingVisibility visibility) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _listingService.updateListingVisibility(
        listingId: listingId,
        visibility: visibility.index,
      );
      if (visibility == ListingVisibility.deleted) {
        _myListings = _myListings.where((l) => l.id != listingId).toList();
        _allListings = _allListings.where((l) => l.id != listingId).toList();
      } else {
        _myListings = _myListings
            .map((l) =>
                l.id == listingId ? l.copyWith(visibility: visibility) : l)
            .toList();
        _allListings = _allListings
            .map((l) =>
                l.id == listingId ? l.copyWith(visibility: visibility) : l)
            .toList();
      }
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
