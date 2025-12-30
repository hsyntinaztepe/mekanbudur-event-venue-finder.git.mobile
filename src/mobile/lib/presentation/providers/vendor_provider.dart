import 'package:flutter/material.dart';
import '../../data/models/public_vendor_model.dart';
import '../../data/models/vendor_profile_model.dart';
import '../../data/services/vendor_service.dart';

class VendorProvider extends ChangeNotifier {
  final VendorService _vendorService;

  VendorProfile? _profile;
  bool _isLoading = false;
  String? _error;

  final Map<String, PublicVendor> _publicVendorsById = <String, PublicVendor>{};
  bool _isPublicVendorsLoading = false;
  String? _publicVendorsError;
  bool _publicVendorsLoaded = false;

  VendorProvider(this._vendorService);

  VendorProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, PublicVendor> get publicVendorsById =>
      Map<String, PublicVendor>.unmodifiable(_publicVendorsById);
  bool get isPublicVendorsLoading => _isPublicVendorsLoading;
  String? get publicVendorsError => _publicVendorsError;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _vendorService.getProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _vendorService.updateProfile(data);
      await fetchProfile(); // Refresh
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

  Future<List<String>> uploadPhotos(List<String> filePaths) async {
    try {
      final urls = await _vendorService.uploadPhotos(filePaths);
      _error = null;
      return urls;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchPublicVendors({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _publicVendorsLoaded &&
        _publicVendorsById.isNotEmpty) {
      return;
    }

    _isPublicVendorsLoading = true;
    _publicVendorsError = null;
    notifyListeners();

    try {
      final vendors = await _vendorService.getPublicVendors();
      _publicVendorsById
        ..clear()
        ..addEntries(vendors.map((v) => MapEntry(v.userId, v)));
      _publicVendorsLoaded = true;
    } catch (e) {
      _publicVendorsError = e.toString();
    } finally {
      _isPublicVendorsLoading = false;
      notifyListeners();
    }
  }
}
