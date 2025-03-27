import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/add_lechenie/add_lechenie.dart';
import 'package:provider/provider.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import '/styles.dart'; // Импортируем AppColors

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
    print('TreatmentCourseBox: build started');
    final userId = Provider.of<UserProvider>(context).userId;
    if (userId == null) {
      print('TreatmentCourseBox: userId is null');
      return const Text('Пожалуйста, войдите в систему');
    }
    print('TreatmentCourseBox: userId: $userId');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0), // Отступы по бокам
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding:
                EdgeInsets.only(left: 20.0), // Отступ слева для подзаголовка
            child: Text(
              'Курс лечения',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500, // medium
                color: AppColors.secondaryGrey,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [],
            ),
            child: InkWell(
              onTap: () => _showCoursesBottomSheet(context, userId),
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Курс лечения',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500, // medium
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      Row(
                        children: [
                          FutureBuilder<String>(
                            future: selectedCourseId != null
                                ? DatabaseService.getCourseName(
                                    selectedCourseId!, userId)
                                : Future.value('Создать'),
                            builder: (context, snapshot) {
                              print(
                                  'TreatmentCourseBox: FutureBuilder snapshot for right side: $snapshot');
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox.shrink();
                              }
                              if (snapshot.hasError) {
                                print(
                                    'TreatmentCourseBox: FutureBuilder error for right side: ${snapshot.error}');
                                return const Text(
                                  'Создать',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500, // medium
                                    color: AppColors.primaryBlue,
                                  ),
                                );
                              }
                              return Text(
                                snapshot.data ?? 'Создать',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500, // medium
                                  color: AppColors.primaryBlue,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          SvgPicture.asset(
                            'assets/arrow_forward_blue.svg',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ],
                  )),
            ),
          ),
        ],
      ),
    );
  }

  void _showCoursesBottomSheet(BuildContext context, String userId) {
    print('TreatmentCourseBox: _showCoursesBottomSheet called');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white, // Белый фон всплывашки
      builder: (BuildContext context) {
        return Container(
          height: 400, // Ограничиваем высоту BottomSheet
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: DatabaseService.getCourses(userId),
            builder: (context, snapshot) {
              print(
                  'TreatmentCourseBox: BottomSheet FutureBuilder snapshot: $snapshot');
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print(
                    'TreatmentCourseBox: BottomSheet FutureBuilder error: ${snapshot.error}');
                return Center(child: Text('Ошибка: ${snapshot.error}'));
              }
              final courses = snapshot.data ?? [];
              print('TreatmentCourseBox: Courses loaded: $courses');

              // Список цветов для кружочков
              final colors = [
                const Color.fromRGBO(22, 178, 217, 0.2), // Голубой
                const Color.fromRGBO(86, 199, 0, 0.2), // Зелёный
                const Color.fromRGBO(159, 25, 242, 0.2), // Фиолетовый
                const Color.fromRGBO(242, 25, 141, 0.2), // Розовый
                const Color.fromRGBO(242, 153, 0, 0.2), // Оранжевый
              ];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Курс лечения',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600, // semibold
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Выберите из уже существующих\nили добавьте новый',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400, // regular
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: courses.length + 1,
                      itemBuilder: (context, index) {
                        if (index == courses.length) {
                          return ListTile(
                            title: const Text(
                              'Добавить новый курс лечения',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400, // regular
                              ),
                            ),
                            trailing: SvgPicture.asset(
                              'assets/arrow_forward.svg',
                              width: 20,
                              height: 20,
                            ),
                            onTap: () {
                              print(
                                  'TreatmentCourseBox: Navigating to AddLechenieScreen');
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddLechenieScreen(userId: userId),
                                ),
                              ).then((newCourseId) {
                                print(
                                    'TreatmentCourseBox: Returned from AddLechenieScreen with newCourseId: $newCourseId');
                                if (newCourseId != null) {
                                  onSelectCourse(newCourseId as int);
                                }
                              });
                            },
                          );
                        }
                        final course = courses[index];
                        final isSelected = selectedCourseId == course['id'];
                        final circleColor =
                            colors[index % colors.length]; // Чередуем цвета

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) {
                            print(
                                'TreatmentCourseBox: Course selection changed: ${course['id']}, value: $value');
                            if (value == true) {
                              onSelectCourse(course['id']);
                            } else {
                              onSelectCourse(null);
                            }
                            Navigator.pop(context);
                          },
                          title: Text(
                            course['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400, // regular
                            ),
                          ),
                          activeColor: AppColors
                              .primaryBlue, // Цвет галочки и обводки при выборе
                          checkColor: Colors.white, // Цвет самой галочки
                          secondary: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: circleColor,
                            ),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.secondaryGrey,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
