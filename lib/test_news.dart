import 'services/news_service.dart';

void main() async {
  final newsService = NewsService();

  try {
    final news = await newsService.getLocalNews('Hyderabad');

    print('================================');
    print('NEWS FOUND: ${news.length}');
    print('================================');

    for (final article in news.take(5)) {
      print('TITLE: ${article['title']}');
      print('SOURCE: ${article['source']?['name']}');
      print('--------------------------------');
    }
  } catch (e) {
    print('ERROR: $e');
  }
}
