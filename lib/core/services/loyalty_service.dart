import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class LoyaltyService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // GET /loyalty/balance - Get loyalty balance
  Future<Map<String, dynamic>> getLoyaltyBalance() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.loyaltyBalanceEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'balance': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load loyalty balance'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load loyalty balance'};
    }
  }

  // GET /loyalty/referral-code - Get referral code
  Future<Map<String, dynamic>> getReferralCode() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.loyaltyReferralCodeEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'referral_code': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load referral code'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load referral code'};
    }
  }

  // POST /loyalty/apply-referral - Apply referral code
  Future<Map<String, dynamic>> applyReferralCode(String referralCode) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.loyaltyApplyReferralEndpoint,
          token: token,
          data: {'referral_code': referralCode});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to apply referral code'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to apply referral code'};
    }
  }

  // Get loyalty points history
  Future<Map<String, dynamic>> getLoyaltyHistory({
    int? page,
    int? limit,
    String? type, // 'earned', 'redeemed', 'all'
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (type != null) queryParams['type'] = type;
      
      final response = await ApiService.get(ApiConfig.loyaltyHistoryEndpoint,
          token: token,
          queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'history': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load loyalty history'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load loyalty history'};
    }
  }

  // Redeem loyalty points
  Future<Map<String, dynamic>> redeemPoints({
    required int points,
    required String redeemType, // 'discount', 'cashback', 'gift'
    String? bookingId,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.loyaltyRedeemEndpoint,
          token: token,
          data: {
            'points': points,
            'redeem_type': redeemType,
            if (bookingId != null) 'booking_id': bookingId,
          });
      return response['success'] == true
          ? {'success': true, 'redemption': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to redeem points'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to redeem points'};
    }
  }

  // Get loyalty program details
  Future<Map<String, dynamic>> getLoyaltyProgram() async {
    try {
      final response = await ApiService.get(ApiConfig.loyaltyProgramEndpoint);
      return response['success'] == true
          ? {'success': true, 'program': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load loyalty program'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load loyalty program'};
    }
  }

  // Get loyalty tiers
  Future<Map<String, dynamic>> getLoyaltyTiers() async {
    try {
      final response = await ApiService.get(ApiConfig.loyaltyTiersEndpoint);
      return response['success'] == true
          ? {'success': true, 'tiers': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load loyalty tiers'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load loyalty tiers'};
    }
  }

  // Get user's loyalty tier
  Future<Map<String, dynamic>> getUserTier() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.loyaltyUserTierEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'tier': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load user tier'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load user tier'};
    }
  }

  // Get referral statistics
  Future<Map<String, dynamic>> getReferralStats() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.loyaltyReferralStatsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'stats': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load referral stats'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load referral stats'};
    }
  }

  // Get available rewards
  Future<Map<String, dynamic>> getAvailableRewards() async {
    try {
      final response = await ApiService.get(ApiConfig.loyaltyRewardsEndpoint);
      return response['success'] == true
          ? {'success': true, 'rewards': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load available rewards'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load available rewards'};
    }
  }

  // Calculate points for booking
  Future<Map<String, dynamic>> calculatePointsForBooking({
    required double bookingAmount,
    String? hotelId,
  }) async {
    try {
      final queryParams = <String, String>{
        'booking_amount': bookingAmount.toString(),
      };
      if (hotelId != null) queryParams['hotel_id'] = hotelId;
      
      final response = await ApiService.get(ApiConfig.loyaltyCalculatePointsEndpoint, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'points': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to calculate points'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to calculate points'};
    }
  }

  // Get points value in currency
  Future<Map<String, dynamic>> getPointsValue(int points) async {
    try {
      final response = await ApiService.get(ApiConfig.loyaltyPointsValueEndpoint, queryParams: {'points': points.toString()});
      return response['success'] == true
          ? {'success': true, 'value': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to get points value'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get points value'};
    }
  }

  // Share referral code
  Future<Map<String, dynamic>> shareReferralCode(String platform) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.loyaltyShareReferralEndpoint,
          token: token,
          data: {'platform': platform});
      return response['success'] == true
          ? {'success': true, 'share_data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to share referral code'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to share referral code'};
    }
  }


  // Get loyalty dashboard data
  Future<Map<String, dynamic>> getLoyaltyDashboard() async {
    try {
      final results = <String, dynamic>{};
      
      // Get balance
      final balanceResult = await getLoyaltyBalance();
      if (balanceResult['success'] == true) {
        results['balance'] = balanceResult['balance'];
      }
      
      // Get referral code
      final referralResult = await getReferralCode();
      if (referralResult['success'] == true) {
        results['referral_code'] = referralResult['referral_code'];
      }
      
      // Get user tier
      final tierResult = await getUserTier();
      if (tierResult['success'] == true) {
        results['tier'] = tierResult['tier'];
      }
      
      // Get referral stats
      final statsResult = await getReferralStats();
      if (statsResult['success'] == true) {
        results['referral_stats'] = statsResult['stats'];
      }
      
      // Get recent history
      final historyResult = await getLoyaltyHistory(limit: 5);
      if (historyResult['success'] == true) {
        results['recent_history'] = historyResult['history'];
      }
      
      return {'success': true, 'dashboard': results};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load loyalty dashboard'};
    }
  }

  // Check if user can redeem points
  Future<Map<String, dynamic>> canRedeemPoints(int points) async {
    try {
      final balanceResult = await getLoyaltyBalance();
      if (balanceResult['success'] == true) {
        final balance = balanceResult['balance']['points'] ?? 0;
        final canRedeem = balance >= points;
        return {
          'success': true,
          'can_redeem': canRedeem,
          'current_balance': balance,
          'required_points': points,
          'shortfall': canRedeem ? 0 : (points - balance),
        };
      }
      return balanceResult;
    } catch (e) {
      return {'success': false, 'message': 'Failed to check redemption eligibility'};
    }
  }
}