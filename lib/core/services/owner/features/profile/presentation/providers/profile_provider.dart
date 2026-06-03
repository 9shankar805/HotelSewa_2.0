import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/services/real_auth_service.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;

  ProfileProvider(this._profileService);

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfileData() async {
    _setLoading(true);
    _clearError();

    try {
      // First try to load from local storage
      final localUserData = await RealAuthService.getUserData();
      debugPrint('📱 Local user data: $localUserData');
      
      if (localUserData != null) {
        _user = User.fromJson(localUserData);
        debugPrint('✅ User loaded from local: ${_user?.name}, Phone: ${_user?.phoneNumber}');
        notifyListeners();
      }
      
      // Then fetch fresh data from API
      final userData = await _profileService.getUserProfile();
      debugPrint('🌐 API user data: $userData');
      
      if (userData['success'] == true && userData['data'] != null) {
        _user = User.fromJson(userData['data']);
        debugPrint('✅ User loaded from API: ${_user?.name}, Phone: ${_user?.phoneNumber}');
      }
    } catch (e) {
      debugPrint('❌ Failed to load profile: ${e.toString()}');
      // Try to use local data if API fails
      final localUserData = await RealAuthService.getUserData();
      if (localUserData != null) {
        _user = User.fromJson(localUserData);
      } else {
        _setError('Failed to load profile: ${e.toString()}');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedData = await _profileService.updateProfile(profileData);
      _user = User.fromJson(updatedData);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfilePicture({required bool fromCamera}) async {
    _setLoading(true);
    _clearError();

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        debugPrint('📸 Image selected: ${image.path}');
        final userName = _user?.name ?? 'User';
        final response = await _profileService.uploadProfilePicture(image.path, userName);
        debugPrint('✅ Upload response: $response');
        
        if (_user != null) {
          final imageUrl = response['imageUrl'] ?? response['user']?['profileImage'];
          debugPrint('🖼️ Image URL: $imageUrl');
          _user = _user!.copyWith(profileImageUrl: imageUrl);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ Upload error: ${e.toString()}');
      _setError('Failed to update profile picture: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeProfilePicture() async {
    _setLoading(true);
    _clearError();

    try {
      await _profileService.removeProfilePicture();
      
      if (_user != null) {
        _user = _user!.copyWith(profileImageUrl: null);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to remove profile picture: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _profileService.logout();
      
      // Clear local data
      _user = null;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to logout: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
