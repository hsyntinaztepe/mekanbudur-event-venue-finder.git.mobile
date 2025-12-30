import 'package:flutter/material.dart';

import '../../data/models/place_model.dart';
import '../../data/services/place_service.dart';

class PlaceProvider extends ChangeNotifier {
  PlaceProvider(this._placeService);

  final PlaceService _placeService;

  final List<PlaceModel> _places = [];
  bool _isLoading = false;
  String? _error;
  String _currentRefType = PlaceRefType.listing;
  bool _hasLoadedOnce = false;

  List<PlaceModel> get places => List.unmodifiable(_places);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentRefType => _currentRefType;
  bool get hasLoaded => _hasLoadedOnce;

  Future<void> fetchPlaces({
    String? refType,
    bool forceRefresh = false,
  }) async {
    final targetType = refType ?? _currentRefType;

    if (!forceRefresh &&
        _hasLoadedOnce &&
        targetType == _currentRefType &&
        _places.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    if (targetType != _currentRefType) {
      _places.clear();
    }
    notifyListeners();

    try {
      final results = await _placeService.getPlacesByRefType(targetType);
      _currentRefType = targetType;
      _places
        ..clear()
        ..addAll(results);
      _hasLoadedOnce = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrent() {
    return fetchPlaces(refType: _currentRefType, forceRefresh: true);
  }
}

class PlaceRefType {
  static const String listing = 'Listing';
  static const String vendor = 'Vendor';
}
