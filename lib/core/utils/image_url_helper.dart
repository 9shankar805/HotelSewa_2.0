/// Centralized image URL helper for fixing broken storage URLs from the API.
///
/// The backend at 209.50.241.46:2000 sometimes stores image URLs as:
///   http://209.50.241.46:2000/storage/https://images.unsplash.com/...
/// when the actual URL should just be:
///   https://images.unsplash.com/...
///
/// This utility strips that broken prefix everywhere in the app.
class ImageUrlHelper {
  static const String _serverBase = 'http://209.50.241.46:2000';

  /// Fixes a single image URL.
  static String fix(String? url) {
    if (url == null || url.isEmpty) return '';

    // Pattern: http(s)://any-host/storage/https://real-url
    final badPrefix = RegExp(r'https?://[^/]+/storage/(https?://.+)');
    final match = badPrefix.firstMatch(url);
    if (match != null) return match.group(1)!;

    // If it's a relative path like /storage/images/... build full URL
    if (url.startsWith('/storage/')) {
      return '$_serverBase$url';
    }

    return url;
  }

  /// Fixes a list of image URLs.
  static List<String> fixList(List<dynamic>? urls) {
    if (urls == null || urls.isEmpty) return [];
    return urls
        .map((u) => fix(u?.toString()))
        .where((u) => u.isNotEmpty)
        .toList();
  }

  /// Returns the first valid fixed image URL, or a fallback.
  static String firstOrFallback(List<dynamic>? urls, {String? fallback}) {
    final fixed = fixList(urls);
    if (fixed.isNotEmpty) return fixed.first;
    return fallback ?? 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800';
  }
}
