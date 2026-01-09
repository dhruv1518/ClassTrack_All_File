import 'package:flutter/material.dart';

// Palette based on the provided image
const Color kBgColor = Color(0xFFF7F2EE);               // Background/Scaffold
const Color kSectionCardColor = Color(0xFFE7DED7);      // Section card backgrounds
const Color kIconMain = Color(0xFF26445B);              // Primary icon/text (deep blue)
const Color kTextMain = Color(0xFF294761);              // Title text (deep blue)
const Color kTileCard = Colors.white;                   // MaterialTiles (keep white)
const Color kAccentBlue = Color(0xFF26445B);            // Accent, appbar
const Color kAccentMuted = Color(0xFFB6AC9D);           // Muted icon bg (light taupe)
const Color kRedAccent = Color(0xFFF44336);
const Color kGreenAccent = Color(0xFF64B587);
const Color kPurpleAccent = Color(0xFF6B5CA5);
const Color kOrangeAccent = Color(0xFFF9A825);
const Color kCyanAccent = Color(0xFF41B6C4);
const Color kIndigoAccent = Color(0xFF3F51B5);
const Color kBlueAccent = Color(0xFF2196F3);

class StudyMaterialPage extends StatelessWidget {
  const StudyMaterialPage({Key? key}) : super(key: key);

  Widget _sectionTitle(String title, IconData icon) => Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: kSectionCardColor,
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    child: Row(
      children: [
        Icon(icon, color: kIconMain),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: kTextMain,
          ),
        ),
      ],
    ),
  );

  Widget _materialTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color iconBg = kAccentBlue,
    VoidCallback? onTap,
    Widget? trailing,
  }) =>
      Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        elevation: 2,
        color: kTileCard,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconBg.withOpacity(0.12),
            child: Icon(icon, color: iconBg),
          ),
          title: Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: kTextMain),
          ),
          subtitle: Text(subtitle,
              style: const TextStyle(color: kAccentMuted)),
          trailing: trailing,
          onTap: onTap,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text(
          'Study Materials',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: kAccentBlue,
        iconTheme: const IconThemeData(color: Colors.white), // Makes back arrow white
      ),


      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _sectionTitle('Quizzes', Icons.quiz_outlined),
          _materialTile(
            title: "Chapter-wise Quiz",
            subtitle: "Practice by topics and chapters",
            icon: Icons.assignment_turned_in,
            onTap: () {},
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kAccentMuted),
          ),
          _materialTile(
            title: "Mock Test",
            subtitle: "Simulate full-length exams",
            icon: Icons.fact_check,
            iconBg: kPurpleAccent,
            onTap: () {},
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kAccentMuted),
          ),
          const SizedBox(height: 18),

          _sectionTitle('Previous Year Papers', Icons.folder_open_rounded),
          _materialTile(
            title: "2024 Final Exam Paper",
            subtitle: "Download PDF, with solutions",
            icon: Icons.picture_as_pdf,
            iconBg: kRedAccent,
            onTap: () {},
            trailing: const Icon(Icons.cloud_download, color: kRedAccent),
          ),
          _materialTile(
            title: "2023 Mid-term Paper",
            subtitle: "With solved answers",
            icon: Icons.picture_as_pdf,
            iconBg: kGreenAccent,
            onTap: () {},
            trailing: const Icon(Icons.cloud_download, color: kGreenAccent),
          ),
          _materialTile(
            title: "2022 Question Paper",
            subtitle: "Practice unsolved paper",
            icon: Icons.picture_as_pdf,
            iconBg: kOrangeAccent,
            onTap: () {},
            trailing: const Icon(Icons.cloud_download, color: kOrangeAccent),
          ),
          const SizedBox(height: 18),

          _sectionTitle('Study Notes & Guides', Icons.menu_book_outlined),
          _materialTile(
            title: "Lecture Notes",
            subtitle: "Summarized notes by chapters",
            icon: Icons.notes,
            onTap: () {},
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kAccentMuted),
          ),
          _materialTile(
            title: "Sample Assignments",
            subtitle: "Model answers and assignment tips",
            icon: Icons.assignment,
            iconBg: kCyanAccent,
            onTap: () {},
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kAccentMuted),
          ),
          _materialTile(
            title: "Reference Books",
            subtitle: "Recommended reading list",
            icon: Icons.book_outlined,
            iconBg: kPurpleAccent,
            onTap: () {},
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kAccentMuted),
          ),
          const SizedBox(height: 18),

          _sectionTitle('Useful Links', Icons.link_outlined),
          _materialTile(
            title: "University Portal",
            subtitle: "Check official notices and results",
            icon: Icons.language,
            iconBg: kIndigoAccent,
            onTap: () {},
            trailing: const Icon(Icons.open_in_new, color: kIndigoAccent),
          ),
          _materialTile(
            title: "Online Resources",
            subtitle: "Extra exercises and video lectures",
            icon: Icons.web,
            iconBg: kBlueAccent,
            onTap: () {},
            trailing: const Icon(Icons.open_in_new, color: kBlueAccent),
          ),
        ],
      ),
    );
  }
}
