import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../models/public_vendor_model.dart';
import '../models/vendor_public_profile_model.dart';
import '../models/vendor_rating_summary_model.dart';
import '../models/vendor_review_model.dart';
import '../models/vendor_profile_model.dart';

class VendorService {
  final ApiClient _apiClient;

  VendorService(this._apiClient);

  Future<VendorProfile> getProfile() async {
    final response = await _apiClient.dio.get('/vendor/profile');
    return VendorProfile.fromJson(response.data);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _apiClient.dio.put('/vendor/profile', data: data);
  }

  Future<List<String>> uploadPhotos(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      return const <String>[];
    }

    final files = <MapEntry<String, MultipartFile>>[];
    for (final path in filePaths) {
      final normalizedPath = path.replaceAll('\\', '/');
      final fileName = normalizedPath.split('/').last;
      files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(path, filename: fileName),
        ),
      );
    }

    final formData = FormData();
    formData.files.addAll(files);

    final response = await _apiClient.dio.post(
      '/vendor/photos',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final body = response.data;
    if (body is Map<String, dynamic> && body['urls'] is List) {
      return (body['urls'] as List)
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    throw const FormatException('Fotoğraf yükleme yanıtı okunamadı');
  }

  Future<List<PublicVendor>> getPublicVendors() async {
    // Prefer `/api/vendors` (does not depend on Geo). Fallback to legacy `/api/vendors/map`.
    // ApiClient baseUrl already includes `/api`.
    Response<dynamic> response;
    try {
      response = await _apiClient.dio.get('/vendors');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        response = await _apiClient.dio.get('/vendors/map');
      } else {
        rethrow;
      }
    }
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PublicVendor.fromJson)
          .where((v) => v.userId.isNotEmpty && v.companyName.isNotEmpty)
          .toList(growable: false);
    }
    throw const FormatException('Vendor listesi okunamadı');
  }

  Future<VendorPublicProfile> getPublicVendorProfile(
      String vendorUserId) async {
    final response = await _apiClient.dio.get('/vendors/$vendorUserId');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return VendorPublicProfile.fromJson(data);
    }
    throw const FormatException('Vendor profili okunamadı');
  }

  Future<VendorRatingSummary> getVendorRating(String vendorUserId) async {
    final response = await _apiClient.dio.get('/vendors/$vendorUserId/rating');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return VendorRatingSummary.fromJson(data);
    }
    throw const FormatException('Vendor puanı okunamadı');
  }

  Future<List<VendorReview>> getVendorReviews(String vendorUserId) async {
    final response = await _apiClient.dio.get('/vendors/$vendorUserId/reviews');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(VendorReview.fromJson)
          .where((r) => r.id.isNotEmpty)
          .toList(growable: false);
    }
    throw const FormatException('Vendor yorumları okunamadı');
  }

  Future<void> askVendorQuestion(String vendorUserId, String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Soru boş olamaz');
    }

    await _apiClient.dio.post(
      '/vendors/$vendorUserId/questions',
      data: <String, dynamic>{'question': trimmed},
    );
  }
}
