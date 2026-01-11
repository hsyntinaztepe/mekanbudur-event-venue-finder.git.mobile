import 'package:flutter/material.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/listing_service.dart';

class ListingProvider extends ChangeNotifier {
  final ListingService _listingService;

  List<ServiceCategory> _categories = [];
  List<Listing> _myListings = [];
  List<Listing> _allListings = [];
  List<Listing> _favoriteListings = [];
  bool _isLoading = false;
  String? _error;

  ListingProvider(this._listingService);

  List<ServiceCategory> get categories => _categories;
  List<Listing> get myListings => _myListings;
  List<Listing> get allListings => _allListings;
  List<Listing> get favoriteListings => _favoriteListings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isFavorite(String listingId) {
    return _favoriteListings.any((l) => l.id == listingId) || 
           _allListings.any((l) => l.id == listingId && l.isFavorited);
  }

  Future<void> fetchFavorites() async {
    _isLoading = true;
    notifyListeners();
    try {
      _favoriteListings = await _listingService.getFavorites();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(String listingId) async {
    try {
      final isFav = await _listingService.toggleFavorite(listingId);
      
      _updateLocalList(_allListings, listingId, isFav);
      _updateLocalList(_myListings, listingId, isFav);
      
      if (isFav) {
        if (!_favoriteListings.any((l) => l.id == listingId)) {
           Listing? item;
           try {
             item = _allListings.firstWhere((l) => l.id == listingId);
           } catch (_) {
             try {
                item = _myListings.firstWhere((l) => l.id == listingId);
             } catch (_) {}
           }
           
           if (item != null) {
              _favoriteListings.add(item.copyWith(isFavorited: true));
           } else {
             // Fallback: reload favorites if we can't find the item object
             await fetchFavorites();
           }
        }
      } else {
        _favoriteListings.removeWhere((l) => l.id == listingId);
      }
      
      notifyListeners();
      return isFav;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _updateLocalList(List<Listing> list, String id, bool isFav) {
    for (var i = 0; i < list.length; i++) {
      if (list[i].id == id) {
        list[i] = list[i].copyWith(isFavorited: isFav);
      }
    }
  }

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
        _favoriteListings = _favoriteListings.where((l) => l.id != listingId).toList();
      } else {
        _myListings = _myListings
            .map((l) =>
                l.id == listingId ? l.copyWith(visibility: visibility) : l)
            .toList();
        _allListings = _allListings
            .map((l) =>
                l.id == listingId ? l.copyWith(visibility: visibility) : l)
            .toList();
         _favoriteListings = _favoriteListings
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
