import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/listing_service.dart';

class ListingProvider extends ChangeNotifier {
  final ListingService _listingService;

  List<ServiceCategory> _categories = [];
  List<Listing> _myListings = [];
  List<Listing> _allListings = [];
  bool _isLoading = false;
  String? _error;
  Set<String> _favoriteListingIds = <String>{};
  String? _favoritesOwnerKey;
  bool _favoritesLoaded = false;

  ListingProvider(this._listingService);

  List<ServiceCategory> get categories => _categories;
  List<Listing> get myListings => _myListings;
  List<Listing> get allListings => _allListings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get favoritesReady => _favoritesLoaded;

  bool isFavorite(String listingId) => _favoriteListingIds.contains(listingId);

  String _favoritesStorageKey(String ownerIdentifier) =>
      'favorites_$ownerIdentifier';

  Future<void> loadFavorites({String? ownerIdentifier}) async {
    if (ownerIdentifier == null || ownerIdentifier.isEmpty) {
      final hadData =
          _favoriteListingIds.isNotEmpty || _favoritesOwnerKey != null;
      _favoriteListingIds = <String>{};
      _favoritesOwnerKey = null;
      _favoritesLoaded = true;
      if (hadData) {
        notifyListeners();
      }
      return;
    }

    if (_favoritesLoaded && _favoritesOwnerKey == ownerIdentifier) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_favoritesStorageKey(ownerIdentifier)) ??
        <String>[];
    _favoriteListingIds = stored.toSet();
    _favoritesOwnerKey = ownerIdentifier;
    _favoritesLoaded = true;
    notifyListeners();
  }

  Future<bool> toggleFavorite({
    required String listingId,
    required String ownerIdentifier,
  }) async {
    if (ownerIdentifier.isEmpty) {
      return false;
    }

    if (!_favoritesLoaded || _favoritesOwnerKey != ownerIdentifier) {
      await loadFavorites(ownerIdentifier: ownerIdentifier);
    }

    final isCurrentlyFavorite = _favoriteListingIds.contains(listingId);
    if (isCurrentlyFavorite) {
      _favoriteListingIds.remove(listingId);
    } else {
      _favoriteListingIds.add(listingId);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesStorageKey(ownerIdentifier),
      _favoriteListingIds.toList(),
    );

    return !isCurrentlyFavorite;
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
