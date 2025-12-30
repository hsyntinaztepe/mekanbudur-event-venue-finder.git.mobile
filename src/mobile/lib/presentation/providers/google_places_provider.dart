import 'package:flutter/foundation.dart';

import '../../data/models/google_place_category.dart';
import '../../data/models/google_place_model.dart';
import '../../data/services/google_places_service.dart';

class GooglePlacesProvider extends ChangeNotifier {
  GooglePlacesProvider(this._service);

  final GooglePlacesService _service;

  final Map<String, List<GooglePlaceModel>> _placesCache = {};
  final Map<String, bool> _loading = {};
  final Map<String, String?> _errors = {};

  String _activeCategory = GooglePlaceCategory.weddingHalls;
  bool _initialized = false;

  String get activeCategory => _activeCategory;
  bool get isLoading => _loading[_activeCategory] ?? false;
  String? get error => _errors[_activeCategory];
  List<GooglePlaceModel> get places =>
      _placesCache[_activeCategory] ?? const <GooglePlaceModel>[];

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await loadCategory(_activeCategory, forceRefresh: true);
  }

  Future<void> switchCategory(String category) async {
    if (_activeCategory == category) {
      if (!_hasData(category)) {
        await loadCategory(category, forceRefresh: true);
      }
      return;
    }

    _activeCategory = category;
    notifyListeners();
    if (!_hasData(category)) {
      await loadCategory(category, forceRefresh: true);
    }
  }

  Future<void> refreshActive() async {
    await loadCategory(_activeCategory, forceRefresh: true);
  }

  Future<void> loadCategory(String category, {bool forceRefresh = false}) async {
    if (!forceRefresh && _hasData(category)) {
      return;
    }

    _setLoading(category, true);
    try {
      final items = await _service.fetchPlaces(category);
      _placesCache[category] = items;
      _errors[category] = null;
    } catch (e) {
      _errors[category] = e.toString();
      _placesCache[category] = const <GooglePlaceModel>[];
    } finally {
      _setLoading(category, false);
    }
  }

  bool _hasData(String category) {
    final items = _placesCache[category];
    return items != null && items.isNotEmpty;
  }

  void _setLoading(String category, bool value) {
    _loading[category] = value;
    notifyListeners();
  }
}
