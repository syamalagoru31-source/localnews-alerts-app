import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedNewsService {
  static const String _savedNewsKey = 'saved_news';

  Future<List<Map<String, dynamic>>> getSavedNews() async {
    final prefs = await SharedPreferences.getInstance();

    final savedData = prefs.getString(_savedNewsKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    final decodedData = jsonDecode(savedData);

    return List<Map<String, dynamic>>.from(
      decodedData.map((article) => Map<String, dynamic>.from(article)),
    );
  }

  Future<void> saveNews(List<Map<String, dynamic>> news) async {
    final prefs = await SharedPreferences.getInstance();

    final encodedData = jsonEncode(news);

    await prefs.setString(_savedNewsKey, encodedData);
  }
}
