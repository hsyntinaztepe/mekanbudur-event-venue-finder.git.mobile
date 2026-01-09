import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/embedded_place_model.dart';

class EmbeddedPlacesService {
  const EmbeddedPlacesService();

  Future<List<EmbeddedPlace>> loadFromAssetManifest({
    String manifestAssetPath = 'assets/place-photos/manifest.json',
    String geoAssetPath = 'assets/place-photos/geo.json',
  }) async {
    final raw = await rootBundle.loadString(manifestAssetPath);
    final decoded = jsonDecode(raw);
    final geoLookup = await _loadGeoLookup(geoAssetPath);

    if (decoded is! Map<String, dynamic>) {
      return const <EmbeddedPlace>[];
    }

    final items = decoded['items'];
    if (items is! Map<String, dynamic>) {
      return const <EmbeddedPlace>[];
    }

    final results = <EmbeddedPlace>[];
    for (final entry in items.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;

      final name = value['name']?.toString().trim() ?? '';
      final category = value['category']?.toString().trim() ?? '';
      final path = value['path']?.toString().trim() ?? '';
      if (name.isEmpty || category.isEmpty || path.isEmpty) continue;

      final filename = path.split('/').where((p) => p.isNotEmpty).last;
      final assetPath = 'assets/place-photos/$filename';
      final normalizedName = _normalizeName(name);
      final geo = geoLookup[normalizedName];

      results.add(
        EmbeddedPlace(
          key: key,
          name: name,
          category: category,
          assetPath: assetPath,
          address: geo?.address,
          latitude: geo?.latitude,
          longitude: geo?.longitude,
        ),
      );
    }

    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  Future<Map<String, _EmbeddedGeoData>> _loadGeoLookup(
    String geoAssetPath,
  ) async {
    try {
      final raw = await rootBundle.loadString(geoAssetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const <String, _EmbeddedGeoData>{};
      }

      final places = decoded['places'];
      if (places is! List) {
        return const <String, _EmbeddedGeoData>{};
      }

      final lookup = <String, _EmbeddedGeoData>{};
      for (final entry in places) {
        if (entry is! Map<String, dynamic>) continue;
        final name = entry['name']?.toString();
        if (name == null || name.trim().isEmpty) continue;
        final normalizedName = _normalizeName(name);
        final lat = double.tryParse(entry['latitude']?.toString() ?? '');
        final lng = double.tryParse(entry['longitude']?.toString() ?? '');
        final address = entry['address']?.toString();
        lookup[normalizedName] = _EmbeddedGeoData(
          latitude: lat,
          longitude: lng,
          address: address,
        );
      }

      return lookup;
    } catch (_) {
      return const <String, _EmbeddedGeoData>{};
    }
  }

  String _normalizeName(String value) => value.toLowerCase().trim();
}

class _EmbeddedGeoData {
  const _EmbeddedGeoData({this.address, this.latitude, this.longitude});

  final String? address;
  final double? latitude;
  final double? longitude;
}
