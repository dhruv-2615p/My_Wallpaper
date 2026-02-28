/// Pexels API configuration.
class ApiConstants {
  ApiConstants._();

  static const String pexelsBaseUrl = 'https://api.pexels.com/v1';

  /// Placeholder key — replace with your own from https://www.pexels.com/api/
  static const String defaultPexelsApiKey = '';

  static const int perPage = 30;

  // Endpoints
  static String curated({int page = 1}) =>
      '$pexelsBaseUrl/curated?per_page=$perPage&page=$page';

  static String search(String query, {int page = 1}) =>
      '$pexelsBaseUrl/search?query=$query&per_page=$perPage&page=$page';
}
