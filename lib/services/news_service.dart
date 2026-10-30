import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  static const String apiKey = 'f3f0fa8c73124674995b79435d26c46d';

  // ============================================================
  // LOCAL NEWS
  // ============================================================

  Future<List<Map<String, dynamic>>> getLocalNews(String location) async {
    final url = Uri.parse(
      'https://newsapi.org/v2/everything'
      '?q=${Uri.encodeComponent(location)}'
      '&language=en'
      '&sortBy=publishedAt'
      '&pageSize=20'
      '&apiKey=$apiKey',
    );

    final response = await http.get(url);

    print('NEWS API STATUS: ${response.statusCode}');
    print('NEWS API RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final articles = data['articles'] as List;

      return articles.map<Map<String, dynamic>>((article) {
        final item = Map<String, dynamic>.from(article);

        // Get the image supplied by NewsAPI
        item['image_url'] = item['urlToImage']?.toString() ?? '';

        return item;
      }).toList();
    } else {
      throw Exception('Failed to load local news: ${response.statusCode}');
    }
  }

  // ============================================================
  // SEARCH NEWS
  // ============================================================

  Future<List<Map<String, dynamic>>> searchNews(String query) async {
    final url = Uri.parse(
      'https://newsapi.org/v2/everything'
      '?q=${Uri.encodeComponent(query)}'
      '&language=en'
      '&sortBy=publishedAt'
      '&pageSize=20'
      '&apiKey=$apiKey',
    );

    final response = await http.get(url);

    print('SEARCH API STATUS: ${response.statusCode}');
    print('SEARCH API RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final articles = data['articles'] as List;

      return articles.map<Map<String, dynamic>>((article) {
        final item = Map<String, dynamic>.from(article);

        // Get the image supplied by NewsAPI
        item['image_url'] = item['urlToImage']?.toString() ?? '';

        return item;
      }).toList();
    } else {
      throw Exception('Failed to search news: ${response.statusCode}');
    }
  }
}
