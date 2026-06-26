import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class TwoFactorService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // GET /2fa/status - Get 2FA status
  Future<Map<String, dynamic>> getTwoFactorStatus() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.twoFaStatusEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'status': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load 2FA status'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load 2FA status'};
    }
  }

  // POST /2fa/setup - Setup 2FA
  Future<Map<String, dynamic>> setupTwoFactor({
    String? method, // 'sms', 'email', 'authenticator'
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final token = await _getToken();
      final data = <String, dynamic>{};
      if (method != null) data['method'] = method;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (email != null) data['email'] = email;
      
      final response = await ApiService.post(ApiConfig.twoFaSetupEndpoint, token: token, data: data);
      return response['success'] == true
          ? {'success': true, 'setup_data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to setup 2FA'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to setup 2FA'};
    }
  }

  // POST /2fa/verify - Verify 2FA code
  Future<Map<String, dynamic>> verifyTwoFactor({
    required String code,
    String? method,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.twoFaVerifyEndpoint,
          token: token,
          data: {
            'code': code,
            if (method != null) 'method': method,
          });
      return response['success'] == true
          ? {'success': true, 'verified': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Invalid 2FA code'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to verify 2FA code'};
    }
  }

  // POST /2fa/disable - Disable 2FA
  Future<Map<String, dynamic>> disableTwoFactor({
    required String password,
    String? verificationCode,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.twoFaDisableEndpoint,
          token: token,
          data: {
            'password': password,
            if (verificationCode != null) 'verification_code': verificationCode,
          });
      return response['success'] == true
          ? {'success': true, 'message': '2FA disabled successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to disable 2FA'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to disable 2FA'};
    }
  }

  // POST /2fa/validate - Validate 2FA for sensitive operations
  Future<Map<String, dynamic>> validateTwoFactor({
    required String code,
    required String operation, // 'login', 'payment', 'profile_change', etc.
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.twoFaValidateEndpoint,
          token: token,
          data: {
            'code': code,
            'operation': operation,
          });
      return response['success'] == true
          ? {'success': true, 'validated': true, 'session_token': response['data']['session_token']}
          : {'success': false, 'message': response['message'] ?? 'Invalid 2FA code'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to validate 2FA code'};
    }
  }

  // POST /2fa/biometric/toggle - Toggle biometric authentication
  Future<Map<String, dynamic>> toggleBiometricAuth({
    required bool enabled,
    String? biometricType, // 'fingerprint', 'face', 'voice'
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.twoFaBiometricToggleEndpoint,
          token: token,
          data: {
            'enabled': enabled,
            if (biometricType != null) 'biometric_type': biometricType,
          });
      return response['success'] == true
          ? {'success': true, 'biometric_enabled': enabled, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to toggle biometric authentication'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to toggle biometric authentication'};
    }
  }

  // Generate backup codes
  Future<Map<String, dynamic>> generateBackupCodes() async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.twoFaBackupCodesEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'backup_codes': response['data']['codes']}
          : {'success': false, 'message': response['message'] ?? 'Failed to generate backup codes'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to generate backup codes'};
    }
  }

  // Use backup code
  Future<Map<String, dynamic>> useBackupCode(String backupCode) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.twoFaUseBackupCodeEndpoint,
          token: token,
          data: {'backup_code': backupCode});
      return response['success'] == true
          ? {'success': true, 'verified': true}
          : {'success': false, 'message': response['message'] ?? 'Invalid backup code'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to use backup code'};
    }
  }

  // Send 2FA code
  Future<Map<String, dynamic>> sendTwoFactorCode({
    String? method, // 'sms', 'email'
    String? operation,
  }) async {
    try {
      final token = await _getToken();
      final data = <String, dynamic>{};
      if (method != null) data['method'] = method;
      if (operation != null) data['operation'] = operation;
      
      final response = await ApiService.post(ApiConfig.twoFaSendCodeEndpoint, token: token, data: data);
      return response['success'] == true
          ? {'success': true, 'message': '2FA code sent successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to send 2FA code'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send 2FA code'};
    }
  }

  // Get 2FA methods
  Future<Map<String, dynamic>> getTwoFactorMethods() async {
    try {
      final response = await ApiService.get(ApiConfig.twoFaMethodsEndpoint);
      return response['success'] == true
          ? {'success': true, 'methods': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load 2FA methods'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load 2FA methods'};
    }
  }

  // Update 2FA settings
  Future<Map<String, dynamic>> updateTwoFactorSettings({
    String? primaryMethod,
    String? backupMethod,
    bool? requireForLogin,
    bool? requireForPayments,
    bool? requireForProfileChanges,
  }) async {
    try {
      final token = await _getToken();
      final data = <String, dynamic>{};
      if (primaryMethod != null) data['primary_method'] = primaryMethod;
      if (backupMethod != null) data['backup_method'] = backupMethod;
      if (requireForLogin != null) data['require_for_login'] = requireForLogin;
      if (requireForPayments != null) data['require_for_payments'] = requireForPayments;
      if (requireForProfileChanges != null) data['require_for_profile_changes'] = requireForProfileChanges;
      
      final response = await ApiService.put(ApiConfig.twoFaSettingsEndpoint, token: token, data: data);
      return response['success'] == true
          ? {'success': true, 'settings': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update 2FA settings'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update 2FA settings'};
    }
  }

  // Get 2FA settings
  Future<Map<String, dynamic>> getTwoFactorSettings() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.twoFaSettingsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'settings': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load 2FA settings'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load 2FA settings'};
    }
  }

  // Check if 2FA is required for operation
  Future<Map<String, dynamic>> checkTwoFactorRequired(String operation) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.twoFaRequiredEndpoint,
          token: token,
          queryParams: {'operation': operation});
      return response['success'] == true
          ? {'success': true, 'required': response['data']['required'], 'methods': response['data']['methods']}
          : {'success': false, 'message': response['message'] ?? 'Failed to check 2FA requirement'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to check 2FA requirement'};
    }
  }

  // Get 2FA recovery options
  Future<Map<String, dynamic>> getRecoveryOptions() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.twoFaRecoveryOptionsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'options': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load recovery options'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load recovery options'};
    }
  }

  // Reset 2FA (for account recovery)
  Future<Map<String, dynamic>> resetTwoFactor({
    required String email,
    String? recoveryCode,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.twoFaResetEndpoint,
          data: {
            'email': email,
            if (recoveryCode != null) 'recovery_code': recoveryCode,
          });
      return response['success'] == true
          ? {'success': true, 'message': '2FA reset request submitted'}
          : {'success': false, 'message': response['message'] ?? 'Failed to reset 2FA'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to reset 2FA'};
    }
  }

  // Get active sessions
  Future<Map<String, dynamic>> getActiveSessions() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.activeSessionsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'sessions': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load sessions'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load sessions'};
    }
  }

  // Revoke a session
  Future<Map<String, dynamic>> revokeSession(String sessionId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.buildPath(ApiConfig.revokeSessionEndpoint, '$sessionId/revoke'),
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'message': 'Session revoked successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to revoke session'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to revoke session'};
    }
  }

  // Revoke all sessions except current
  Future<Map<String, dynamic>> revokeAllSessions() async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.revokeAllSessionsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'message': 'All sessions revoked successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to revoke sessions'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to revoke sessions'};
    }
  }
}