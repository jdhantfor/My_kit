import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/add_lechenie/add_lechenie.dart';
import 'package:provider/provider.dart';
import 'package:my_aptechka/screens/user_provider.dart';

class TreatmentCourseBox extends StatelessWidget {
  final Function(int?) onSelectCourse;
  final int? selectedCourseId;

  const TreatmentCourseBox({
    super.key,
    required this.onSelectCourse,
    this.selectedCourseId,
  });

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context).userId;
    if (userId == null) {
      return const Text('Пожалуйста, войдите в систему');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Курс лечения',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showCoursesBottomSheet(context, userId),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<String>(
                    future: selectedCourseId != null
                        ? DatabaseService.getCourseName(
                            selectedCourseId!, userId)
                        : Future.value('Курс лечения'),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'Курс лечения',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: selectedCourseId != null
                              ? const Color(0xFF0B102B)
                              : const Color(0xFF6B7280),
                        ),
                      );
                    },
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF197FF2),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCoursesBottomSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseService.getCourses(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            }
            final courses = snapshot.data ?? [];

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Курс лечения',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: courses.length + 1,
                      itemBuilder: (context, index) {
                        if (index == courses.length) {
                          return ListTile(
                            leading: const Icon(Icons.add),
                            title: const Text('Добавить курс'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddLechenieScreen(userId: userId),
                                ),
                              ).then((newCourseId) {
                                if (newCourseId != null) {
                                  onSelectCourse(newCourseId as int);
                                }
                              });
                            },
                          );
                        }
                        final course = courses[index];
                        return ListTile(
                          title: Text(course['name']),
                          onTap: () {
                            onSelectCourse(course['id']);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
