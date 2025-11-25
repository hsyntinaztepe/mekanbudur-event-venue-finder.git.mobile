import 'package:flutter/material.dart';
import '../../data/models/vendor_profile_model.dart';
import '../../data/services/vendor_service.dart';

class VendorProvider extends ChangeNotifier {
  final VendorService _vendorService;
  
  VendorProfile? _profile;
  bool _isLoading = false;
  String? _error;

  VendorProvider(this._vendorService);

  VendorProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfile() async {
    _isLoading = true;
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
}
