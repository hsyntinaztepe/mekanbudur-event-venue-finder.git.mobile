import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../data/models/turkiye_location_model.dart';
import '../../../data/services/turkiye_location_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/vendor_provider.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _websiteController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final TurkiyeLocationService _locationService = TurkiyeLocationService();

  static const LatLng _defaultMapCenter = LatLng(41.015137, 28.97953);

  bool _isEditing = false;
  bool _isUploadingPhotos = false;
  LatLng? _selectedPoint;
  String? _addressLabel;
  List<String> _photoUrls = <String>[];
  Set<int> _selectedCategoryIds = <int>{};
  List<String> _initialCategoryNames = <String>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    await _ensureCategoriesLoaded();
    await _loadProfile();
  }

  Future<void> _ensureCategoriesLoaded() async {
    final listingProvider = context.read<ListingProvider>();
    if (listingProvider.categories.isEmpty) {
      await listingProvider.fetchCategories();
    }
  }

  Future<void> _loadProfile() async {
    await context.read<VendorProvider>().fetchProfile();
    if (!mounted) {
      return;
    }
    final profile = context.read<VendorProvider>().profile;
    if (profile != null) {
      setState(() {
        _isEditing = false;
      });
      _companyNameController.text = profile.companyName;
      _descriptionController.text = profile.description ?? '';
      _phoneNumberController.text = profile.phoneNumber ?? '';
      _websiteController.text = profile.website ?? '';

      setState(() {
        _photoUrls = List<String>.from(profile.photoUrlList);
        _initialCategoryNames = List<String>.from(profile.serviceCategoryNames);
        _addressLabel = profile.venueAddressLabel;
        if (profile.hasLocation) {
          _selectedPoint =
              LatLng(profile.venueLatitude!, profile.venueLongitude!);
        } else {
          _selectedPoint = null;
        }
      });

      _syncSelectedCategoriesWithNames();
    }
  }

  void _syncSelectedCategoriesWithNames() {
    if (_initialCategoryNames.isEmpty) {
      return;
    }
    final listingProvider = context.read<ListingProvider>();
    final categories = listingProvider.categories;
    if (categories.isEmpty) {
      return;
    }
    final normalized = _initialCategoryNames
        .map((name) => name.toLowerCase().trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    final mapped = categories
        .where((cat) => normalized.contains(cat.name.toLowerCase().trim()))
        .map((cat) => cat.id)
        .toSet();
    setState(() => _selectedCategoryIds = mapped);
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _phoneNumberController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _save({
    required VendorProvider vendorProvider,
    required ListingProvider listingProvider,
    required ScaffoldMessengerState messenger,
  }) async {
    if (!_isEditing) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String? serviceCategoriesCsv;
    if (_selectedCategoryIds.isNotEmpty) {
      final selectedNames = listingProvider.categories
          .where((cat) => _selectedCategoryIds.contains(cat.id))
          .map((cat) => cat.name)
          .toList();
      serviceCategoriesCsv = selectedNames.join(',');
    }

    final success = await vendorProvider.updateProfile({
      'companyName': _companyNameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'phoneNumber': _phoneNumberController.text.trim(),
      'website': _websiteController.text.trim(),
      'photoUrls': _photoUrls.isEmpty ? null : _photoUrls.join(','),
      'serviceCategoriesCsv': serviceCategoriesCsv,
      'venueLatitude': _selectedPoint?.latitude,
      'venueLongitude': _selectedPoint?.longitude,
      'venueAddressLabel':
          (_addressLabel?.trim().isNotEmpty ?? false) ? _addressLabel : null,
    });

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Profil güncellendi')),
      );
      setState(() {
        _isEditing = false;
      });
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            vendorProvider.error ?? 'Güncelleme başarısız',
          ),
        ),
      );
    }
  }

  Future<void> _pickAndUploadPhotos({
    required VendorProvider vendorProvider,
    required ScaffoldMessengerState messenger,
  }) async {
    if (!_isEditing) {
      return;
    }
    final files = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) {
      return;
    }

    setState(() => _isUploadingPhotos = true);
    try {
      final urls = await vendorProvider
          .uploadPhotos(files.map((file) => file.path).toList());
      if (!mounted) return;
      setState(() {
        _photoUrls = List<String>.from(_photoUrls)..addAll(urls);
      });
      messenger.showSnackBar(
        SnackBar(content: Text('${urls.length} fotoğraf eklendi')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Fotoğraf yüklenemedi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhotos = false);
      }
    }
  }

  void _removePhotoAt(int index) {
    if (!_isEditing) {
      return;
    }
    setState(() {
      _photoUrls = List<String>.from(_photoUrls)..removeAt(index);
    });
  }

  Future<void> _openLocationPicker() async {
    if (!_isEditing) {
      return;
    }
    final result = await showModalBottomSheet<_LocationPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: _VendorLocationPickerSheet(
          initialPoint: _selectedPoint ?? _defaultMapCenter,
          initialLabel: _addressLabel,
          locationService: _locationService,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPoint = result.point;
        _addressLabel = result.label;
      });
    }
  }

  void _showCategoryPicker() {
    if (!_isEditing) {
      return;
    }
    final categories = context.read<ListingProvider>().categories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori listesi yüklenemedi')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hizmet Kategorileri',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Tamam'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected =
                              _selectedCategoryIds.contains(category.id);
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(category.name),
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  _selectedCategoryIds.add(category.id);
                                } else {
                                  _selectedCategoryIds.remove(category.id);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _buildSelectedCategoriesText() {
    if (_selectedCategoryIds.isEmpty) {
      return 'Kategori seçmek için dokunun';
    }
    final listingProvider = context.read<ListingProvider>();
    final names = listingProvider.categories
        .where((cat) => _selectedCategoryIds.contains(cat.id))
        .map((cat) => cat.name)
        .toList();
    return names.join(', ');
  }

  String? _formatLatLng(LatLng? point) {
    if (point == null) return null;
    return 'Lat ${point.latitude.toStringAsFixed(4)}, Lng ${point.longitude.toStringAsFixed(4)}';
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
        title: const Text('Tedarikçi Profili'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            child: Text(_isEditing ? 'Bitti' : 'Düzenle'),
          ),
        ],
      ),
      body: Consumer2<VendorProvider, ListingProvider>(
        builder: (context, vendorProvider, listingProvider, child) {
          final isInitialLoading =
              vendorProvider.isLoading && vendorProvider.profile == null;
          if (isInitialLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionTitle(text: 'Temel Bilgiler'),
                    TextFormField(
                      controller: _companyNameController,
                      enabled: _isEditing,
                      decoration:
                          const InputDecoration(labelText: 'Şirket Adı'),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(labelText: 'Açıklama'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneNumberController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Telefon Numarası',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      enabled: _isEditing,
                      decoration:
                          const InputDecoration(labelText: 'Web Sitesi'),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(text: 'Hizmet Kategorileri'),
                    listingProvider.categories.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : (_isEditing
                            ? InkWell(
                                onTap: _showCategoryPicker,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Hizmet Kategorileri',
                                    suffixIcon:
                                        const Icon(Icons.arrow_drop_down),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _buildSelectedCategoriesText(),
                                    style: _selectedCategoryIds.isEmpty
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.white54)
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                  ),
                                ),
                              )
                            : InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Hizmet Kategorileri',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _buildSelectedCategoriesText(),
                                  style: _selectedCategoryIds.isEmpty
                                      ? Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white54)
                                      : Theme.of(context).textTheme.bodyMedium,
                                ),
                              )),
                    const SizedBox(height: 24),
                    const _SectionTitle(text: 'Fotoğraflar'),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_photoUrls.isEmpty)
                              const Text('Henüz fotoğraf eklenmedi')
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _photoUrls.length,
                                itemBuilder: (context, index) {
                                  final url = _photoUrls[index];
                                  return Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade800,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white54,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      if (_isEditing)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: InkWell(
                                            onTap: () => _removePhotoAt(index),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            const SizedBox(height: 16),
                            if (_isUploadingPhotos)
                              const LinearProgressIndicator(),
                            const SizedBox(height: 12),
                            if (_isEditing)
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _isUploadingPhotos
                                          ? null
                                          : () => _pickAndUploadPhotos(
                                                vendorProvider: vendorProvider,
                                                messenger: ScaffoldMessenger.of(
                                                  context,
                                                ),
                                              ),
                                      icon: const Icon(Icons.add_a_photo),
                                      label: const Text('Fotoğraf Yükle'),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(text: 'Konum'),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Haritadan seç'),
                                TextButton.icon(
                                  onPressed:
                                      _isEditing ? _openLocationPicker : null,
                                  icon: const Icon(Icons.map_outlined),
                                  label: Text(
                                    _selectedPoint == null ? 'Seç' : 'Düzenle',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_selectedPoint == null)
                              const Text(
                                'Henüz konum seçilmedi. Haritadan seçim yapın.',
                              )
                            else ...[
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter:
                                          _selectedPoint ?? _defaultMapCenter,
                                      initialZoom: 14,
                                      interactionOptions: InteractionOptions(
                                        flags: _isEditing
                                            ? (InteractiveFlag.pinchZoom |
                                                InteractiveFlag.drag)
                                            : InteractiveFlag.none,
                                      ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.evently.mobile',
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
                              const SizedBox(height: 12),
                              if (_addressLabel?.isNotEmpty ?? false)
                                Text('Adres etiketi: $_addressLabel'),
                              Text(_formatLatLng(_selectedPoint!) ?? ''),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_isEditing)
                      FilledButton(
                        onPressed: vendorProvider.isLoading
                            ? null
                            : () => _save(
                                  vendorProvider: vendorProvider,
                                  listingProvider: listingProvider,
                                  messenger: ScaffoldMessenger.of(context),
                                ),
                        child: vendorProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Kaydet'),
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Çıkış Yap'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _LocationPickerResult {
  final LatLng point;
  final String? label;
  const _LocationPickerResult({required this.point, this.label});
}

class _VendorLocationPickerSheet extends StatefulWidget {
  final LatLng initialPoint;
  final String? initialLabel;
  final TurkiyeLocationService locationService;

  const _VendorLocationPickerSheet({
    required this.initialPoint,
    required this.locationService,
    this.initialLabel,
  });

  @override
  State<_VendorLocationPickerSheet> createState() =>
      _VendorLocationPickerSheetState();
}

class _VendorLocationPickerSheetState
    extends State<_VendorLocationPickerSheet> {
  late LatLng _tempPoint = widget.initialPoint;
  late final TextEditingController _labelController =
      TextEditingController(text: widget.initialLabel);
  late final Future<List<TurkiyeProvince>> _provinceFuture =
      widget.locationService.fetchProvinces();
  final MapController _mapController = MapController();
  TurkiyeProvince? _selectedProvince;
  TurkiyeDistrict? _selectedDistrict;
  bool _isDistrictLookupLoading = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _moveMap(LatLng point, {double zoom = 13}) {
    _mapController.move(point, zoom);
    setState(() => _tempPoint = point);
  }

  Future<void> _onDistrictSelected(TurkiyeDistrict? district) async {
    setState(() => _selectedDistrict = district);
    if (district == null) {
      return;
    }

    LatLng? target;
    if (district.latitude != null && district.longitude != null) {
      target = LatLng(district.latitude!, district.longitude!);
    } else if (_selectedProvince != null) {
      setState(() => _isDistrictLookupLoading = true);
      target = await widget.locationService.fetchDistrictCoordinates(
        provinceName: _selectedProvince!.name,
        districtName: district.name,
      );
      if (mounted) {
        setState(() => _isDistrictLookupLoading = false);
      }
    }

    if (target != null) {
      _moveMap(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Konumu Seç', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            FutureBuilder<List<TurkiyeProvince>>(
              future: _provinceFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'İl/ilçe verileri yüklenemedi: ${snapshot.error}',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final provinces = snapshot.data!;
                return Column(
                  children: [
                    DropdownButtonFormField<TurkiyeProvince>(
                      value: _selectedProvince,
                      decoration: const InputDecoration(labelText: 'İl'),
                      items: provinces
                          .map((province) => DropdownMenuItem(
                                value: province,
                                child: Text(province.name),
                              ))
                          .toList(),
                      onChanged: (province) {
                        setState(() {
                          _selectedProvince = province;
                          _selectedDistrict = null;
                        });
                        if (province?.latitude != null &&
                            province?.longitude != null) {
                          _moveMap(
                            LatLng(province!.latitude!, province.longitude!),
                            zoom: 9,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TurkiyeDistrict>(
                      value: _selectedDistrict,
                      decoration: const InputDecoration(labelText: 'İlçe'),
                      items: (_selectedProvince?.districts ??
                              const <TurkiyeDistrict>[])
                          .map((district) => DropdownMenuItem(
                                value: district,
                                child: Text(district.name),
                              ))
                          .toList(),
                      onChanged: _onDistrictSelected,
                    ),
                    if (_isDistrictLookupLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _tempPoint,
                    initialZoom: 12,
                    minZoom: 5,
                    maxZoom: 18,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                    onTap: (tapPosition, latLng) {
                      setState(() => _tempPoint = latLng);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.evently.mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _tempPoint,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            size: 36,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Adres etiketi (opsiyonel)',
                hintText: 'Örn. Ankara, Çankaya Ofis',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final labelText = _labelController.text.trim();
                Navigator.of(context).pop(
                  _LocationPickerResult(
                    point: _tempPoint,
                    label: labelText.isEmpty ? null : labelText,
                  ),
                );
              },
              child: const Text('Konumu Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
