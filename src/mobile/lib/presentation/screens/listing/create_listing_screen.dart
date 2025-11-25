import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/listing_provider.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  LatLng? _selectedPoint;
  double _selectedRadius = 1000;
  String? _addressLabel;

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
    _locationController.dispose();
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
          initialLabel: _addressLabel ??
              (_locationController.text.isNotEmpty
                  ? _locationController.text
                  : null),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPoint = result.point;
        _selectedRadius = result.radius;
        final label = result.label?.trim();
        _addressLabel = (label?.isNotEmpty ?? false) ? label : null;
        if (_addressLabel != null && _addressLabel!.isNotEmpty) {
          _locationController.text = _addressLabel!;
        } else {
          _locationController.text = _formatLatLng(result.point);
        }
      });
    }
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

      final locationText = _locationController.text.trim();
      final label = (_addressLabel?.trim().isNotEmpty ?? false)
          ? _addressLabel!.trim()
          : locationText;

      final success = await context.read<ListingProvider>().createListing(
            title: _titleController.text,
            description: _descriptionController.text,
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
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 3,
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
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Konum'),
                validator: (v) => v?.isEmpty == true ? 'Zorunlu' : null,
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
                          Text('Harita Konumu',
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

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  String _radiusText(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} km';
    }
    return '${value.round()} m';
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
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
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
