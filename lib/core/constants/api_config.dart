/// API Configuration for HotelSewa App
class ApiConfig {
  // ==================== BASE URLs ====================

  static const String baseUrl = 'http://209.50.241.46:2000/api';
  static const String wsUrl = 'ws://209.50.241.46:2000';
  static const String stagingUrl = 'http://209.50.241.46:2000/api';
  static const String productionUrl = 'http://209.50.241.46:2000/api';

  // ==================== 1. AUTHENTICATION ====================

  static const String getOtpEndpoint = '/get-otp';
  static const String verifyOtpEndpoint = '/verify-otp';
  static const String forgotPasswordEndpoint = '/forgot-password';
  static const String resetPasswordEndpoint = '/reset-password';
  static const String logoutEndpoint = '/logout';
  static const String switchRoleEndpoint = '/switch-role';
  static const String userSignupEndpoint = '/user-signup';
  static const String searchHistoryEndpoint = '/search-history';

  // ==================== 2. USER PROFILE ====================

  static const String updateProfileEndpoint = '/update-profile';
  static const String deleteUserEndpoint = '/delete-user';
  static const String getOwnerEndpoint = '/get-owner';
  static const String profileStatsEndpoint = '/profile/stats';
  static const String travelPreferencesEndpoint = '/profile/travel-preferences';
  static const String profileAddressesEndpoint = '/profile/addresses';
  static const String linkedAccountsEndpoint = '/profile/linked-accounts';
  static const String linkSocialEndpoint = '/profile/link-social';
  static const String notificationPreferencesEndpoint = '/notification-preferences';
  static const String userPreferencesEndpoint = '/user/preferences';
  static const String paymentMethodsEndpoint = '/payment-methods';
  static const String walletEndpoint = '/wallet';

  // ==================== 3. HOTELS — BROWSE & SEARCH ====================

  static const String hotelsEndpoint = '/hotels';
  static const String hotelDetailsEndpoint = '/hotel-details'; // + /{id}
  static const String hotelPoliciesEndpoint = '/hotel-policies'; // + /{id}
  static const String hotelsNearbyEndpoint = '/hotels/nearby';
  static const String hotelGalleryEndpoint = '/hotels'; // + /{hotelId}/gallery
  static const String hotelVideosEndpoint = '/hotels'; // + /{hotelId}/videos
  static const String hotelBlackoutDatesEndpoint = '/hotels'; // + /{hotelId}/blackout-dates
  static const String hotelPackagesEndpoint = '/hotels'; // + /{hotelId}/packages
  static const String hotelAddonsEndpoint = '/hotels'; // + /{hotelId}/addons
  static const String hotelActivitiesEndpoint = '/hotels'; // + /{hotelId}/activities
  static const String hotelEventSpacesEndpoint = '/hotels'; // + /{hotelId}/event-spaces
  static const String hotelLongStayRatesEndpoint = '/hotels'; // + /{hotelId}/long-stay-rates
  static const String hotelEcoInfoEndpoint = '/hotels'; // + /{hotelId}/eco-info
  static const String hotelMenuEndpoint = '/hotels'; // + /{hotelId}/menu
  static const String hotelsCompareEndpoint = '/hotels/compare';
  static const String roomTypesEndpoint = '/room-types';
  static const String roomTypesGalleryEndpoint = '/room-types'; // + /{id}/gallery
  static const String roomTypesVideosEndpoint = '/room-types'; // + /{id}/videos
  static const String roomTypesMediaEndpoint = '/room-types'; // + /{id}/media/...
  static const String roomTypeGalleryEndpoint = '/room-types'; // + /{roomTypeId}/gallery
  static const String roomTypeVideosEndpoint = '/room-types'; // + /{roomTypeId}/videos
  static const String getHomeDataEndpoint = '/get-home-data';
  static const String flashSalesEndpoint = '/flash-sales';
  static const String membershipsEndpoint = '/memberships';
  static const String insurancePlansEndpoint = '/insurance/plans';
  static const String dealsEndpoint = '/deals';
  static const String getPackagesEndpoint = '/get-package';
  static const String getFavouriteItemEndpoint = '/get-favourite-item';
  static const String manageFavouriteEndpoint = '/manage-favourite';

  // ==================== 4. HOTEL MANAGEMENT (OWNER) ====================

  static const String myHotelsEndpoint = '/my-hotels';
  static const String storeHotelEndpoint = '/store-hotel';
  static const String updateHotelEndpoint = '/update-hotel'; // + /{id}
  static const String deleteHotelEndpoint = '/delete-hotel'; // + /{id}
  static const String updateHotelAmenitiesEndpoint = '/hotels'; // + /{id}/amenities
  static const String recordHotelViewEndpoint = '/hotels'; // + /{id}/view
  static const String recentlyViewedHotelsEndpoint = '/hotels/recently-viewed';

  // ==================== 5. ROOM TYPES ====================

  static const String storeRoomTypeEndpoint = '/store-room-type';
  static const String updateRoomTypeEndpoint = '/update-room-type'; // + /{id}
  static const String deleteRoomTypeEndpoint = '/delete-room-type'; // + /{id}

  // ==================== 6. ROOMS ====================

  static const String storeRoomEndpoint = '/store-room';
  static const String updateRoomEndpoint = '/update-room'; // + /{id}
  static const String deleteRoomEndpoint = '/delete-room'; // + /{id}

  // ==================== 7. BOOKINGS (GUEST) ====================

  static const String createBookingEndpoint = '/create-booking';
  static const String confirmPaymentEndpoint = '/confirm-payment';
  static const String myBookingsEndpoint = '/my-bookings';
  static const String cancelBookingEndpoint = '/cancel-booking'; // + /{id}
  static const String previewPriceEndpoint = '/preview-price';
  static const String bookingRefundStatusEndpoint = '/bookings'; // + /{id}/refund-status
  static const String myPendingReviewsEndpoint = '/my-pending-reviews';

  // ==================== 8. BOOKING MANAGEMENT (OWNER) ====================

  static const String ownerBookingsEndpoint = '/hotel-owner/bookings';
  static const String updateBookingStatusEndpoint = '/update-booking-status'; // + /{id}
  static const String setDynamicPricingEndpoint = '/set-dynamic-pricing';
  static const String ownerManualBookingEndpoint = '/hotel-owner/bookings/manual';

  // ==================== 9. PAYMENTS ====================

  static const String paymentIntentEndpoint = '/payment-intent';
  static const String paymentTransactionsEndpoint = '/payment-transactions';
  static const String bankTransferUpdateEndpoint = '/bank-transfer-update';
  static const String getPaymentSettingsEndpoint = '/get-payment-settings';

  // ==================== 10. NEPAL PAYMENTS — KHALTI & ESEWA ====================

  static const String khaltiInitiateEndpoint = '/payment/khalti/initiate';
  static const String esewaInitiateEndpoint = '/payment/esewa/initiate';
  static const String khaltiCallbackEndpoint = '/payment/khalti/callback';
  static const String esewaCallbackEndpoint = '/payment/esewa/callback';
  static const String esewaFailureEndpoint = '/payment/esewa/failure';

  // ==================== 11. COUPONS & DEALS ====================

  static const String validateCouponEndpoint = '/validate-coupon';
  static const String availableCouponsEndpoint = '/coupons/available';
  static const String applyCouponEndpoint = '/apply-coupon';

  // ==================== 12. HOTEL RATINGS & REVIEWS ====================

  static const String rateHotelEndpoint = '/rate-hotel';
  static const String ownerReviewsEndpoint = '/hotel-owner/reviews';
  static const String ownerReviewReplyEndpoint = '/hotel-owner/reviews'; // + /{id}/reply
  static const String sendReviewRequestEndpoint = '/review-requests/send';
  static const String myReviewEndpoint = '/my-review';
  static const String addReviewReportEndpoint = '/add-review-report';

  // ==================== 13. HOTEL MEDIA / GALLERY / VIDEO (OWNER) ====================

  static const String ownerMediaEndpoint = '/hotel-owner/media';
  static const String ownerMediaImagesEndpoint = '/hotel-owner/media/images';
  static const String ownerMediaVideoEndpoint = '/hotel-owner/media/video';
  static const String ownerMediaVideoLinkEndpoint = '/hotel-owner/media/video-link';
  static const String ownerMediaReorderEndpoint = '/hotel-owner/media/reorder';
  static const String ownerVideosUploadEndpoint = '/hotel-owner/videos/upload';
  static const String ownerVideosLinkEndpoint = '/hotel-owner/videos/link';
  static const String ownerVideosSetPrimaryEndpoint = '/hotel-owner/videos'; // + /{id}/set-primary
  static const String ownerVideosEndpoint = '/hotel-owner/videos'; // DELETE /{id}

  // ==================== 14. ROOM TYPE MEDIA (OWNER) ====================

  static const String ownerRoomTypeMediaEndpoint = '/hotel-owner/room-types/media';
  static const String roomTypeMediaImagesEndpoint = '/room-types'; // + /{roomTypeId}/media/images
  static const String roomTypeMediaVideoEndpoint = '/room-types'; // + /{roomTypeId}/media/video
  static const String roomTypeMediaVideoLinkEndpoint = '/room-types'; // + /{roomTypeId}/media/video-link
  static const String roomTypeMediaUpdateEndpoint = '/room-types/media'; // + /{id}
  static const String roomTypeMediaReorderEndpoint = '/room-types'; // + /{roomTypeId}/media/reorder
  static const String roomTypeVideosUploadEndpoint = '/room-types'; // + /{roomTypeId}/videos/upload
  static const String roomTypeVideosLinkEndpoint = '/room-types'; // + /{roomTypeId}/videos/link
  static const String roomTypeVideosSetPrimaryEndpoint = '/room-types/videos'; // + /{id}/set-primary

  // ==================== 15. HOTEL OWNER DASHBOARD ====================

  static const String ownerDashboardEndpoint = '/hotel-owner/dashboard';
  static const String ownerAmenitiesEndpoint = '/hotel-owner/amenities';
  static const String ownerGalleryEndpoint = '/hotel-owner/gallery';
  static const String ownerReportsEndpoint = '/hotel-owner/reports';
  static const String ownerAnalyticsEndpoint = '/hotel-owner/analytics';
  static const String ownerAnalyticsSummaryEndpoint = '/owner-analytics';
  static const String ownerEarningsSummaryEndpoint = '/owner/earnings-summary';
  static const String ownerCalendarEndpoint = '/owner/calendar';
  static const String ownerTaxReportEndpoint = '/owner/tax-report';
  static const String ownerCompetitorBenchmarkEndpoint = '/owner/competitor-benchmark';
  static const String ownerReviewRequestsEndpoint = '/owner/review-requests';

  // ==================== 16. OWNER EARNINGS ====================

  static const String ownerEarningsEndpoint = '/hotel-owner/earnings';
  static const String ownerTransactionsEndpoint = '/hotel-owner/transactions';
  static const String ownerTransactionsFilterEndpoint = '/hotel-owner/transactions/filter';
  static const String ownerEarningsExportEndpoint = '/hotel-owner/earnings/export';

  // ==================== 17. OWNER WITHDRAWALS ====================

  static const String ownerWithdrawalsEndpoint = '/hotel-owner/withdrawals';

  // ==================== 18. OFFERS MANAGEMENT (OWNER) ====================

  static const String ownerOffersEndpoint = '/hotel-owner/offers';
  static const String ownerOffersDetailEndpoint = '/hotel-owner/offers'; // + /{id}
  static const String ownerOfferAnalyticsEndpoint = '/hotel-owner/offers'; // + /{id}/analytics

  // ==================== 19. IN-STAY ORDERING ====================

  static const String ordersPlaceEndpoint = '/orders/place';
  static const String myOrdersEndpoint = '/orders/my-orders';
  static const String orderCancelEndpoint = '/orders'; // + /{id}/cancel
  static const String ownerOrdersEndpoint = '/hotel-owner/orders';
  static const String ownerOrderStatusEndpoint = '/hotel-owner/orders'; // + /{id}/status
  static const String ownerOrderAnalyticsEndpoint = '/hotel-owner/order-analytics';
  static const String ownerMenuEndpoint = '/hotel-owner/menu';
  static const String ownerMenuDetailEndpoint = '/hotel-owner/menu'; // + /{id}

  // ==================== 20. QR CHECK-IN SYSTEM ====================

  static const String checkinQrEndpoint = '/checkin/qr';
  static const String checkinScanEndpoint = '/checkin/scan';
  static const String checkinConfirmEndpoint = '/checkin/confirm';
  static const String checkinCheckoutEndpoint = '/checkin/checkout';
  static const String checkinTodayEndpoint = '/checkin/today';
  static const String checkinActiveGuestsEndpoint = '/checkin/active-guests';

  // ==================== 21. LOYALTY POINTS ====================

  static const String loyaltyBalanceEndpoint = '/loyalty/balance';
  static const String loyaltyReferralCodeEndpoint = '/loyalty/referral-code';
  static const String loyaltyApplyReferralEndpoint = '/loyalty/apply-referral';
  static const String loyaltyHistoryEndpoint = '/loyalty/history';
  static const String loyaltyProgramEndpoint = '/loyalty/program';
  static const String loyaltyUserTierEndpoint = '/loyalty/user-tier';
  static const String loyaltyReferralStatsEndpoint = '/loyalty/referral-stats';
  static const String loyaltyRewardsEndpoint = '/loyalty/rewards';
  static const String loyaltyCalculatePointsEndpoint = '/loyalty/calculate-points';
  static const String loyaltyPointsValueEndpoint = '/loyalty/points-value';
  static const String loyaltyShareReferralEndpoint = '/loyalty/share-referral';
  static const String loyaltyTiersEndpoint = '/loyalty/tiers';
  static const String loyaltyMyTierEndpoint = '/loyalty/my-tier';
  static const String loyaltyRedeemEndpoint = '/loyalty/redeem';
  static const String loyaltyRedemptionPreviewEndpoint = '/loyalty/redemption-preview';

  // ==================== 22. WAITLIST ====================

  static const String waitlistJoinEndpoint = '/waitlist/join';
  static const String waitlistMyEndpoint = '/waitlist/my';
  static const String waitlistDeleteEndpoint = '/waitlist'; // + /{id}
  static const String waitlistCheckStatusEndpoint = '/waitlist/check-status';
  static const String waitlistNotificationsEndpoint = '/waitlist/notifications';
  static const String waitlistStatisticsEndpoint = '/waitlist/statistics';
  static const String waitlistPreferencesEndpoint = '/waitlist/preferences';
  static const String waitlistCancelAllEndpoint = '/waitlist/cancel-all';

  // ==================== 23. BOOKING REQUESTS & MODIFICATIONS ====================

  static const String bookingRequestsSpecialTimeEndpoint = '/booking-requests/special-time';
  static const String bookingRequestsMyEndpoint = '/booking-requests/my';
  static const String bookingRequestsRespondEndpoint = '/booking-requests'; // + /{id}/respond
  static const String ownerBookingRequestsEndpoint = '/booking-requests/owner';
  static const String bookingModificationsRequestEndpoint = '/booking-modifications/request';
  static const String bookingModificationsRespondEndpoint = '/booking-modifications'; // + /{id}/respond

  // ==================== 24. GUEST-HOTEL CHAT ====================

  static const String chatMessagesEndpoint = '/chat'; // + /{bookingId}/messages
  static const String chatSendEndpoint = '/chat/send';
  static const String ownerChatAllEndpoint = '/chat/owner/all';

  // ==================== 25. PRICE ALERTS (GUEST) ====================

  static const String priceAlertsEndpoint = '/price-alerts';
  static const String priceAlertsMyEndpoint = '/price-alerts/my';
  static const String priceAlertsDeleteEndpoint = '/price-alerts'; // + /{id}

  // ==================== 26. SUPPORT SYSTEM ====================

  static const String supportTicketsEndpoint = '/support/tickets';
  static const String supportTicketDetailEndpoint = '/support/tickets'; // + /{id}
  static const String supportTicketMessagesEndpoint = '/support/tickets'; // + /{id}/messages
  static const String supportChatStartEndpoint = '/support/chat/start';
  static const String supportChatGetEndpoint = '/support/chat'; // + /{token}
  static const String supportChatMessageEndpoint = '/support/chat'; // + /{token}/message
  static const String supportChatEndEndpoint = '/support/chat'; // + /{token}/end

  // ==================== 27. AI CHATBOT ====================

  static const String aiChatStartEndpoint = '/ai-chat/start';
  static const String aiChatMessageEndpoint = '/ai-chat/message';
  static const String aiChatHistoryEndpoint = '/ai-chat/history'; // + /{token}
  static const String aiChatEndEndpoint = '/ai-chat/end'; // + /{token}

  // ==================== 28. AI / DYNAMIC PRICING (OWNER) ====================

  static const String aiPricingRulesEndpoint = '/ai-pricing/rules';
  static const String aiPricingSuggestEndpoint = '/ai-pricing/suggest';
  static const String aiPricingSuggestRangeEndpoint = '/ai-pricing/suggest-range';
  static const String aiPricingApplyEndpoint = '/ai-pricing/apply';
  static const String aiPricingAutoApplyEndpoint = '/ai-pricing/auto-apply';

  // ==================== 29. ICAL / CHANNEL MANAGER (OWNER) ====================

  static const String icalChannelsEndpoint = '/ical/channels';
  static const String icalSyncEndpoint = '/ical/channels'; // + /{id}/sync
  static const String icalExportEndpoint = '/ical/export'; // + /{token}

  // ==================== 30. AUTOMATED GUEST MESSAGING (OWNER) ====================

  static const String guestMessagingTemplatesEndpoint = '/guest-messaging/templates';
  static const String guestMessagingLogsEndpoint = '/guest-messaging/logs';
  static const String guestMessagingTestEndpoint = '/guest-messaging/test';

  // ==================== 31. COMPETITOR BENCHMARKING (OWNER) ====================

  static const String competitorPricesEndpoint = '/competitor/prices';
  static const String competitorSummaryEndpoint = '/competitor/summary';
  static const String competitorParityCheckEndpoint = '/competitor/parity-check';
  static const String competitorTrendEndpoint = '/competitor/trend';

  // ==================== 32. MULTI-CURRENCY ====================

  static const String currenciesEndpoint = '/currencies';
  static const String currenciesDetectEndpoint = '/currencies/detect';
  static const String currenciesRatesMapEndpoint = '/currencies/rates-map';
  static const String currenciesPreferenceEndpoint = '/currencies/preference';
  static const String currenciesConvertEndpoint = '/currencies/convert';

  // ==================== 33. TAX REPORTING (OWNER) ====================

  static const String taxesEndpoint = '/taxes';
  static const String taxesReportEndpoint = '/taxes/report';
  static const String taxesReportExportEndpoint = '/taxes/report/export';

  // ==================== 34. TWO-FACTOR AUTHENTICATION (2FA) ====================

  static const String twoFaStatusEndpoint = '/2fa/status';
  static const String twoFaSetupEndpoint = '/2fa/setup';
  static const String twoFaVerifyEndpoint = '/2fa/verify';
  static const String twoFaDisableEndpoint = '/2fa/disable';
  static const String twoFaValidateEndpoint = '/2fa/validate';
  static const String twoFaBiometricToggleEndpoint = '/2fa/biometric/toggle';
  static const String twoFaBackupCodesEndpoint = '/2fa/backup-codes';
  static const String twoFaUseBackupCodeEndpoint = '/2fa/use-backup-code';
  static const String twoFaSendCodeEndpoint = '/2fa/send-code';
  static const String twoFaMethodsEndpoint = '/2fa/methods';
  static const String twoFaSettingsEndpoint = '/2fa/settings';
  static const String twoFaRequiredEndpoint = '/2fa/required';
  static const String twoFaRecoveryOptionsEndpoint = '/2fa/recovery-options';
  static const String twoFaResetEndpoint = '/2fa/reset';

  // ==================== 35. RECOMMENDATIONS ====================

  static const String recommendationsTrendingEndpoint = '/recommendations/trending';
  static const String recommendationsNearbyPopularEndpoint = '/recommendations/nearby-popular';
  static const String recommendationsAlsoBookedEndpoint = '/recommendations/also-booked'; // + /{hotelId}
  static const String recommendationsForYouEndpoint = '/recommendations/for-you';

  // ==================== 36. FILTERS & SEARCH ====================

  static const String filtersOptionsEndpoint = '/filters/options';
  static const String filtersAdvancedEndpoint = '/filters/advanced';
  static const String filtersSearchEndpoint = '/filters/search';

  // ==================== 37. INVOICE ====================

  static const String invoicePreviewEndpoint = '/invoice'; // + /{bookingId}/preview
  static const String invoiceDownloadEndpoint = '/invoice'; // + /{bookingId}/download
  static const String corporateInvoiceEndpoint = '/corporate/invoice'; // + /{bookingId}
  static const String midStayFeedbackEndpoint = '/bookings'; // + /{bookingId}/mid-stay-feedback

  // ==================== 38. BLACKOUT DATES (OWNER) ====================

  static const String ownerBlackoutDatesEndpoint = '/hotel-owner/blackout-dates';
  static const String ownerBlackoutDatesRangeEndpoint = '/hotel-owner/blackout-dates/range';

  // ==================== 39. GUEST ID VERIFICATION ====================

  static const String idVerificationSubmitEndpoint = '/id-verification/submit';
  static const String idVerificationStatusEndpoint = '/id-verification/status';

  // ==================== 40. LONG-STAY / MONTHLY RATES ====================

  static const String longStayPreviewEndpoint = '/long-stay/preview';
  static const String ownerLongStayRatesEndpoint = '/hotel-owner/long-stay-rates';

  // ==================== 41. PMS INTEGRATION (OWNER) ====================

  static const String ownerPmsConnectionsEndpoint = '/hotel-owner/pms/connections';
  static const String ownerPmsTestEndpoint = '/hotel-owner/pms/connections'; // + /{id}/test
  static const String ownerPmsSyncEndpoint = '/hotel-owner/pms/connections'; // + /{id}/sync
  static const String ownerPmsLogsEndpoint = '/hotel-owner/pms/connections'; // + /{id}/logs

  // ==================== 42. SPLIT PAYMENT ====================

  static const String splitPaymentCreateEndpoint = '/split-payment/create';
  static const String splitPaymentMySplitsEndpoint = '/split-payment/my-splits';
  static const String splitPaymentDetailEndpoint = '/split-payment'; // + /{token}
  static const String splitPaymentPayEndpoint = '/split-payment/pay'; // + /{inviteToken}
  static const String payLaterEndpoint = '/payment/pay-later';
  static const String splitPaymentLegacyEndpoint = '/payment/split';
  static const String installmentEndpoint = '/payment/installment';
  static const String payLaterStatusEndpoint = '/payment/pay-later/status'; // + /{bookingId}

  // ==================== 43. HOUSEKEEPING (OWNER) ====================

  static const String housekeepingTasksEndpoint = '/housekeeping/tasks';
  static const String housekeepingTaskStatusEndpoint = '/housekeeping/tasks'; // + /{id}/status
  static const String housekeepingRoomStatusEndpoint = '/housekeeping/room-status';
  static const String housekeepingLinenEndpoint = '/housekeeping/linen';

  // ==================== 44. MAINTENANCE (OWNER) ====================

  static const String maintenanceIssuesEndpoint = '/maintenance/issues';
  static const String maintenanceIssueAssignEndpoint = '/maintenance/issues'; // + /{id}/assign
  static const String maintenanceIssueStatusEndpoint = '/maintenance/issues'; // + /{id}/status
  static const String maintenancePreventiveEndpoint = '/maintenance/preventive';

  // ==================== 45. HOTEL STAFF MANAGEMENT (OWNER) ====================

  static const String ownerStaffEndpoint = '/hotel-owner/staff';
  static const String ownerStaffShiftsEndpoint = '/hotel-owner/staff/shifts';
  static const String ownerStaffAttendanceClockInEndpoint = '/hotel-owner/staff/attendance/clock-in';
  static const String ownerStaffAttendanceClockOutEndpoint = '/hotel-owner/staff/attendance/clock-out';
  static const String ownerStaffAttendanceEndpoint = '/hotel-owner/staff/attendance';
  static const String ownerStaffTasksEndpoint = '/hotel-owner/staff/tasks';
  static const String ownerStaffTaskStatusEndpoint = '/hotel-owner/staff/tasks'; // + /{id}/status

  // ==================== 46. DIGITAL ROOM KEY ====================

  static const String digitalKeyGenerateEndpoint = '/digital-key/generate';
  static const String digitalKeyMyEndpoint = '/digital-key/my';
  static const String digitalKeyUnlockEndpoint = '/digital-key/unlock';
  static const String digitalKeyShareEndpoint = '/digital-key'; // + /{id}/share
  static const String digitalKeyRevokeEndpoint = '/digital-key'; // + /{id}

  // ==================== 47. FRONT DESK (OWNER) ====================

  static const String frontDeskRoomGridEndpoint = '/front-desk/room-grid';
  static const String frontDeskWalkInEndpoint = '/front-desk/walk-in';
  static const String frontDeskRoomAssignEndpoint = '/front-desk/room-assign';
  static const String frontDeskFolioEndpoint = '/front-desk/folio'; // + /{bookingId}
  static const String frontDeskFolioChargeEndpoint = '/front-desk/folio'; // + /{bookingId}/charge
  static const String frontDeskNightAuditEndpoint = '/front-desk/night-audit';

  // ==================== 48. HOTEL STAY PACKAGES ====================

  static const String ownerPackagesEndpoint = '/hotel-owner/packages';

  // ==================== 49. UPSELLING & ADD-ONS ====================

  static const String bookingAddonsEndpoint = '/bookings'; // + /{bookingId}/addons
  static const String ownerAddonsEndpoint = '/hotel-owner/addons';
  static const String ownerAddonOrdersEndpoint = '/hotel-owner/addon-orders';
  static const String ownerAddonOrderStatusEndpoint = '/hotel-owner/addon-orders'; // + /{id}/status

  // ==================== 50. ACTIVITIES & EXPERIENCES ====================

  static const String activitiesBookEndpoint = '/activities/book';
  static const String activitiesMyEndpoint = '/activities/my';
  static const String ownerActivitiesEndpoint = '/hotel-owner/activities';
  static const String ownerActivityBookingsEndpoint = '/hotel-owner/activity-bookings';
  static const String ownerActivityBookingStatusEndpoint = '/hotel-owner/activity-bookings'; // + /{id}/status

  // ==================== 51. CORPORATE / BUSINESS TRAVEL ====================

  static const String corporateRegisterEndpoint = '/corporate/register';
  static const String corporateAccountEndpoint = '/corporate/my-account';
  static const String corporateAddTravelerEndpoint = '/corporate/add-traveler';
  static const String corporateBookingsEndpoint = '/corporate/bookings';

  // ==================== 52. GROUP BOOKINGS ====================

  static const String groupBookingsInquiryEndpoint = '/group-bookings/inquiry';
  static const String groupBookingsMyEndpoint = '/group-bookings/my';
  static const String ownerGroupBookingsEndpoint = '/hotel-owner/group-bookings';
  static const String ownerGroupBookingConfirmEndpoint = '/hotel-owner/group-bookings'; // + /{id}/confirm
  static const String ownerGroupBookingRoomingListEndpoint = '/hotel-owner/group-bookings'; // + /{id}/rooming-list

  // ==================== 53. FLASH SALES ====================

  static const String ownerFlashSalesEndpoint = '/hotel-owner/flash-sales';

  // ==================== 54. MEMBERSHIP / SUBSCRIPTION ====================

  static const String membershipsMyEndpoint = '/memberships/my';
  static const String membershipsSubscribeEndpoint = '/memberships/subscribe';
  static const String membershipsCancelEndpoint = '/memberships/cancel';

  // ==================== 55. DIGITAL CONCIERGE ====================

  static const String conciergeRequestEndpoint = '/concierge/request';
  static const String conciergeMyEndpoint = '/concierge/my';
  static const String ownerConciergeEndpoint = '/hotel-owner/concierge';
  static const String ownerConciergeStatusEndpoint = '/hotel-owner/concierge'; // + /{id}/status

  // ==================== 56. PRE-ARRIVAL GUEST PROFILE ====================

  static const String guestPreferencesEndpoint = '/guest/preferences';
  static const String bookingPreArrivalEndpoint = '/bookings'; // + /{bookingId}/pre-arrival

  // ==================== 57. REPUTATION MANAGEMENT (OWNER) ====================

  static const String ownerReputationEndpoint = '/hotel-owner/reputation';
  static const String ownerReputationReviewsEndpoint = '/hotel-owner/reputation/reviews';
  static const String ownerReputationReviewRespondEndpoint = '/hotel-owner/reputation/reviews'; // + /{id}/respond

  // ==================== 58. REVIEW REQUESTS ====================

  static const String reviewRequestsSendEndpoint = '/review-requests/send';

  // ==================== TIMEOUTS ====================

  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds

  // ==================== LOCATION ====================

  static const String countriesEndpoint = '/countries';
  static const String statesEndpoint = '/states';
  static const String citiesEndpoint = '/cities';
  static const String areasEndpoint = '/areas';
  static const String getLocationEndpoint = '/get-location';

  // ==================== USER / VERIFICATION ====================

  static const String getLimitsEndpoint = '/get-limits';
  static const String blockUserEndpoint = '/block-user';
  static const String unblockUserEndpoint = '/unblock-user';
  static const String blockedUsersEndpoint = '/blocked-users';
  static const String addReportsEndpoint = '/add-reports';
  static const String verificationFieldsEndpoint = '/verification-fields';
  static const String sendVerificationRequestEndpoint = '/send-verification-request';
  static const String verificationRequestEndpoint = '/verification-request';

  // ==================== SYSTEM ====================

  static const String getSystemSettingsEndpoint = '/get-system-settings';

  // ==================== UTILITY ====================

  static String buildPath(String base, String segment) {
    return '$base/$segment';
  }

  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // ==================== MISSING ENDPOINTS (legacy service compat) ====================

  // wallet_service.dart
  static const String walletAddMoneyEndpoint = '/wallet/add-money';
  static const String walletUseEndpoint = '/wallet/use';
  static const String walletTransactionsEndpoint = '/payment-transactions';
  static const String walletTransferEndpoint = '/wallet/transfer';
  static const String walletWithdrawEndpoint = '/wallet/withdraw';
  static const String walletSettingsEndpoint = '/wallet/settings';
  static const String walletStatisticsEndpoint = '/wallet/statistics';
  static const String walletSetPinEndpoint = '/wallet/set-pin';
  static const String walletVerifyPinEndpoint = '/wallet/verify-pin';
  static const String walletCashbackOffersEndpoint = '/wallet/cashback-offers';

  // filters_service.dart
  static const String filterOptionsEndpoint = '/filters/options';
  static const String filterAdvancedEndpoint = '/filters/advanced';
  static const String filterSearchEndpoint = '/filters/search';

  // app_data_service.dart
  static const String getPackageEndpoint = '/get-package';
  static const String getLanguagesEndpoint = '/get-languages';
  static const String appPaymentStatusEndpoint = '/app-payment-status';
  static const String getCustomFieldsEndpoint = '/get-customfields';
  static const String getItemEndpoint = '/get-item';
  static const String getSliderEndpoint = '/get-slider';
  static const String getReportReasonsEndpoint = '/get-report-reasons';
  static const String getCategoriesEndpoint = '/get-categories';
  static const String getParentCategoriesEndpoint = '/get-parent-categories';
  static const String getFeaturedSectionEndpoint = '/get-featured-section';
  static const String getCategoriesDemoEndpoint = '/get-categories-demo';
  static const String seoSettingsEndpoint = '/seo-settings';
  static const String blogsEndpoint = '/blogs';
  static const String blogTagsEndpoint = '/blog-tags';
  static const String faqEndpoint = '/faq';
  static const String tipsEndpoint = '/tips';
  static const String setItemTotalClickEndpoint = '/set-item-total-click';
  static const String contactUsEndpoint = '/contact-us';
}
