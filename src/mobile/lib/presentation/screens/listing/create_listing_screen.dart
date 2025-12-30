import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/listing_provider.dart';
import '../../../data/models/turkiye_location_model.dart';
import '../../../data/services/turkiye_location_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  LatLng? _selectedPoint;
  double _selectedRadius = 1000;
  String? _addressLabel;

  static final RegExp _descriptionCharPattern = RegExp(
    r'''[0-9A-Za-zğüşöçıİĞÜŞÖÇ.,;:!?()"'\-\s]''',
  );
  static final TextInputFormatter _turkishFriendlyFormatter =
      FilteringTextInputFormatter.allow(_descriptionCharPattern);

  static const LatLng _defaultMapCenter = LatLng(41.015137, 28.97953);

  // Items
  final List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ListingProvider>().fetchCategories());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatLatLng(LatLng point) {
    return 'Lat ${point.latitude.toStringAsFixed(4)}, Lng ${point.longitude.toStringAsFixed(4)}';
  }

  Future<void> _openLocationPicker() async {
    final result = await showModalBottomSheet<_LocationPickerResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _LocationPickerSheet(
          initialPoint: _selectedPoint ?? _defaultMapCenter,
          initialRadius: _selectedRadius,
          initialLabel: _addressLabel,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPoint = result.point;
        _selectedRadius = result.radius;
        final label = result.label?.trim();
        _addressLabel = (label?.isNotEmpty ?? false) ? label : null;
      });
    }
  }

  int _countWords(String value) {
    final text = value.trim();
    if (text.isEmpty) return 0;
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;
  }

  String? _validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Açıklama zorunludur';
    }
    final wordCount = _countWords(text);
    if (wordCount < 20) {
      return 'Açıklama en az 20 kelime olmalı (şu an $wordCount)';
    }
    if (wordCount > 400) {
      return 'Açıklama en fazla 400 kelime olabilir (şu an $wordCount)';
    }
    return null;
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        onAdd: (item) {
          setState(() {
            _items.add(item);
          });
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lütfen bir tarih seçin')));
        return;
      }
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lütfen en az bir kalem ekleyin')));
        return;
      }
      if (_selectedPoint == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lütfen haritada konum seçin')));
        return;
      }

      final hasCustomLabel = _addressLabel?.trim().isNotEmpty ?? false;
      final locationText = hasCustomLabel
          ? _addressLabel!.trim()
          : _formatLatLng(_selectedPoint!);
      final label = hasCustomLabel ? _addressLabel!.trim() : locationText;

      final titleText = _titleController.text.trim();
      final descriptionText = _descriptionController.text.trim();

      final success = await context.read<ListingProvider>().createListing(
            title: titleText,
            description: descriptionText,
            eventDate: _selectedDate!,
            location: locationText,
            items: _items,
            latitude: _selectedPoint!.latitude,
            longitude: _selectedPoint!.longitude,
            radius: _selectedRadius,
            addressLabel: label,
          );

      if (success && mounted) {
        context.pop(); // Go back to my listings
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.read<ListingProvider>().error ??
                  'İlan oluşturulamadı')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Yeni İlan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration:
                    const InputDecoration(labelText: 'Etkinlik Başlığı'),
                validator: (v) => v?.isEmpty == true ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  helperText: 'En az 20 kelime, en fazla 400 kelime',
                ),
                minLines: 3,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [_turkishFriendlyFormatter],
                validator: _validateDescription,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Etkinlik tarihini seçin'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Konum Seç',
                              style: Theme.of(context).textTheme.titleMedium),
                          TextButton.icon(
                            onPressed: _openLocationPicker,
                            icon: const Icon(Icons.map),
                            label: Text(
                                _selectedPoint == null ? 'Seç' : 'Düzenle'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedPoint == null)
                        const Text(
                            'Henüz konum seçilmedi. Harita üzerinden seçim yapın.')
                      else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 200,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: _selectedPoint!,
                                initialZoom: 13,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.pinchZoom |
                                      InteractiveFlag.drag,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.mobile',
                                ),
                                CircleLayer(
                                  circles: [
                                    if (_selectedRadius > 0)
                                      CircleMarker(
                                        point: _selectedPoint!,
                                        radius: _selectedRadius,
                                        useRadiusInMeter: true,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.2),
                                        borderColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.6),
                                        borderStrokeWidth: 2,
                                      ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedPoint!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.redAccent,
                                        size: 36,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Kapsam: ${_selectedRadius.round()} m'),
                        Text('Koordinat: ${_formatLatLng(_selectedPoint!)}'),
                        if ((_addressLabel?.isNotEmpty ?? false)) ...[
                          const SizedBox(height: 4),
                          Text('Adres etiketi: $_addressLabel'),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gereken Kalemler',
                      style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                      onPressed: _addItem, icon: const Icon(Icons.add_circle)),
                ],
              ),
              ..._items.map((item) => Card(
                    child: ListTile(
                      title: Text(
                          'Kategori ID: ${item['categoryId']}'), // Should map to name
                      subtitle: Text('Bütçe: ${item['budget']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _items.remove(item);
                          });
                        },
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
              Consumer<ListingProvider>(
                builder: (context, provider, child) {
                  return provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton(
                          onPressed: _submit,
                          child: const Text('İlanı Oluştur'),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const _AddItemDialog({required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  int? _selectedCategory;
  final _budgetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ListingProvider>().categories;

    return AlertDialog(
      title: const Text('Kalem Ekle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: _selectedCategory,
            items: categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (val) => setState(() => _selectedCategory = val),
            decoration: const InputDecoration(labelText: 'Kategori'),
          ),
          TextField(
            controller: _budgetController,
            decoration: const InputDecoration(labelText: 'Bütçe'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç')),
        TextButton(
          onPressed: () {
            if (_selectedCategory != null &&
                _budgetController.text.isNotEmpty) {
              widget.onAdd({
                'categoryId': _selectedCategory,
                'budget': double.tryParse(_budgetController.text) ?? 0,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

class _LocationPickerResult {
  final LatLng point;
  final double radius;
  final String? label;

  const _LocationPickerResult({
    required this.point,
    required this.radius,
    this.label,
  });
}

class _LocationPickerSheet extends StatefulWidget {
  final LatLng initialPoint;
  final double initialRadius;
  final String? initialLabel;

  const _LocationPickerSheet({
    required this.initialPoint,
    required this.initialRadius,
    this.initialLabel,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late LatLng _point = widget.initialPoint;
  late double _radius = widget.initialRadius.clamp(100, 10000);
  late TextEditingController _labelController;
  final MapController _mapController = MapController();
  final TurkiyeLocationService _locationService = TurkiyeLocationService();
  late Future<List<TurkiyeProvince>> _provinceFuture;
  TurkiyeProvince? _selectedProvince;
  TurkiyeDistrict? _selectedDistrict;
  bool _labelChangedByUser = false;
  bool _suppressLabelEvent = false;
  bool _initialLocationApplied = false;
  bool _isDistrictGeocoding = false;
  String? _districtGeocodeError;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
    _labelController.addListener(() {
      if (_suppressLabelEvent) return;
      _labelChangedByUser = true;
    });
    _provinceFuture = _locationService.fetchProvinces();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String _radiusText(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} km';
    }
    return '${value.round()} m';
  }

  Widget _buildProvinceDistrictSelectors(ThemeData theme) {
    return FutureBuilder<List<TurkiyeProvince>>(
      future: _provinceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'İl ve ilçe verileri yükleniyor...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İl ve ilçe listesi yüklenemedi.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.error?.toString() ?? 'Lütfen tekrar deneyin.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _retryProvinceFetch,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          );
        }

        final provinces = snapshot.data ?? const <TurkiyeProvince>[];
        if (provinces.isEmpty) {
          return const SizedBox.shrink();
        }

        _applyInitialLocationSelection(provinces);
        final districtOptions =
            _selectedProvince?.districts ?? const <TurkiyeDistrict>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProvince?.name,
              decoration: const InputDecoration(labelText: 'İl'),
              isExpanded: true,
              items: provinces
                  .map(
                    (province) => DropdownMenuItem(
                      value: province.name,
                      child: Text(province.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _handleProvinceSelection(value, provinces),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDistrict?.name,
              decoration: const InputDecoration(labelText: 'İlçe'),
              isExpanded: true,
              items: districtOptions
                  .map(
                    (district) => DropdownMenuItem(
                      value: district.name,
                      child: Text(district.name),
                    ),
                  )
                  .toList(),
              onChanged: _selectedProvince == null
                  ? null
                  : (value) => _handleDistrictSelection(value),
            ),
            if (_isDistrictGeocoding) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'İlçe koordinatları alınıyor...',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (_districtGeocodeError != null) ...[
              const SizedBox(height: 8),
              Text(
                _districtGeocodeError!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.redAccent),
              ),
            ],
          ],
        );
      },
    );
  }

  void _retryProvinceFetch() {
    setState(() {
      _provinceFuture = _locationService.fetchProvinces(forceRefresh: true);
    });
  }

  void _applyInitialLocationSelection(List<TurkiyeProvince> provinces) {
    if (_initialLocationApplied) return;
    final parts = _parseLocationParts(widget.initialLabel);
    _initialLocationApplied = true;
    if (parts.$1 == null) return;
    final province = _findProvinceByName(provinces, parts.$1!);
    if (province == null) return;
    TurkiyeDistrict? district;
    if (parts.$2 != null) {
      district = _findDistrictByName(province, parts.$2!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedProvince = province;
        _selectedDistrict = district;
      });
      final lat = district?.latitude ?? province.latitude;
      final lng = district?.longitude ?? province.longitude;
      _focusOnCoordinates(lat, lng, district != null ? 12.5 : 10.5);
    });
  }

  void _handleProvinceSelection(
    String? value,
    List<TurkiyeProvince> provinces,
  ) {
    if (value == null || value.trim().isEmpty) {
      setState(() {
        _selectedProvince = null;
        _selectedDistrict = null;
        _isDistrictGeocoding = false;
        _districtGeocodeError = null;
      });
      if (!_labelChangedByUser) {
        _setLabelText('');
      }
      return;
    }
    final province = _findProvinceByName(provinces, value);
    if (province == null) return;
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = null;
      _isDistrictGeocoding = false;
      _districtGeocodeError = null;
    });
    _maybeUpdateLabelFromSelection(province, null);
    _focusOnCoordinates(province.latitude, province.longitude, 10.5);
  }

  Future<void> _handleDistrictSelection(String? value) async {
    final province = _selectedProvince;
    if (province == null) return;
    if (value == null || value.trim().isEmpty) {
      setState(() {
        _selectedDistrict = null;
        _isDistrictGeocoding = false;
        _districtGeocodeError = null;
      });
      _maybeUpdateLabelFromSelection(province, null);
      _focusOnCoordinates(province.latitude, province.longitude, 10.5);
      return;
    }
    final district = _findDistrictByName(province, value);
    if (district == null) return;
    setState(() {
      _selectedDistrict = district;
      _districtGeocodeError = null;
    });
    _maybeUpdateLabelFromSelection(province, district);

    if (district.latitude != null && district.longitude != null) {
      _focusOnCoordinates(district.latitude, district.longitude, 12.5);
      return;
    }

    setState(() => _isDistrictGeocoding = true);
    try {
      final latLng = await _locationService.fetchDistrictCoordinates(
        provinceName: province.name,
        districtName: district.name,
      );
      if (!mounted) return;
      if (latLng != null) {
        final updatedDistrict = TurkiyeDistrict(
          name: district.name,
          latitude: latLng.latitude,
          longitude: latLng.longitude,
        );
        setState(() {
          _selectedDistrict = updatedDistrict;
          _isDistrictGeocoding = false;
          _districtGeocodeError = null;
        });
        _focusOnCoordinates(latLng.latitude, latLng.longitude, 12.5);
      } else {
        setState(() {
          _isDistrictGeocoding = false;
          _districtGeocodeError = 'İlçe koordinatları bulunamadı.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isDistrictGeocoding = false;
        _districtGeocodeError =
            'Koordinatlar alınamadı. Lütfen tekrar deneyin.';
      });
    }
  }

  void _maybeUpdateLabelFromSelection(
    TurkiyeProvince? province,
    TurkiyeDistrict? district,
  ) {
    if (province == null) return;
    if (_labelChangedByUser && _labelController.text.trim().isNotEmpty) {
      return;
    }
    final buffer = StringBuffer(province.name);
    if (district != null) {
      buffer
        ..write(' / ')
        ..write(district.name);
    }
    _setLabelText(buffer.toString());
  }

  void _setLabelText(String value) {
    _suppressLabelEvent = true;
    _labelController.text = value;
    _suppressLabelEvent = false;
  }

  void _focusOnCoordinates(double? latitude, double? longitude, double zoom) {
    if (latitude == null || longitude == null || !mounted) return;
    final target = LatLng(latitude, longitude);
    setState(() => _point = target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(target, zoom);
    });
  }

  TurkiyeProvince? _findProvinceByName(
    List<TurkiyeProvince> provinces,
    String name,
  ) {
    final lower = name.toLowerCase();
    for (final province in provinces) {
      if (province.name.toLowerCase() == lower) {
        return province;
      }
    }
    return null;
  }

  TurkiyeDistrict? _findDistrictByName(
    TurkiyeProvince province,
    String name,
  ) {
    final lower = name.toLowerCase();
    for (final district in province.districts) {
      if (district.name.toLowerCase() == lower) {
        return district;
      }
    }
    return null;
  }

  (String?, String?) _parseLocationParts(String? raw) {
    if (raw == null || raw.trim().isEmpty) return (null, null);
    final normalized = raw
        .replaceAll('•', ',')
        .replaceAll('/', ',')
        .replaceAll(' - ', ',')
        .replaceAll('-', ',');
    final tokens = normalized
        .split(',')
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return (null, null);
    final province = tokens.first;
    final district = tokens.length > 1 ? tokens[1] : null;
    return (province, district);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Haritada Konum Seç', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildProvinceDistrictSelectors(theme),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _point,
                    initialZoom: 12.5,
                    onTap: (tapPosition, latLng) {
                      setState(() => _point = latLng);
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mobile',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _point,
                          radius: _radius,
                          useRadiusInMeter: true,
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          borderColor:
                              theme.colorScheme.primary.withOpacity(0.6),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _point,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kapsam', style: theme.textTheme.bodyLarge),
                Text(_radiusText(_radius)),
              ],
            ),
            Slider(
              value: _radius.clamp(100, 10000),
              min: 100,
              max: 10000,
              divisions: 99,
              label: _radiusText(_radius),
              onChanged: (value) => setState(() => _radius = value),
            ),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                  labelText: 'Adres etiketi (isteğe bağlı)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _LocationPickerResult(
                          point: _point,
                          radius: _radius,
                          label: _labelController.text.trim().isEmpty
                              ? null
                              : _labelController.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
