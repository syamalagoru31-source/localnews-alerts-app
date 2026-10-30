class NewsModel {
  final String id;
  final String category;
  final String title;
  final String description;
  final String time;
  final String location;
  final String source;
  final bool isBreaking;
  bool isSaved;

  NewsModel({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.time,
    required this.location,
    required this.source,
    required this.isBreaking,
    this.isSaved = false,
  });
}
