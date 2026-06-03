import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class UserService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // GET /profile/stats - User profile statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.profileStatsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'stats': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load user stats'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load user stats'};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.updateProfileEndpoint, token: token, data: data);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update profile'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile'};
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete(ApiConfig.deleteUserEndpoint, token: token);
      return response['success'] == true
          ? {'success': true}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete account'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete account'};
    }
  }

  Future<Map<String, dynamic>> getLimits() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.getLimitsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to get limits'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get limits'};
    }
  }

  Future<Map<String, dynamic>> blockUser(String userId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.blockUserEndpoint, token: token, data: {'user_id': userId});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to block user'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to block user'};
    }
  }

  Future<Map<String, dynamic>> unblockUser(String userId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.unblockUserEndpoint, token: token, data: {'user_id': userId});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to unblock user'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to unblock user'};
    }
  }

  Future<Map<String, dynamic>> getBlockedUsers() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.blockedUsersEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to get blocked users'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get blocked users'};
    }
  }

  Future<Map<String, dynamic>> addReport(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.addReportsEndpoint, token: token, data: data);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to submit report'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit report'};
    }
  }

  Future<Map<String, dynamic>> sendVerificationRequest(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.sendVerificationRequestEndpoint, token: token, data: data);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to send verification request'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send verification request'};
    }
  }

  Future<Map<String, dynamic>> getVerificationFields() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.verificationFieldsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to get verification fields'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get verification fields'};
    }
  }

  Future<Map<String, dynamic>> getVerificationRequest() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.verificationRequestEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to get verification request'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get verification request'};
    }
  }

  Future<Map<String, dynamic>> bankTransferUpdate(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.bankTransferUpdateEndpoint, token: token, data: data);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update bank transfer'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update bank transfer'};
    }
  }

  // GET /profile/travel-preferences - User travel preferences
  Future<Map<String, dynamic>> getTravelPreferences() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.travelPreferencesEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'preferences': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load travel preferences'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load travel preferences'};
    }
  }

  // PUT /profile/travel-preferences - Update user travel preferences
  Future<Map<String, dynamic>> updateTravelPreferences(Map<String, dynamic> preferences) async {
    try {
      final token = await _getToken();
      final response = await ApiService.put(ApiConfig.travelPreferencesEndpoint, token: token, data: preferences);
      return response['success'] == true
          ? {'success': true, 'message': 'Travel preferences updated successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to update travel preferences'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update travel preferences'};
    }
  }

  // GET /profile/addresses - User addresses
  Future<Map<String, dynamic>> getAddresses() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.profileAddressesEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'addresses': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load addresses'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load addresses'};
    }
  }

  // POST /profile/addresses - Add new address
  Future<Map<String, dynamic>> addAddress(Map<String, dynamic> addressData) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.profileAddressesEndpoint, token: token, data: addressData);
      return response['success'] == true
          ? {'success': true, 'address': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to add address'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add address'};
    }
  }

  // DELETE /profile/addresses/{id} - Delete address
  Future<Map<String, dynamic>> deleteAddress(String addressId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete('${ApiConfig.profileAddressesEndpoint}/$addressId', token: token);
      return response['success'] == true
          ? {'success': true, 'message': 'Address deleted successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete address'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete address'};
    }
  }

  // GET /profile/linked-accounts - User linked social accounts
  Future<Map<String, dynamic>> getLinkedAccounts() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.linkedAccountsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'accounts': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load linked accounts'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load linked accounts'};
    }
  }

  // POST /profile/link-social - Link social account
  Future<Map<String, dynamic>> linkSocialAccount(String provider, String socialToken) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.linkSocialEndpoint, 
          token: token, 
          data: {'provider': provider, 'token': socialToken});
      return response['success'] == true
          ? {'success': true, 'message': 'Account linked successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to link account'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to link account'};
    }
  }

  // DELETE /profile/linked-accounts/{provider} - Unlink social account
  Future<Map<String, dynamic>> unlinkSocialAccount(String provider) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete('${ApiConfig.linkedAccountsEndpoint}/$provider', token: token);
      return response['success'] == true
          ? {'success': true, 'message': 'Account unlinked successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to unlink account'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to unlink account'};
    }
  }

  // GET /notification-preferences - User notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.notificationPreferencesEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'preferences': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load notification preferences'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load notification preferences'};
    }
  }

  // PUT /notification-preferences - Update notification preferences
  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    try {
      final token = await _getToken();
      final response = await ApiService.put(ApiConfig.notificationPreferencesEndpoint, token: token, data: preferences);
      return response['success'] == true
          ? {'success': true, 'message': 'Notification preferences updated successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to update notification preferences'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update notification preferences'};
    }
  }
}
