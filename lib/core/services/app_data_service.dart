import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class AppDataService {
  // GET /get-home-data - Home screen data
  Future<Map<String, dynamic>> getHomeData() async {
    try {
      final response = await ApiService.get(ApiConfig.getHomeDataEndpoint);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load home data'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load home data'};
    }
  }

  // GET /get-package - Package info
  Future<Map<String, dynamic>> getPackage() async {
    try {
      final response = await ApiService.get(ApiConfig.getPackageEndpoint);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load package info'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load package info'};
    }
  }

  // GET /get-languages - Language settings
  Future<Map<String, dynamic>> getLanguages() async {
    try {
      final response = await ApiService.get(ApiConfig.getLanguagesEndpoint);
      return response['success'] == true
          ? {'success': true, 'languages': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load languages'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load languages'};
    }
  }

  // GET /app-payment-status - Payment status
  Future<Map<String, dynamic>> getAppPaymentStatus() async {
    try {
      final response = await ApiService.get(ApiConfig.appPaymentStatusEndpoint);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load payment status'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load payment status'};
    }
  }

  // GET /get-customfields - Custom fields
  Future<Map<String, dynamic>> getCustomFields() async {
    try {
      final response = await ApiService.get(ApiConfig.getCustomFieldsEndpoint);
      return response['success'] == true
          ? {'success': true, 'fields': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load custom fields'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load custom fields'};
    }
  }

  // GET /get-item - Item data
  Future<Map<String, dynamic>> getItem(String? itemId) async {
    try {
      final queryParams = itemId != null ? {'id': itemId} : null;
      final response = await ApiService.get(ApiConfig.getItemEndpoint, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load item'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load item'};
    }
  }

  // GET /get-slider - Slider content
  Future<Map<String, dynamic>> getSlider() async {
    try {
      final response = await ApiService.get(ApiConfig.getSliderEndpoint);
      return response['success'] == true
          ? {'success': true, 'sliders': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load sliders'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load sliders'};
    }
  }

  // GET /get-report-reasons - Report reasons
  Future<Map<String, dynamic>> getReportReasons() async {
    try {
      final response = await ApiService.get(ApiConfig.getReportReasonsEndpoint);
      return response['success'] == true
          ? {'success': true, 'reasons': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load report reasons'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load report reasons'};
    }
  }

  // GET /get-categories - Categories
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await ApiService.get(ApiConfig.getCategoriesEndpoint);
      return response['success'] == true
          ? {'success': true, 'categories': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load categories'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load categories'};
    }
  }

  // GET /get-parent-categories - Parent categories
  Future<Map<String, dynamic>> getParentCategories() async {
    try {
      final response = await ApiService.get(ApiConfig.getParentCategoriesEndpoint);
      return response['success'] == true
          ? {'success': true, 'categories': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load parent categories'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load parent categories'};
    }
  }

  // GET /get-featured-section - Featured section
  Future<Map<String, dynamic>> getFeaturedSection() async {
    try {
      final response = await ApiService.get(ApiConfig.getFeaturedSectionEndpoint);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load featured section'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load featured section'};
    }
  }

  // GET /get-categories-demo - Demo categories
  Future<Map<String, dynamic>> getCategoriesDemo() async {
    try {
      final response = await ApiService.get(ApiConfig.getCategoriesDemoEndpoint);
      return response['success'] == true
          ? {'success': true, 'categories': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load demo categories'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load demo categories'};
    }
  }

  // GET /get-owner - Owner data
  Future<Map<String, dynamic>> getOwner(String? ownerId) async {
    try {
      final queryParams = ownerId != null ? {'id': ownerId} : null;
      final response = await ApiService.get(ApiConfig.getOwnerEndpoint, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'owner': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load owner data'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load owner data'};
    }
  }

  // GET /seo-settings - SEO settings
  Future<Map<String, dynamic>> getSeoSettings() async {
    try {
      final response = await ApiService.get(ApiConfig.seoSettingsEndpoint);
      return response['success'] == true
          ? {'success': true, 'settings': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load SEO settings'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load SEO settings'};
    }
  }

  // GET /blogs - Blog content
  Future<Map<String, dynamic>> getBlogs({Map<String, dynamic>? filters}) async {
    try {
      final response = await ApiService.get(ApiConfig.blogsEndpoint, queryParams: filters);
      return response['success'] == true
          ? {'success': true, 'blogs': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load blogs'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load blogs'};
    }
  }

  // GET /blog-tags - Blog tags
  Future<Map<String, dynamic>> getBlogTags() async {
    try {
      final response = await ApiService.get(ApiConfig.blogTagsEndpoint);
      return response['success'] == true
          ? {'success': true, 'tags': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load blog tags'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load blog tags'};
    }
  }

  // GET /faq - FAQ content
  Future<Map<String, dynamic>> getFaq() async {
    try {
      final response = await ApiService.get(ApiConfig.faqEndpoint);
      return response['success'] == true
          ? {'success': true, 'faqs': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load FAQ'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load FAQ'};
    }
  }

  // GET /tips - Tips content
  Future<Map<String, dynamic>> getTips() async {
    try {
      final response = await ApiService.get(ApiConfig.tipsEndpoint);
      return response['success'] == true
          ? {'success': true, 'tips': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load tips'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load tips'};
    }
  }

  // POST /set-item-total-click - Track item clicks
  Future<Map<String, dynamic>> setItemTotalClick(String itemId) async {
    try {
      final response = await ApiService.post(ApiConfig.setItemTotalClickEndpoint, data: {'item_id': itemId});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to track click'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to track click'};
    }
  }

  // POST /contact-us - Contact form
  Future<Map<String, dynamic>> contactUs(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post(ApiConfig.contactUsEndpoint, data: data);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to send message'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send message'};
    }
  }

}