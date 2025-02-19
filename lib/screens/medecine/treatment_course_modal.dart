import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart';

class TreatmentCourseModal extends StatefulWidget {
  final String userId;
  final int medicineId;

  const TreatmentCourseModal({
    super.key,
    required this.userId,
    required this.medicineId,
  });

  @override
  _TreatmentCourseModalState createState() => _TreatmentCourseModalState();
}

class _TreatmentCourseModalState extends State<TreatmentCourseModal> {
  List<Map<String, dynamic>> _treatmentCourses = [];

  @override
  void initState() {
    super.initState();
    _loadTreatmentCourses();
  }

  Future<void> _loadTreatmentCourses() async {
    final courses = await DatabaseService.getCourses(widget.userId);
    setState(() {
      _treatmentCourses = courses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Выберите курс лечения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 48), // Для баланса с кнопкой закрытия
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _treatmentCourses.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey[300],
                height: 1,
              ),
              itemBuilder: (context, index) {
                final course = _treatmentCourses[index];
                return ListTile(
                  title: Text(
                    course['name'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey[400],
                  ),
                  onTap: () {
                    // Здесь будет логика добавления лекарства в курс
                    print('Выбран курс: ${course['name']}');
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
