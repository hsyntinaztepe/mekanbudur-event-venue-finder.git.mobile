import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/public_vendor_model.dart';
import '../../data/models/vendor_public_profile_model.dart';
import '../../data/models/vendor_review_model.dart';
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

  final Map<String, VendorPublicProfile> _publicProfilesByVendorId =
      <String, VendorPublicProfile>{};
  final Map<String, List<VendorReview>> _reviewsByVendorId =
      <String, List<VendorReview>>{};

  VendorProvider(this._vendorService);

  VendorProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, PublicVendor> get publicVendorsById =>
      Map<String, PublicVendor>.unmodifiable(_publicVendorsById);
  bool get isPublicVendorsLoading => _isPublicVendorsLoading;
  String? get publicVendorsError => _publicVendorsError;

  VendorPublicProfile? publicProfileFor(String vendorUserId) =>
      _publicProfilesByVendorId[vendorUserId];

  List<VendorReview> reviewsFor(String vendorUserId) =>
      _reviewsByVendorId[vendorUserId] ?? const <VendorReview>[];

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

  Future<VendorPublicProfile> fetchPublicVendorProfile(
    String vendorUserId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _publicProfilesByVendorId.containsKey(vendorUserId)) {
      return _publicProfilesByVendorId[vendorUserId]!;
    }

    try {
      final profile = await _vendorService.getPublicVendorProfile(vendorUserId);
      _publicProfilesByVendorId[vendorUserId] = profile;
      notifyListeners();
      return profile;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final fallback = _buildFallbackProfile(vendorUserId);
        if (fallback != null) {
          _publicProfilesByVendorId[vendorUserId] = fallback;
          notifyListeners();
          return fallback;
        }
      }
      rethrow;
    }
  }

  Future<List<VendorReview>> fetchVendorReviews(
    String vendorUserId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _reviewsByVendorId.containsKey(vendorUserId)) {
      return _reviewsByVendorId[vendorUserId]!;
    }

    try {
      final list = await _vendorService.getVendorReviews(vendorUserId);
      _reviewsByVendorId[vendorUserId] = list;
      notifyListeners();
      return list;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _reviewsByVendorId[vendorUserId] = const <VendorReview>[];
        notifyListeners();
        return const <VendorReview>[];
      }
      rethrow;
    }
  }

  Future<void> askQuestion(String vendorUserId, String question) async {
    await _vendorService.askVendorQuestion(vendorUserId, question);
  }

  VendorPublicProfile? _buildFallbackProfile(String vendorUserId) {
    final vendor = _publicVendorsById[vendorUserId];
    if (vendor == null) return null;

    return VendorPublicProfile(
      vendorUserId: vendorUserId,
      profileId: vendorUserId,
      companyName: vendor.companyName,
      displayName: vendor.companyName,
      serviceCategories: vendor.categoryList,
      suitableForCsv: null,
      isVerified: vendor.isVerified,
      description: vendor.description,
      venueType: null,
      capacity: null,
      priceRange: null,
      phoneNumber: null,
      website: null,
      photoUrls: vendor.photoUrls,
      averageRating: vendor.averageRating,
      ratingCount: vendor.ratingCount,
      latitude: vendor.latitude,
      longitude: vendor.longitude,
      addressLabel: vendor.addressLabel ??
          'Detay bilgisi sunucuda bulunamadı. Gösterilen veriler liste kaynağından geliyor.',
    );
  }
}
