import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Добавляем импорт для SVG
import 'add_lechenie_items_screen.dart';
import '/screens/database_service.dart';
import '/styles.dart';

class AddLechenieScreen extends StatefulWidget {
  final String userId;

  const AddLechenieScreen({super.key, required this.userId});

  @override
  _AddLechenieScreenState createState() => _AddLechenieScreenState();
}

class _AddLechenieScreenState extends State<AddLechenieScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateCharCount);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateCharCount);
    _nameController.dispose();
    super.dispose();
  }

  void _updateCharCount() {
    setState(() {
      _charCount = _nameController.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          icon: SvgPicture.asset(
            'assets/arrow_back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Введите название\nкурса лечения',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: const Color(0xFF0B102B),
                  ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.activeFieldBlue, // Используем цвет из стилей
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Название курса',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                      Text(
                        '$_charCount/25',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '',
                      contentPadding: EdgeInsets.only(bottom: 8),
                      filled: false, // Убираем серый фон
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF0B102B),
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                    maxLength: 25,
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _continueToCourseItems(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  'Продолжить',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueToCourseItems() async {
    if (_nameController.text.isNotEmpty) {
      int courseId = await DatabaseService.addCourse(
          {'name': _nameController.text, 'user_id': widget.userId},
          widget.userId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AddLechenieItemsScreen(courseId: courseId, userId: widget.userId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Пожалуйста, введите название курса',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
