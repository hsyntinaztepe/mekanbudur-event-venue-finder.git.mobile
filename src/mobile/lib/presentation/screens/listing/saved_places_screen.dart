import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/models/google_place_category.dart';
import '../../../data/models/google_place_model.dart';
import '../../../data/models/public_vendor_model.dart';
import '../../../data/models/place_model.dart';
import '../../providers/listing_provider.dart';
import '../../providers/google_places_provider.dart';
import '../../providers/place_provider.dart';
import '../../providers/vendor_provider.dart';

const Map<String, IconData> _googleCategoryIcons = {
  GooglePlaceCategory.weddingHalls: Icons.celebration_rounded,
  GooglePlaceCategory.bakeries: Icons.cake_rounded,
  GooglePlaceCategory.photographers: Icons.camera_alt_rounded,
};

const int _googlePlacesPreviewLimit = 6;

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final MapController _mapController = MapController();
  static const LatLng _ankaraCenter = LatLng(39.9334, 32.8597);
  String? _activeMarkerId;
  bool _isMapExpanded = false;
  String? _selectedCity;
  String? _selectedDistrict;
  bool _isLocationFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final placeProvider = context.read<PlaceProvider>();
    final listingProvider = context.read<ListingProvider>();
    final googlePlacesProvider = context.read<GooglePlacesProvider>();
    final vendorProvider = context.read<VendorProvider>();

    await placeProvider.fetchPlaces();
    // Ensure listings are available for cross-linking.
    await listingProvider.fetchAllListings();
    await googlePlacesProvider.ensureInitialized();
    await vendorProvider.fetchPublicVendors();
  }

  Future<void> _onPlaceTypeSelected(String target) async {
    await context
        .read<PlaceProvider>()
        .fetchPlaces(refType: target, forceRefresh: true);
    if (!mounted) return;
    if (target == PlaceRefType.vendor) {
      await context.read<VendorProvider>().fetchPublicVendors();
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeProvider = context.watch<PlaceProvider>();
    final listingProvider = context.watch<ListingProvider>();
    final googlePlacesProvider = context.watch<GooglePlacesProvider>();
    final vendorProvider = context.watch<VendorProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Ana sayfaya dön',
          onPressed: () => context.go('/'),
        ),
        title: const Text('Kayıtlı Mekanlar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => placeProvider.refreshCurrent(),
            tooltip: 'Verileri yenile',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _PlaceTypeSelector(
                provider: placeProvider,
                onTypeSelected: _onPlaceTypeSelected,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: theme.colorScheme.primary,
                onRefresh: () => placeProvider.refreshCurrent(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildBody(
                    placeProvider,
                    listingProvider,
                    googlePlacesProvider,
                    vendorProvider,
                    theme,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    PlaceProvider provider,
    ListingProvider listingProvider,
    GooglePlacesProvider googleProvider,
    VendorProvider vendorProvider,
    ThemeData theme,
  ) {
    final isVendorSelected = provider.currentRefType == PlaceRefType.vendor;
    final isListingSelected = provider.currentRefType == PlaceRefType.listing;
    final visiblePlaces = _filterPlacesForDisplay(provider, listingProvider);
    final listingMarkers = _filterListingsForMap(provider, listingProvider);
    final memberVendorSection = isVendorSelected
        ? _buildMemberVendorPlacesSection(
            places: visiblePlaces,
            vendorProvider: vendorProvider,
            theme: theme,
          )
        : const <Widget>[];
    final cityDistrictMap = isListingSelected
        ? _buildCityDistrictMap(listingProvider)
        : <String, Set<String>>{};

    final sharedChildren = <Widget>[
      _buildMapSection(
        provider,
        listingProvider,
        theme,
        googleProvider,
        visiblePlaces,
        listingMarkers,
      ),
      if (isListingSelected && cityDistrictMap.isNotEmpty) ...[
        const SizedBox(height: 12),
        _buildLocationFilterBar(cityDistrictMap),
      ],
      const SizedBox(height: 18),
      if (isVendorSelected) ...[
        ...memberVendorSection,
        const SizedBox(height: 18),
      ],
      if (isVendorSelected) ...[
        _buildGooglePlacesSection(googleProvider),
        const SizedBox(height: 18),
      ],
    ];

    if (provider.isLoading && provider.places.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ...sharedChildren,
          const _SavedPlacesLoadingIndicator(),
        ],
      );
    }

    if (provider.error != null && provider.places.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ...sharedChildren,
          _ErrorView(
            message: provider.error!,
            onRetry: provider.refreshCurrent,
          ),
        ],
      );
    }

    if (provider.places.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ...sharedChildren,
          _EmptyView(refType: provider.currentRefType),
        ],
      );
    }

    final cardWidgets = <Widget>[];
    final filterActive = isListingSelected &&
        (_selectedCity != null || _selectedDistrict != null);

    if (!isVendorSelected) {
      for (final place in visiblePlaces) {
        final listing = place.refType == PlaceRefType.listing
            ? _resolveListing(listingProvider, place.refId)
            : null;
        cardWidgets.add(
          _PlaceCard(
            place: place,
            listing: listing,
            theme: theme,
            onShowOnMap: () => _focusOnPlace(place),
          ),
        );
        cardWidgets.add(const SizedBox(height: 14));
      }
    }
    if (cardWidgets.isNotEmpty) {
      cardWidgets.removeLast();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ...sharedChildren,
        if (cardWidgets.isEmpty && filterActive)
          _FilteredEmptyNotice(onClearFilters: _resetLocationFilters)
        else
          ...cardWidgets,
      ],
    );
  }

  List<Widget> _buildMemberVendorPlacesSection({
    required List<PlaceModel> places,
    required VendorProvider vendorProvider,
    required ThemeData theme,
  }) {
    final vendorPlaces = places
        .where((place) => place.refType == PlaceRefType.vendor)
        .toList(growable: false);

    if (vendorPlaces.isEmpty) {
      return const <Widget>[];
    }

    final widgets = <Widget>[
      const _SectionHeader(text: 'Üye mekanlar'),
      const SizedBox(height: 10),
    ];

    for (final place in vendorPlaces) {
      final vendor = vendorProvider.publicVendorsById[place.refId];
      widgets.add(
        _MemberVendorPlaceCard(
          place: place,
          vendor: vendor,
          theme: theme,
          onShowOnMap: () => _focusOnPlace(place),
        ),
      );
      widgets.add(const SizedBox(height: 14));
    }
    widgets.removeLast();
    return widgets;
  }

  Listing? _resolveListing(ListingProvider provider, String refId) {
    try {
      return provider.allListings.firstWhere((listing) => listing.id == refId);
    } catch (_) {
      return null;
    }
  }

  void _focusOnPlace(PlaceModel place) {
    final target = LatLng(place.latitude, place.longitude);
    _mapController.move(target, 14);
  }

  void _focusOnGooglePlace(GooglePlaceModel place) {
    final target = LatLng(place.latitude, place.longitude);
    _mapController.move(target, 14.2);
  }

  void _focusOnListing(Listing listing) {
    if (listing.latitude == null || listing.longitude == null) return;
    final target = LatLng(listing.latitude!, listing.longitude!);
    _mapController.move(target, 14.2);
  }

  Future<void> _handleMarkerTap(
    String markerId,
    Future<void> Function() action,
  ) async {
    setState(() => _activeMarkerId = markerId);
    await action();
    if (!mounted) return;
    setState(() => _activeMarkerId = null);
  }

  void _toggleMapExpansion() {
    setState(() => _isMapExpanded = !_isMapExpanded);
  }

  void _resetLocationFilters() {
    if (_selectedCity == null && _selectedDistrict == null) return;
    setState(() {
      _selectedCity = null;
      _selectedDistrict = null;
    });
  }

  void _toggleLocationFilterExpansion() {
    setState(() => _isLocationFilterExpanded = !_isLocationFilterExpanded);
  }

  List<PlaceModel> _filterPlacesForDisplay(
    PlaceProvider provider,
    ListingProvider listingProvider,
  ) {
    final places = provider.places;
    if (provider.currentRefType != PlaceRefType.listing) return places;
    if (_selectedCity == null && _selectedDistrict == null) return places;
    return places.where((place) {
      final listing = _resolveListing(listingProvider, place.refId);
      return _matchesLocationFilter(listing);
    }).toList(growable: false);
  }

  List<Listing> _filterListingsForMap(
    PlaceProvider provider,
    ListingProvider listingProvider,
  ) {
    final listings = listingProvider.allListings
        .where(
            (listing) => listing.latitude != null && listing.longitude != null)
        .toList(growable: false);
    if (provider.currentRefType != PlaceRefType.listing) return listings;
    if (_selectedCity == null && _selectedDistrict == null) return listings;
    return listings
        .where((listing) => _matchesLocationFilter(listing))
        .toList(growable: false);
  }

  Map<String, Set<String>> _buildCityDistrictMap(
    ListingProvider listingProvider,
  ) {
    final map = <String, Set<String>>{};
    for (final listing in listingProvider.allListings) {
      final rawLocation = listing.addressLabel?.isNotEmpty == true
          ? listing.addressLabel
          : listing.location;
      final parts = _parseLocationParts(rawLocation);
      final city = parts.city;
      if (city == null || city.isEmpty) continue;
      final district = parts.district;
      final citySet = map.putIfAbsent(city, () => <String>{});
      if (district != null && district.isNotEmpty) {
        citySet.add(district);
      }
    }
    return map;
  }

  _LocationParts _parseLocationParts(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _LocationParts();
    }
    final normalized = raw
        .replaceAll('•', ',')
        .replaceAll('/', ',')
        .replaceAll(' - ', ',')
        .replaceAll('-', ',');
    final tokens = normalized
        .split(',')
        .map(_normalizeLocationToken)
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) {
      return const _LocationParts();
    }
    final city = tokens.first;
    final district = tokens.length >= 2 ? tokens[1] : null;
    return _LocationParts(city: city, district: district);
  }

  String _normalizeLocationToken(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _matchesLocationFilter(Listing? listing) {
    if (_selectedCity == null && _selectedDistrict == null) return true;
    if (listing == null) return false;
    final rawLocation = listing.addressLabel?.isNotEmpty == true
        ? listing.addressLabel
        : listing.location;
    final parts = _parseLocationParts(rawLocation);
    if (_selectedCity != null && parts.city != _selectedCity) {
      return false;
    }
    if (_selectedDistrict != null && parts.district != _selectedDistrict) {
      return false;
    }
    return true;
  }

  Widget _buildLocationFilterBar(Map<String, Set<String>> cityDistrictMap) {
    if (cityDistrictMap.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final cities = cityDistrictMap.keys.toList()..sort();
    final allDistricts = cityDistrictMap.values
        .expand((districts) => districts)
        .toSet()
        .toList()
      ..sort();
    final List<String> currentDistricts;
    if (_selectedCity == null) {
      currentDistricts = List<String>.from(allDistricts);
    } else {
      currentDistricts = (cityDistrictMap[_selectedCity] ?? <String>{}).toList()
        ..sort();
    }
    InputDecoration decoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      );
    }

    final hasSelection = _selectedCity != null || _selectedDistrict != null;
    final summaryBuffer = StringBuffer();
    summaryBuffer.write(_selectedCity ?? 'Tüm şehirler');
    summaryBuffer.write(' • ');
    summaryBuffer.write(_selectedDistrict ?? 'Tüm ilçeler');

    final filterControls = Column(
      key: const ValueKey('filter-expanded'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: _selectedCity,
          decoration: decoration('Şehir'),
          dropdownColor: const Color(0xFF151B26),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tümü', style: TextStyle(color: Colors.white)),
            ),
            ...cities.map(
              (city) => DropdownMenuItem<String?>(
                value: city,
                child: Text(city, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCity = value;
              _selectedDistrict = null;
            });
          },
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: _selectedDistrict,
          decoration: decoration('İlçe'),
          dropdownColor: const Color(0xFF151B26),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tümü', style: TextStyle(color: Colors.white)),
            ),
            ...currentDistricts.map(
              (district) => DropdownMenuItem<String?>(
                value: district,
                child:
                    Text(district, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedDistrict = value;
            });
          },
          style: const TextStyle(color: Colors.white),
        ),
        if (hasSelection) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetLocationFilters,
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Filtreleri temizle'),
            ),
          ),
        ],
      ],
    );

    final collapsedSummary = Padding(
      key: const ValueKey('filter-collapsed'),
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasSelection
                  ? summaryBuffer.toString()
                  : 'Şehir ve ilçe seçmek için açın.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          if (hasSelection)
            TextButton(
              onPressed: _resetLocationFilters,
              child: const Text('Temizle'),
            ),
        ],
      ),
    );

    final icon = _isLocationFilterExpanded ? Icons.remove : Icons.add;
    final toggleTooltip = _isLocationFilterExpanded
        ? 'Filtre panelini daralt'
        : 'Filtre panelini genişlet';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0F121B),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Konuma göre filtrele',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: toggleTooltip,
                onPressed: _toggleLocationFilterExpansion,
                icon: Icon(icon, color: Colors.white),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: collapsedSummary,
            secondChild: filterControls,
            crossFadeState: _isLocationFilterExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(
    PlaceProvider provider,
    ListingProvider listingProvider,
    ThemeData theme,
    GooglePlacesProvider googleProvider,
    List<PlaceModel> places,
    List<Listing> listingsWithCoords,
  ) {
    final isVendorSelected = provider.currentRefType == PlaceRefType.vendor;
    final isListingSelected = provider.currentRefType == PlaceRefType.listing;
    final googlePlaces =
        isVendorSelected ? googleProvider.places : const <GooglePlaceModel>[];

    final List<LatLng> aggregatePoints = [
      ...places.map((p) => LatLng(p.latitude, p.longitude)),
      if (isListingSelected)
        ...listingsWithCoords.map(
          (l) => LatLng(l.latitude!, l.longitude!),
        ),
      if (isVendorSelected)
        ...googlePlaces.map((g) => LatLng(g.latitude, g.longitude)),
    ];

    final hasAnyMarkers = aggregatePoints.isNotEmpty;
    final center =
        hasAnyMarkers ? _calculateLatLngCenter(aggregatePoints) : _ankaraCenter;
    final circles = places
        .where((p) => (p.radius ?? 0) > 0)
        .map((p) => CircleMarker(
              point: LatLng(p.latitude, p.longitude),
              radius: p.radius!,
              useRadiusInMeter: true,
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderColor: theme.colorScheme.primary.withOpacity(0.4),
              borderStrokeWidth: 2,
            ))
        .toList();

    final vendorById = context.read<VendorProvider>().publicVendorsById;
    final savedMarkers = places.map((place) {
      final listing = place.refType == PlaceRefType.listing
          ? _resolveListing(listingProvider, place.refId)
          : null;
      final vendorTitle = place.refType == PlaceRefType.vendor
          ? vendorById[place.refId]?.companyName
          : null;
      final markerId = 'saved-${place.id}';
      final isActive = _activeMarkerId == markerId;
      return Marker(
        point: LatLng(place.latitude, place.longitude),
        width: 120,
        height: 80,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () {
            _handleMarkerTap(
              markerId,
              () => _showPlaceDetails(place, listing),
            );
          },
          child: AnimatedScale(
            scale: isActive ? 1.18 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    listing?.title ??
                        vendorTitle ??
                        place.addressLabel ??
                        (place.refType == PlaceRefType.vendor
                            ? 'Üye mekan'
                            : place.refId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.location_on_rounded,
                  color:
                      isActive ? theme.colorScheme.primary : Colors.pinkAccent,
                  size: isActive ? 36 : 30,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
    final googleMarkers = googlePlaces.map((place) {
      final markerId =
          'google-${place.name}-${place.latitude}-${place.longitude}';
      final isActive = _activeMarkerId == markerId;
      return Marker(
        point: LatLng(place.latitude, place.longitude),
        width: 140,
        height: 74,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () {
            _handleMarkerTap(
              markerId,
              () => _showGooglePlaceDetails(place),
            );
          },
          child: AnimatedScale(
            scale: isActive ? 1.18 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1727).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? Colors.cyanAccent
                          : Colors.cyanAccent.withOpacity(0.5),
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.place_outlined,
                  color: Colors.cyanAccent,
                  size: isActive ? 34 : 28,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    final listingMarkers = isListingSelected
        ? listingsWithCoords.map((listing) {
            final markerId = 'listing-${listing.id}';
            final isActive = _activeMarkerId == markerId;
            return Marker(
              point: LatLng(listing.latitude!, listing.longitude!),
              width: 150,
              height: 82,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () {
                  _handleMarkerTap(
                    markerId,
                    () => _showListingLocationDetails(listing),
                  );
                },
                child: AnimatedScale(
                  scale: isActive ? 1.16 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2436).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? theme.colorScheme.secondary
                                : Colors.white24,
                            width: isActive ? 2 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.secondary
                                        .withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          listing.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.location_city_rounded,
                        color: isActive
                            ? theme.colorScheme.secondary
                            : Colors.amberAccent,
                        size: isActive ? 34 : 28,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList()
        : const <Marker>[];

    final mapHeight = _isMapExpanded ? 420.0 : 260.0;

    final secondaryCount =
        isVendorSelected ? googlePlaces.length : listingsWithCoords.length;
    final secondaryLabel = isVendorSelected
        ? 'Google ${GooglePlaceCategory.labelFor(googleProvider.activeCategory)}'
        : 'İlan lokasyonu';

    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            key: ValueKey(
              'map-${provider.currentRefType}-${places.length}-${googleProvider.activeCategory}-${googlePlaces.length}',
            ),
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: hasAnyMarkers ? 11.2 : 7.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mobile',
              ),
              if (circles.isNotEmpty) CircleLayer(circles: circles),
              if (savedMarkers.isNotEmpty) MarkerLayer(markers: savedMarkers),
              if (listingMarkers.isNotEmpty)
                MarkerLayer(markers: listingMarkers),
              if (googleMarkers.isNotEmpty) MarkerLayer(markers: googleMarkers),
            ],
          ),
          if (!hasAnyMarkers)
            const Center(
              child: Text(
                'Bu tip için kayıtlı konum bulunamadı',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Positioned(
            left: 12,
            top: 12,
            child: _MapExpandButton(
              isExpanded: _isMapExpanded,
              onToggle: _toggleMapExpansion,
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _MapStatsBadge(
              savedCount: places.length,
              savedLabel: provider.currentRefType == PlaceRefType.vendor
                  ? 'Tedarikçi'
                  : 'İlan',
              googleCount: secondaryCount,
              googleLabel: secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGooglePlacesSection(GooglePlacesProvider provider) {
    return _GooglePlacesPanel(
      provider: provider,
      onFocusOnMap: _focusOnGooglePlace,
    );
  }

  LatLng _calculateLatLngCenter(List<LatLng> points) {
    final lat = points.fold<double>(0, (sum, item) => sum + item.latitude) /
        points.length;
    final lng = points.fold<double>(0, (sum, item) => sum + item.longitude) /
        points.length;
    return LatLng(lat, lng);
  }

  String _buildVendorSubtitle(PublicVendor? vendor) {
    if (vendor == null) return 'Bilgi bulunamadı';

    final parts = <String>[];
    final description = vendor.description?.trim();
    if (description != null && description.isNotEmpty) {
      parts.add(description);
    }

    if (vendor.categoryList.isNotEmpty) {
      parts.add(vendor.categoryList.take(3).join(', '));
    }

    return parts.isNotEmpty ? parts.join(' • ') : 'Bilgi bulunamadı';
  }

  Future<void> _showPlaceDetails(PlaceModel place, Listing? listing) async {
    final isVendor = place.refType == PlaceRefType.vendor;
    final vendor = isVendor
        ? context.read<VendorProvider>().publicVendorsById[place.refId]
        : null;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.place, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.addressLabel?.isNotEmpty == true
                              ? place.addressLabel!
                              : (isVendor
                                  ? ((vendor != null &&
                                          vendor.companyName.trim().isNotEmpty)
                                      ? vendor.companyName.trim()
                                      : 'Üye mekan')
                                  : (listing?.title ?? place.refId)),
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        if (isVendor)
                          Text(
                            _buildVendorSubtitle(vendor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                          )
                        else
                          Text(
                            'Lat ${place.latitude.toStringAsFixed(4)} • Lng ${place.longitude.toStringAsFixed(4)}',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (place.radius != null && !isVendor)
                Text('Kapsama: ${place.radius!.toStringAsFixed(0)} metre'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _focusOnPlace(place);
                    },
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Haritada Odakla'),
                  ),
                  if (listing != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.push('/listing/${listing.id}', extra: listing);
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('İlan Detayı'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showGooglePlaceDetails(GooglePlaceModel place) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent),
                    ),
                    child: const Icon(Icons.place_outlined,
                        color: Colors.cyanAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place.address,
                          style: Theme.of(ctx)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Lat ${place.latitude.toStringAsFixed(4)} • Lng ${place.longitude.toStringAsFixed(4)}',
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _focusOnGooglePlace(place);
                    },
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Haritada Göster'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final text = '${place.name} - ${place.address}';
                      await Clipboard.setData(ClipboardData(text: text));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Adres panoya kopyalandı'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Adresi Kopyala'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showListingLocationDetails(Listing listing) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.event_available, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          listing.addressLabel?.isNotEmpty == true
                              ? listing.addressLabel!
                              : listing.location ?? 'Adres belirtilmemiş',
                          style: Theme.of(ctx)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Lat ${listing.latitude?.toStringAsFixed(4) ?? '-'} • Lng ${listing.longitude?.toStringAsFixed(4) ?? '-'}',
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _focusOnListing(listing);
                    },
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Haritada Odakla'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.push('/listing/${listing.id}', extra: listing);
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('İlan Detayı'),
                  ),
                  if (listing.location?.isNotEmpty == true)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: listing.location!),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Adres panoya kopyalandı'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Adresi Kopyala'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaceTypeSelector extends StatelessWidget {
  const _PlaceTypeSelector({
    required this.provider,
    this.onTypeSelected,
  });

  final PlaceProvider provider;
  final Future<void> Function(String target)? onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: PlaceRefType.listing,
          label: Text('İlan Konumları'),
          icon: Icon(Icons.event_available_rounded),
        ),
        ButtonSegment<String>(
          value: PlaceRefType.vendor,
          label: Text('Tedarikçi Konumları'),
          icon: Icon(Icons.store_mall_directory_rounded),
        ),
      ],
      selected: {provider.currentRefType},
      onSelectionChanged: (selection) async {
        final target = selection.first;
        if (onTypeSelected != null) {
          await onTypeSelected!(target);
          return;
        }
        await provider.fetchPlaces(refType: target, forceRefresh: true);
      },
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.listing,
    required this.theme,
    this.onShowOnMap,
  });

  final PlaceModel place;
  final Listing? listing;
  final ThemeData theme;
  final VoidCallback? onShowOnMap;

  @override
  Widget build(BuildContext context) {
    final hasListing = listing != null;
    final radiusLabel = place.radius != null
        ? '${place.radius!.toStringAsFixed(0)} m yarıçap'
        : 'Radius belirtilmemiş';
    final coordinates =
        'Lat ${place.latitude.toStringAsFixed(4)} • Lng ${place.longitude.toStringAsFixed(4)}';
    final primaryText = hasListing
        ? listing!.title
        : place.addressLabel?.isNotEmpty == true
            ? place.addressLabel!
            : (place.refId.isNotEmpty
                ? 'Referans: ${place.refId}'
                : 'Kayıtlı konum');
    final secondaryText = hasListing
        ? (listing!.addressLabel?.isNotEmpty == true
            ? listing!.addressLabel!
            : listing!.location ?? 'Konum belirtilmemiş')
        : 'Referans: ${place.refId}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2233), Color(0xFF0F121B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: hasListing
                      ? theme.colorScheme.primary
                      : Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  hasListing ? Icons.location_on_rounded : Icons.storefront,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      secondaryText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            runSpacing: 8,
            spacing: 8,
            children: [
              _InfoChip(
                icon: Icons.explore_outlined,
                label: coordinates,
              ),
              _InfoChip(
                icon: Icons.radar_rounded,
                label: radiusLabel,
              ),
              _InfoChip(
                icon: Icons.category_outlined,
                label: 'Tip: ${place.refType}',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: onShowOnMap,
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Haritada Göster'),
                  ),
                  if (hasListing)
                    TextButton.icon(
                      onPressed: () => context.push(
                        '/listing/${listing!.id}',
                        extra: listing,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('İlan detayına git'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _MemberVendorPlaceCard extends StatelessWidget {
  const _MemberVendorPlaceCard({
    required this.place,
    required this.vendor,
    required this.theme,
    required this.onShowOnMap,
  });

  final PlaceModel place;
  final PublicVendor? vendor;
  final ThemeData theme;
  final VoidCallback onShowOnMap;

  @override
  Widget build(BuildContext context) {
    final title = (vendor != null && vendor!.companyName.trim().isNotEmpty)
        ? vendor!.companyName.trim()
        : 'Üye mekan';

    final details = <String>[];
    final description = vendor?.description?.trim();
    if (description != null && description.isNotEmpty) {
      details.add(description);
    }

    final categories = vendor?.categoryList;
    if (categories != null && categories.isNotEmpty) {
      details.add(categories.take(3).join(', '));
    }

    final subtitle =
        details.isNotEmpty ? details.join(' • ') : 'Bilgi bulunamadı';

    final photoUrl = _resolveVendorPhotoUrl(vendor);

    return InkWell(
      onTap: onShowOnMap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 72,
                color: theme.colorScheme.surfaceContainerHighest,
                child: photoUrl == null
                    ? Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          color:
                              theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.7,
                          ),
                        ),
                      )
                    : Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.storefront_rounded,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onShowOnMap,
              tooltip: 'Haritada göster',
              icon: const Icon(Icons.map_rounded),
            ),
          ],
        ),
      ),
    );
  }

  String? _resolveVendorPhotoUrl(PublicVendor? vendor) {
    if (vendor == null) return null;
    if (vendor.photoUrlList.isEmpty) return null;
    final raw = vendor.photoUrlList.first.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    // ApiClient.baseUrl = http://10.0.2.2:8081/api
    // Static files are served from the host root, e.g. http://10.0.2.2:8081/uploads/...
    final api = Uri.tryParse(ApiClient.baseUrl);
    if (api == null) return raw;

    final root = api.replace(path: '', query: null, fragment: null);
    final normalized = raw.startsWith('/') ? raw : '/$raw';
    return root.toString().replaceAll(RegExp(r'/$'), '') + normalized;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.refType});

  final String refType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final descriptor = refType == PlaceRefType.vendor ? 'tedarikçi' : 'ilan';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.my_location_outlined,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              'Kayıtlı $descriptor konumu bulunamadı.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni konum eklemek için geo servisini kullanan işlemlerden birini tamamlayabilirsiniz.',
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Konumlar yüklenemedi',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilteredEmptyNotice extends StatelessWidget {
  const _FilteredEmptyNotice({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu konum için kayıtlı ilan konumu bulunamadı.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Farklı bir şehir veya ilçe seçebilir ya da filtreleri temizleyebilirsiniz.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Filtreleri temizle'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedPlacesLoadingIndicator extends StatelessWidget {
  const _SavedPlacesLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            'Kayıtlı konumlar yükleniyor...',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LocationParts {
  const _LocationParts({this.city, this.district});

  final String? city;
  final String? district;
}

class _MapStatsBadge extends StatelessWidget {
  const _MapStatsBadge({
    required this.savedCount,
    required this.savedLabel,
    required this.googleCount,
    required this.googleLabel,
  });

  final int savedCount;
  final String savedLabel;
  final int googleCount;
  final String googleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$savedCount kayıtlı $savedLabel',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$googleCount $googleLabel',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _MapExpandButton extends StatelessWidget {
  const _MapExpandButton({required this.isExpanded, required this.onToggle});

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final label = isExpanded ? 'Haritayı daralt' : 'Haritayı genişlet';
    final icon = isExpanded ? Icons.fullscreen_exit : Icons.fullscreen;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _GooglePlacesPanel extends StatelessWidget {
  const _GooglePlacesPanel({
    required this.provider,
    required this.onFocusOnMap,
  });

  final GooglePlacesProvider provider;
  final void Function(GooglePlaceModel place) onFocusOnMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final places = provider.places;
    final isBusy = provider.isLoading && places.isEmpty;
    final hasError = provider.error != null && places.isEmpty;
    final Widget panelContent;
    if (isBusy) {
      panelContent = const Padding(
        key: ValueKey('google-loading'),
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (hasError) {
      panelContent = _GooglePlacesErrorNotice(
        key: const ValueKey('google-error'),
        message: provider.error!,
        onRetry: provider.refreshActive,
      );
    } else if (places.isEmpty) {
      panelContent = const Padding(
        key: ValueKey('google-empty'),
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Bu kategori için sonuç bulunamadı. Farklı bir kategori seçebilir veya yenilemeyi deneyebilirsiniz.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    } else {
      final preview =
          places.take(_googlePlacesPreviewLimit).toList(growable: false);

      panelContent = Column(
        key: ValueKey(
          'google-data-${provider.activeCategory}-${preview.length}',
        ),
        children: [
          for (final place in preview) ...[
            _GooglePlaceCard(
              place: place,
              onFocusOnMap: () => onFocusOnMap(place),
            ),
            const SizedBox(height: 12),
          ],
          if (places.length > preview.length)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${places.length} sonucun ilk ${preview.length} tanesi gösteriliyor.',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF0B0F17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gölbaşı Google Mekanları',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Düğün salonu, pastane ve fotoğrafçı önerileri Google Places üzerinden canlı çekilir.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Google verilerini yenile',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => provider.refreshActive(),
              ),
            ],
          ),
          if (provider.isLoading && places.isNotEmpty) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: GooglePlaceCategory.values
                .map(
                  (value) => ButtonSegment<String>(
                    value: value,
                    label: Text(GooglePlaceCategory.labelFor(value)),
                    icon: Icon(_googleCategoryIcons[value] ?? Icons.place),
                  ),
                )
                .toList(),
            selected: {provider.activeCategory},
            onSelectionChanged: (selection) {
              final target = selection.first;
              provider.switchCategory(target);
            },
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: panelContent,
          ),
        ],
      ),
    );
  }
}

class _GooglePlacesErrorNotice extends StatelessWidget {
  const _GooglePlacesErrorNotice({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Google verileri alınamadı',
          style: theme.textTheme.titleSmall
              ?.copyWith(color: theme.colorScheme.error),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tekrar Dene'),
        ),
      ],
    );
  }
}

class _GooglePlaceCard extends StatelessWidget {
  const _GooglePlaceCard({
    required this.place,
    required this.onFocusOnMap,
  });

  final GooglePlaceModel place;
  final VoidCallback onFocusOnMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF151B26),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.6)),
                ),
                child: const Icon(Icons.apartment_rounded,
                    color: Colors.cyanAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.address,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white70, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Lat ${place.latitude.toStringAsFixed(4)} • Lng ${place.longitude.toStringAsFixed(4)}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: onFocusOnMap,
                icon: const Icon(Icons.map_rounded),
                label: const Text('Haritada Odakla'),
              ),
              TextButton.icon(
                onPressed: () {
                  final text = '${place.name} - ${place.address}';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adres panoya kopyalandı'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Adresi Kopyala'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
