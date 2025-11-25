import '../../core/api_client.dart';
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
}
