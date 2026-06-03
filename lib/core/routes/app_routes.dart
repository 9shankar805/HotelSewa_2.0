class AppRoutes {
  // Authentication & Onboarding
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  
  // Core App
  static const String home = '/home';
  static const String search = '/search';
  static const String hotelList = '/hotel-list';
  static const String hotelDetails = '/hotel-details';
  
  // Booking Flow
  static const String bookingForm = '/booking-form';
  static const String payment = '/payment';
  static const String bookingSuccess = '/booking-success';
  static const String roomTypes = '/room-types';
  static const String pricingBreakdown = '/pricing-breakdown';
  
  // User Profile
  static const String profile = '/profile';
  static const String personalInfo = '/personal-info';
  static const String profileComplete = '/profile-complete';
  static const String myTrips = '/my-trips';
  static const String saved = '/saved';
  static const String notifications = '/notifications';
  static const String wallet = '/wallet';
  static const String paymentMethods = '/payment-methods';
  
  // Features
  static const String inviteEarn = '/invite-earn';
  static const String helpCenter = '/help-center';
  static const String coupons = '/coupons';
  static const String filters = '/filters';
  static const String gallery = '/gallery';
  static const String chat = '/chat';
  static const String aiChat = '/ai-chat';
  static const String amenities = '/amenities';
  static const String advancedFeatures = '/advanced-features';
  
  // Reviews
  static const String hotelReviews = '/hotel-reviews';
  static const String reviewSubmission = '/review-submission';
  static const String pendingReviews = '/pending-reviews';
  
  // Map & Location
  static const String mapSearch = '/map-search';
  static const String locationSelector = '/location-selector';
}
