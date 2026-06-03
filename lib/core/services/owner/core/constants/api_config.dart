/// API Configuration for Hotel Owner Flutter App
///
/// This file centralizes all API-related configuration including:
/// - Base URLs for different environments
/// - API endpoints
/// - Timeout settings
class ApiConfig {
  // ==================== BASE URLs ====================

  static const String baseUrl = 'http://209.50.241.46:2000/api';

  /// WebSocket URL for real-time features
  static const String wsUrl = 'ws://209.50.241.46:2000';

  static const String stagingUrl = 'http://209.50.241.46:2000/api';
  static const String productionUrl = 'http://209.50.241.46:2000/api';

  // ==================== AUTH (No Token Required) ====================

  static const String getHomeDataEndpoint = '/get-home-data';
  static const String getOtpEndpoint = '/get-otp';
  static const String verifyOtpEndpoint = '/verify-otp';
  static const String getPackageEndpoint = '/get-package';
  static const String getLanguagesEndpoint = '/get-languages';
  static const String userSignupEndpoint = '/user-signup';
  static const String getSystemSettingsEndpoint = '/get-system-settings';
  static const String appPaymentStatusEndpoint = '/app-payment-status';
  static const String getCustomFieldsEndpoint = '/get-customfields';
  static const String getItemEndpoint = '/get-item';
  static const String getSliderEndpoint = '/get-slider';
  static const String getReportReasonsEndpoint = '/get-report-reasons';
  static const String getCategoriesEndpoint = '/get-categories';
  static const String getParentCategoriesEndpoint = '/get-parent-categories';
  static const String getFeaturedSectionEndpoint = '/get-featured-section';
  static const String blogsEndpoint = '/blogs';
  static const String blogTagsEndpoint = '/blog-tags';
  static const String faqEndpoint = '/faq';
  static const String tipsEndpoint = '/tips';
  static const String countriesEndpoint = '/countries';
  static const String statesEndpoint = '/states';
  static const String citiesEndpoint = '/cities';
  static const String areasEndpoint = '/areas';
  static const String contactUsEndpoint = '/contact-us';
  static const String seoSettingsEndpoint = '/seo-settings';
  static const String getOwnerEndpoint = '/get-owner';
  static const String getLocationEndpoint = '/get-location';

  // ==================== HOTELS (Public) ====================

  static const String hotelsEndpoint = '/hotels';
  static const String hotelDetailsEndpoint = '/hotel-details'; // + /{id}
  static const String hotelPoliciesEndpoint = '/hotel-policies'; // + /{id}
  static const String hotelsNearbyEndpoint = '/hotels/nearby';
  static const String hotelMenuEndpoint = '/hotels'; // + /{hotelId}/menu
  static const String hotelGalleryEndpoint = '/hotels'; // + /{hotelId}/gallery
  static const String hotelBlackoutDatesEndpoint = '/hotels'; // + /{hotelId}/blackout-dates

  // ==================== HOTELS (Auth Required — Owner) ====================

  static const String myHotelsEndpoint = '/my-hotels';
  static const String ownerAnalyticsEndpoint = '/owner-analytics';
  static const String storeHotelEndpoint = '/store-hotel';
  static const String updateHotelEndpoint = '/update-hotel'; // + /{id}
  static const String deleteHotelEndpoint = '/delete-hotel'; // + /{id}
  static const String storeRoomTypeEndpoint = '/store-room-type';
  static const String updateRoomTypeEndpoint = '/update-room-type'; // + /{id}
  static const String deleteRoomTypeEndpoint = '/delete-room-type'; // + /{id}
  static const String storeRoomEndpoint = '/store-room';
  static const String updateRoomEndpoint = '/update-room'; // + /{id}
  static const String deleteRoomEndpoint = '/delete-room'; // + /{id}
  static const String updateBookingStatusEndpoint = '/update-booking-status'; // + /{id}
  static const String setDynamicPricingEndpoint = '/set-dynamic-pricing';

  // ==================== HOTEL OWNER PANEL ====================

  static const String ownerDashboardEndpoint = '/hotel-owner/dashboard';
  static const String dashboardAliasEndpoint = '/dashboard';
  static const String ownerAmenitiesEndpoint = '/hotel-owner/amenities';
  static const String ownerGalleryEndpoint = '/hotel-owner/gallery';
  static const String ownerBookingsEndpoint = '/hotel-owner/bookings';
  static const String ownerReportsEndpoint = '/hotel-owner/reports';
  static const String reportsAliasEndpoint = '/reports';
  static const String ownerAnalyticsPanelEndpoint = '/hotel-owner/analytics';
  static const String ownerAnalyticsAliasEndpoint = '/owner-analytics';
  static const String ownerReviewsEndpoint = '/hotel-owner/reviews';
  static const String ownerReviewReplyEndpoint = '/hotel-owner/reviews'; // + /{id}/reply
  static const String reviewRequestsSendEndpoint = '/review-requests/send';
  static const String ownerEarningsEndpoint = '/hotel-owner/earnings';
  static const String earningsAliasEndpoint = '/earnings';
  static const String ownerTransactionsEndpoint = '/hotel-owner/transactions';
  static const String ownerWithdrawalsEndpoint = '/hotel-owner/withdrawals';
  static const String ownerEarningsExportEndpoint = '/hotel-owner/earnings/export';
  static const String ownerTransactionsFilterEndpoint = '/hotel-owner/transactions/filter';
  static const String ownerOffersEndpoint = '/hotel-owner/offers';
  static const String ownerMenuEndpoint = '/hotel-owner/menu';
  static const String ownerOrdersEndpoint = '/hotel-owner/orders';
  static const String ownerOrderStatusEndpoint = '/hotel-owner/orders'; // + /{id}/status
  static const String ownerOrderAnalyticsEndpoint = '/hotel-owner/order-analytics';
  static const String ownerMediaEndpoint = '/hotel-owner/media';
  static const String ownerMediaImagesEndpoint = '/hotel-owner/media/images';
  static const String ownerMediaVideoEndpoint = '/hotel-owner/media/video';
  static const String ownerMediaVideoLinkEndpoint = '/hotel-owner/media/video-link';
  static const String ownerMediaReorderEndpoint = '/hotel-owner/media/reorder';
  static const String ownerVideosUploadEndpoint = '/hotel-owner/videos/upload';
  static const String ownerVideosLinkEndpoint = '/hotel-owner/videos/link';
  static const String ownerVideosEndpoint = '/hotel-owner/videos'; // + /{id} or /{id}/set-primary
  static const String ownerBlackoutDatesEndpoint = '/hotel-owner/blackout-dates';
  static const String ownerBlackoutDatesRangeEndpoint = '/hotel-owner/blackout-dates/range';
  static const String ownerChatAllEndpoint = '/chat/owner/all';
  static const String ownerBookingRequestsEndpoint = '/booking-requests/owner';

  // ==================== AUTH (Token Required) ====================

  static const String logoutEndpoint = '/logout';
  static const String notificationsReadEndpoint = '/notifications'; // + /{id}/read
  static const String notificationsReadAllEndpoint = '/notifications/read-all';
  static const String twoFaStatusEndpoint = '/2fa/status';
  static const String twoFaSetupEndpoint = '/2fa/setup';
  static const String twoFaVerifyEndpoint = '/2fa/verify';
  static const String twoFaValidateEndpoint = '/2fa/validate';
  static const String twoFaDisableEndpoint = '/2fa/disable';
  static const String twoFaBiometricToggleEndpoint = '/2fa/biometric/toggle';

  // ==================== HOTEL MANAGEMENT (Owner) ====================

  static const String hotelsMyAliasEndpoint = '/hotels/my';
  static const String hotelsRegisterAliasEndpoint = '/hotels/register';
  static const String hotelsAmenitiesAliasEndpoint = '/hotels'; // + /{id}/amenities

  // ==================== ROOM TYPES & ROOMS ====================

  static const String roomTypesEndpoint = '/room-types'; // POST create, PUT /{id}, DELETE /{id}
  static const String roomsEndpoint = '/rooms'; // POST create, PUT /{id}, DELETE /{id}

  // ==================== PRICING ====================

  static const String previewPriceEndpoint = '/preview-price';

  // ==================== AI PRICING ====================

  static const String aiPricingRulesEndpoint = '/ai-pricing/rules'; // GET list, POST save, DELETE /{id}
  static const String aiPricingSuggestEndpoint = '/ai-pricing/suggest';
  static const String aiPricingSuggestRangeEndpoint = '/ai-pricing/suggest-range';
  static const String aiPricingApplyEndpoint = '/ai-pricing/apply';
  static const String aiPricingAutoApplyEndpoint = '/ai-pricing/auto-apply';

  // ==================== QR CHECK-IN (Owner) ====================

  static const String checkinConfirmEndpoint = '/checkin/confirm';
  static const String checkinCheckoutEndpoint = '/checkin/checkout';
  static const String checkinTodayEndpoint = '/checkin/today';
  static const String checkinActiveGuestsEndpoint = '/checkin/active-guests';

  // ==================== TAXES ====================

  static const String taxesEndpoint = '/taxes'; // GET, POST, DELETE /{id}
  static const String taxesReportEndpoint = '/taxes/report';
  static const String taxesReportExportEndpoint = '/taxes/report/export';

  // ==================== ICAL / CHANNEL MANAGER ====================

  static const String icalChannelsEndpoint = '/ical/channels'; // GET, POST, DELETE /{id}, POST /{id}/sync
  static const String icalExportEndpoint = '/ical/export'; // + /{token}

  // ==================== AUTOMATED GUEST MESSAGING ====================

  static const String guestMessagingTemplatesEndpoint = '/guest-messaging/templates'; // GET, POST, DELETE /{id}
  static const String guestMessagingLogsEndpoint = '/guest-messaging/logs';
  static const String guestMessagingTestEndpoint = '/guest-messaging/test';

  // ==================== COMPETITOR BENCHMARKING ====================

  static const String competitorPricesEndpoint = '/competitor/prices'; // GET, POST, DELETE /{id}
  static const String competitorSummaryEndpoint = '/competitor/summary';
  static const String competitorParityCheckEndpoint = '/competitor/parity-check';
  static const String competitorTrendEndpoint = '/competitor/trend';

  // ==================== MULTI-CURRENCY ====================

  static const String currenciesEndpoint = '/currencies';
  static const String currenciesRatesMapEndpoint = '/currencies/rates-map';
  static const String currenciesConvertEndpoint = '/currencies/convert';
  static const String currenciesPreferenceEndpoint = '/currencies/preference';

  // ==================== RECOMMENDATIONS (Public) ====================

  static const String recommendationsTrendingEndpoint = '/recommendations/trending';
  static const String recommendationsNearbyPopularEndpoint = '/recommendations/nearby-popular';
  static const String recommendationsAlsoBookedEndpoint = '/recommendations/also-booked'; // + /{hotelId}

  // ==================== FILTERS (Public) ====================

  static const String filtersOptionsEndpoint = '/filters/options';
  static const String filtersAdvancedEndpoint = '/filters/advanced';
  static const String filtersSearchEndpoint = '/filters/search';

  // ==================== NEPAL PAYMENTS (Public Callbacks) ====================

  static const String khaltiCallbackEndpoint = '/payment/khalti/callback';
  static const String esewaCallbackEndpoint = '/payment/esewa/callback';
  static const String esewaFailureEndpoint = '/payment/esewa/failure';

  // ==================== QR CHECK-IN (Public) ====================

  static const String checkinScanEndpoint = '/checkin/scan'; // + /{token}

  // ==================== USER / PROFILE (Auth Required) ====================

  static const String updateProfileEndpoint = '/update-profile';
  static const String deleteUserEndpoint = '/delete-user';
  static const String getNotificationListEndpoint = '/get-notification-list';
  static const String getLimitsEndpoint = '/get-limits';
  static const String getPaymentSettingsEndpoint = '/get-payment-settings';
  static const String paymentIntentEndpoint = '/payment-intent';
  static const String paymentTransactionsEndpoint = '/payment-transactions';
  static const String inAppPurchaseEndpoint = '/in-app-purchase';
  static const String blockUserEndpoint = '/block-user';
  static const String unblockUserEndpoint = '/unblock-user';
  static const String blockedUsersEndpoint = '/blocked-users';
  static const String addReportsEndpoint = '/add-reports';
  static const String manageFavouriteEndpoint = '/manage-favourite';
  static const String getFavouriteItemEndpoint = '/get-favourite-item';
  static const String sendVerificationRequestEndpoint = '/send-verification-request';
  static const String verificationFieldsEndpoint = '/verification-fields';
  static const String verificationRequestEndpoint = '/verification-request';
  static const String bankTransferUpdateEndpoint = '/bank-transfer-update';

  // ==================== HOTEL BOOKING (Auth Required) ====================

  static const String createBookingEndpoint = '/create-booking';
  static const String confirmPaymentEndpoint = '/confirm-payment';
  static const String myBookingsEndpoint = '/my-bookings';
  static const String cancelBookingEndpoint = '/cancel-booking'; // + /{id}
  static const String rateHotelEndpoint = '/rate-hotel';
  static const String validateCouponEndpoint = '/validate-coupon';
  static const String invoiceDownloadEndpoint = '/invoice'; // + /{bookingId}/download
  static const String invoicePreviewEndpoint = '/invoice'; // + /{bookingId}/preview

  // ==================== IN-STAY ORDERING (Auth Required) ====================

  static const String ordersPlaceEndpoint = '/orders/place';
  static const String ordersMyOrdersEndpoint = '/orders/my-orders';
  static const String ordersCancelEndpoint = '/orders'; // + /{id}/cancel

  // ==================== QR CHECK-IN (Auth Required) ====================

  static const String checkinQrEndpoint = '/checkin/qr'; // + /{bookingId}

  // ==================== LOYALTY POINTS (Auth Required) ====================

  static const String loyaltyBalanceEndpoint = '/loyalty/balance';
  static const String loyaltyReferralCodeEndpoint = '/loyalty/referral-code';
  static const String loyaltyApplyReferralEndpoint = '/loyalty/apply-referral';

  // ==================== WAITLIST (Auth Required) ====================

  static const String waitlistJoinEndpoint = '/waitlist/join';
  static const String waitlistMyEndpoint = '/waitlist/my';
  static const String waitlistDeleteEndpoint = '/waitlist'; // + /{id}

  // ==================== BOOKING REQUESTS (Auth Required) ====================

  static const String bookingRequestsSpecialTimeEndpoint = '/booking-requests/special-time';
  static const String bookingRequestsRespondEndpoint = '/booking-requests'; // + /{id}/respond
  static const String bookingRequestsMyEndpoint = '/booking-requests/my';
  static const String bookingModificationsRequestEndpoint = '/booking-modifications/request';
  static const String bookingModificationsRespondEndpoint = '/booking-modifications'; // + /{id}/respond

  // ==================== GUEST-HOTEL CHAT (Auth Required) ====================

  static const String chatMessagesEndpoint = '/chat'; // + /{bookingId}/messages
  static const String chatSendEndpoint = '/chat/send';

  // ==================== PRICE ALERTS (Auth Required) ====================

  static const String priceAlertsCreateEndpoint = '/price-alerts';
  static const String priceAlertsMyEndpoint = '/price-alerts/my';
  static const String priceAlertsDeleteEndpoint = '/price-alerts'; // + /{id}

  // ==================== SUPPORT (Auth Required) ====================

  static const String supportTicketsCreateEndpoint = '/support/tickets';
  static const String supportTicketsListEndpoint = '/support/tickets';
  static const String supportTicketDetailEndpoint = '/support/tickets'; // + /{id}
  static const String supportTicketMessagesEndpoint = '/support/tickets'; // + /{id}/messages
  static const String supportChatStartEndpoint = '/support/chat/start';
  static const String supportChatGetEndpoint = '/support/chat'; // + /{token}
  static const String supportChatMessageEndpoint = '/support/chat'; // + /{token}/message
  static const String supportChatEndEndpoint = '/support/chat'; // + /{token}/end

  // ==================== AI CHATBOT (Auth Required) ====================

  static const String aiChatStartEndpoint = '/ai-chat/start';
  static const String aiChatMessageEndpoint = '/ai-chat/message';
  static const String aiChatHistoryEndpoint = '/ai-chat/history'; // + /{token}
  static const String aiChatEndEndpoint = '/ai-chat/end'; // + /{token}

  // ==================== NEPAL PAYMENTS (Auth Required) ====================

  static const String khaltiInitiateEndpoint = '/payment/khalti/initiate';
  static const String esewaInitiateEndpoint = '/payment/esewa/initiate';

  // ==================== RECOMMENDATIONS (Personalized, Auth Required) ====================

  static const String recommendationsForYouEndpoint = '/recommendations/for-you';

  // ==================== TIMEOUTS ====================

  /// Connection timeout in seconds
  static const int connectionTimeout = 30;

  /// Receive timeout in seconds
  static const int receiveTimeout = 30;

  /// Upload timeout in seconds (for image uploads)
  static const int uploadTimeout = 60;

  // ==================== HELPER METHODS ====================

  /// Get the full URL for an endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Get WebSocket URL for an endpoint
  static String getWsUrl(String endpoint) {
    return '$wsUrl$endpoint';
  }

  /// Build a parameterized endpoint path
  static String buildPath(String base, String param) {
    return '$base/$param';
  }
}
