import '../services/api_service.dart';
import '../models/profile_update.dart';

class ProfileRepository {
  final ApiService _api = ApiService();

  Future<ProfileUpdate> getProfile() async {
    final data = await _api.get('/profile');
    return ProfileUpdate.fromJson(data);
  }

  Future<ProfileUpdate> updateProfile(ProfileUpdate profile) async {
    final data = await _api.put('/profile', profile.toJson());
    return ProfileUpdate.fromJson(data);
  }
}