import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SavedScreen extends StatelessWidget {
  final List<Map<String, dynamic>> savedNews;
  final Function(Map<String, dynamic>) onRemove;

  const SavedScreen({
    super.key,
    required this.savedNews,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Saved News',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: savedNews.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedNews.length,
              itemBuilder: (context, index) {
                final article = savedNews[index];

                return _savedCard(context, article);
              },
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            const Text(
              'No Saved News',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'News you bookmark will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedCard(BuildContext context, Map<String, dynamic> article) {
    final title = article['title']?.toString() ?? 'No title';

    final source = article['source']?['name']?.toString() ?? 'News';

    final url = article['url']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.all(15),

        leading: Container(
          width: 55,
          height: 55,

          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(Icons.article_rounded, color: Colors.blue.shade700),
        ),

        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,

          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),

          child: Text(
            source,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),

        trailing: IconButton(
          icon: Icon(Icons.bookmark_rounded, color: Colors.blue.shade700),

          onPressed: () {
            onRemove(article);
          },
        ),

        onTap: () async {
          if (url.isEmpty) return;

          final uri = Uri.tryParse(url);

          if (uri == null) return;

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}
