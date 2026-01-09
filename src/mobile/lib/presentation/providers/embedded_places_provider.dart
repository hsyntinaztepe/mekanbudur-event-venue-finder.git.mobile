import 'package:flutter/foundation.dart';

import '../../data/models/embedded_place_model.dart';
import '../../data/services/embedded_places_service.dart';

class EmbeddedPlacesProvider extends ChangeNotifier {
  EmbeddedPlacesProvider(this._service);

  final EmbeddedPlacesService _service;

  List<EmbeddedPlace> _places = const <EmbeddedPlace>[];
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;

  List<EmbeddedPlace> get places => _places;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _places.isNotEmpty;

  Future<void> ensureLoaded() => _load(forceRefresh: false);

  Future<void> refresh() => _load(forceRefresh: true);

  Future<void> _load({required bool forceRefresh}) async {
    if (_isLoading) return;
    if (_initialized && !forceRefresh) return;

    _isLoading = true;
    if (forceRefresh) {
      _error = null;
    }
    notifyListeners();

    try {
      final resolved = await _service.loadFromAssetManifest();
      _places = resolved;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _initialized = true;
      notifyListeners();
    }
  }
}
