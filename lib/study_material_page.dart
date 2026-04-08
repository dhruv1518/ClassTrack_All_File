import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

Future<void> openLink(String url) async {
  final Uri uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class StudyMaterialPage extends StatelessWidget {
  const StudyMaterialPage({Key? key}) : super(key: key);

  Widget _sectionTitle(ThemeProvider tp, String title) => Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: tp.cardHighlight,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.menu_book_rounded, color: tp.iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: tp.primaryText,
          ),
        ),
      ],
    ),
  );

  Widget _chapterTile(ThemeProvider tp, Map<String, dynamic> data) => Card(
    color: tp.cardBg,
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.withOpacity(0.12),
        child: const Icon(Icons.picture_as_pdf, color: Colors.red),
      ),
      title: Text(
        data['chapter'],
        style: TextStyle(fontWeight: FontWeight.w600, color: tp.primaryText),
      ),
      subtitle: Text(data['title'], style: TextStyle(color: tp.secondaryText)),
      trailing: Icon(Icons.open_in_new, color: tp.inactiveColor),
      onTap: () => openLink(data['pdfUrl']),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          "Study Materials",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: tp.appBarBg,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('study_materials')
            .orderBy('createdAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(
              child: Text(
                "No study material available",
                style: TextStyle(color: tp.inactiveColor),
              ),
            );
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            grouped.putIfAbsent(data['subject'], () => []);
            grouped[data['subject']]!.add(data);
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: grouped.entries
                .map(
                  (entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(tp, entry.key),
                      ...entry.value.map((d) => _chapterTile(tp, d)).toList(),
                    ],
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
