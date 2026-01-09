import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 🎨 Palette
const kDarkBlue = Color(0xFF1B3C53);
const kMedBlue = Color(0xFF456882);
const kTan = Color(0xFFD2C1B6);
const kCream = Color(0xFFF9F3EF);
const kOffWhite = Color(0xFFFAF5F1);

class ExamPlannerPage extends StatefulWidget {
  const ExamPlannerPage({Key? key}) : super(key: key);

  @override
  State<ExamPlannerPage> createState() => _ExamPlannerPageState();
}

class _ExamPlannerPageState extends State<ExamPlannerPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _subjectCtrl = TextEditingController();
  DateTime? _examDate;
  _Difficulty _difficulty = _Difficulty.medium;

  final List<_Subject> _subjects = [];
  final Map<DateTime, List<_PlanItem>> _plan = {};
  bool _generated = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
  }

  // ===== HELPERS =====

  Future<void> _pickExamDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kDarkBlue,
              onPrimary: Colors.white,
              onSurface: kDarkBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _examDate = picked);
    }
  }

  void _addSubject() {
    if (!_formKey.currentState!.validate()) return;
    if (_examDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an exam date')),
      );
      return;
    }
    setState(() {
      _subjects.add(_Subject(
        name: _subjectCtrl.text.trim(),
        examDate: DateUtils.dateOnly(_examDate!),
        difficulty: _difficulty,
      ));
      _subjectCtrl.clear();
      _examDate = null;
      _difficulty = _Difficulty.medium;
      _generated = false;
    });
  }

  void _removeSubject(int index) {
    setState(() {
      _subjects.removeAt(index);
      _generated = false;
    });
  }

  void _clearPlan() {
    setState(() {
      _plan.clear();
      _generated = false;
    });
  }

  // ===== PLAN GENERATOR =====
  void _generatePlan() {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one subject')),
      );
      return;
    }
    _plan.clear();

    final today = DateUtils.dateOnly(DateTime.now());
    final weights = {
      _Difficulty.easy: 1,
      _Difficulty.medium: 2,
      _Difficulty.hard: 3
    };

    // Reserve revision days
    for (final s in _subjects) {
      for (int i = 2; i >= 1; i--) {
        final revDate =
        DateUtils.dateOnly(s.examDate.subtract(Duration(days: i)));
        if (!revDate.isBefore(today)) {
          _plan.putIfAbsent(revDate, () => []);
          _plan[revDate]!.add(_PlanItem(
            subject: s.name,
            type: _ItemType.revision,
            done: false,
          ));
        }
      }
    }

    // Weighted distribution
    final weightedSubjects = <_Subject>[];
    for (final s in _subjects) {
      for (int i = 0; i < weights[s.difficulty]!; i++) {
        weightedSubjects.add(s);
      }
    }
    if (weightedSubjects.isEmpty) return;

    final maxExam = _subjects
        .map((s) => s.examDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    int cursor = 0;
    for (DateTime d = today;
    !d.isAfter(maxExam);
    d = d.add(const Duration(days: 1))) {
      final items = _plan[d] ?? <_PlanItem>[];
      final isExamForSome =
      _subjects.any((s) => DateUtils.isSameDay(s.examDate, d));

      if (isExamForSome) {
        _plan[d] = items
          ..add(_PlanItem(
              subject: 'Exam Day', type: _ItemType.exam, done: false));
        continue;
      }

      int slots = 2;
      int tries = 0;
      while (slots > 0 && tries < weightedSubjects.length * 2) {
        final picked = weightedSubjects[cursor % weightedSubjects.length];
        cursor++;
        tries++;
        if (d.isAfter(picked.examDate)) continue;

        final alreadyRevisionForSubject = items.any((it) =>
        it.type == _ItemType.revision && it.subject == picked.name);
        if (alreadyRevisionForSubject) continue;

        final twoBefore = picked.examDate.subtract(const Duration(days: 2));
        final oneBefore = picked.examDate.subtract(const Duration(days: 1));
        if (DateUtils.isSameDay(d, twoBefore) ||
            DateUtils.isSameDay(d, oneBefore)) continue;

        items.add(_PlanItem(
            subject: picked.name, type: _ItemType.study, done: false));
        slots--;
      }
      if (items.isNotEmpty) _plan[d] = items;
    }

    setState(() => _generated = true);
  }

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMMd();

    return Scaffold(
      backgroundColor: kOffWhite,
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        title: const Text("📘 Smart Exam Planner",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputCard(),
            const SizedBox(height: 20),
            _buildActions(),
            const SizedBox(height: 20),
            if (_generated && _plan.isEmpty)
              const Center(
                child: Text("No study days available before exams.",
                    style: TextStyle(color: kDarkBlue)),
              ),
            if (_plan.isNotEmpty) _buildPlanList(dateFmt),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: kDarkBlue.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: const [
                  Icon(Icons.add_task, color: kDarkBlue),
                  SizedBox(width: 8),
                  Text("Add Subject",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectCtrl,
                decoration: InputDecoration(
                  labelText: "Subject name",
                  prefixIcon: const Icon(Icons.book_outlined),
                  filled: true,
                  fillColor: kCream,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? "Enter subject" : null,
              ),
              const SizedBox(height: 14),

              // ✅ FIXED ROW
              Row(
                children: [
                  // Exam Date Picker
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: _pickExamDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: kCream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_outlined, color: kMedBlue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _examDate == null
                                    ? "Pick exam date"
                                    : DateFormat.yMMMd().format(_examDate!),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: _examDate == null
                                      ? Colors.black54
                                      : kDarkBlue,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Difficulty Dropdown
                  Flexible(
                    flex: 1,
                    child: DropdownButtonFormField<_Difficulty>(
                      value: _difficulty,
                      items: const [
                        DropdownMenuItem(
                            value: _Difficulty.easy, child: Text("Easy")),
                        DropdownMenuItem(
                            value: _Difficulty.medium, child: Text("Medium")),
                        DropdownMenuItem(
                            value: _Difficulty.hard, child: Text("Hard")),
                      ],
                      onChanged: (v) =>
                          setState(() => _difficulty = v ?? _Difficulty.medium),
                      decoration: InputDecoration(
                        labelText: "Difficulty",
                        filled: true,
                        fillColor: kCream,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _addSubject,
                icon: const Icon(Icons.add),
                label: const Text("Add Subject"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMedBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_subjects.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _subjects.asMap().entries.map((e) {
                    final i = e.key;
                    final s = e.value;
                    return Chip(
                      backgroundColor: kTan.withOpacity(0.3),
                      label: Text(
                          "${s.name} • ${DateFormat.MMMd().format(s.examDate)} • ${s.difficulty.name}",
                          style: const TextStyle(color: kDarkBlue)),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeSubject(i),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    );
                  }).toList(),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _generatePlan,
            icon: const Icon(Icons.auto_awesome),
            label: const Text("Generate Plan"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A9D8F),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearPlan,
            icon: const Icon(Icons.refresh),
            label: const Text("Clear"),
            style: OutlinedButton.styleFrom(
              foregroundColor: kDarkBlue,
              side: const BorderSide(color: kDarkBlue, width: 1.3),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanList(DateFormat dateFmt) {
    final dates = _plan.keys.toList()..sort((a, b) => a.compareTo(b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("📅 Your Plan",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: kDarkBlue)),
        const SizedBox(height: 12),
        ...dates.map((d) {
          final items = _plan[d]!;
          return Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 14),
            child: ExpansionTile(
              tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Text(dateFmt.format(d),
                  style: const TextStyle(
                      color: kDarkBlue, fontWeight: FontWeight.w600)),
              subtitle: Text("${items.length} task(s)",
                  style: const TextStyle(color: kMedBlue)),
              children: [
                ...items.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  return CheckboxListTile(
                    value: item.done,
                    onChanged: (v) {
                      setState(() => item.done = v ?? false);
                    },
                    title: Row(
                      children: [
                        _typeBadge(item.type),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.subject,
                              style: TextStyle(
                                color: kDarkBlue,
                                decoration: item.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              )),
                        )
                      ],
                    ),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          items.removeAt(idx);
                          if (items.isEmpty) _plan.remove(d);
                        });
                      },
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          );
        })
      ],
    );
  }

  Widget _typeBadge(_ItemType type) {
    late String text;
    late Color bg;
    switch (type) {
      case _ItemType.study:
        text = "Study";
        bg = kTan.withOpacity(0.4);
        break;
      case _ItemType.revision:
        text = "Revision";
        bg = const Color(0xFFE9C46A).withOpacity(0.35);
        break;
      case _ItemType.exam:
        text = "Exam";
        bg = const Color(0xFF2A9D8F).withOpacity(0.3);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: kDarkBlue)),
    );
  }
}

// ===== Models =====
enum _Difficulty { easy, medium, hard }

extension on _Difficulty {
  String get name {
    switch (this) {
      case _Difficulty.easy:
        return "Easy";
      case _Difficulty.medium:
        return "Medium";
      case _Difficulty.hard:
        return "Hard";
    }
  }
}

class _Subject {
  final String name;
  final DateTime examDate;
  final _Difficulty difficulty;
  _Subject(
      {required this.name, required this.examDate, required this.difficulty});
}

enum _ItemType { study, revision, exam }

class _PlanItem {
  final String subject;
  final _ItemType type;
  bool done;
  _PlanItem({required this.subject, required this.type, this.done = false});
}
