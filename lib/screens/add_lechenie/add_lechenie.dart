import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'add_lechenie_items_screen.dart';
import '/screens/database_service.dart';

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
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Введите название \nкурса лечения',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(25, 127, 242, 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(
                  16, 8, 16, 8), // Уменьшили нижний отступ
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Название курса',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$_charCount/25',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
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
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
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
                  backgroundColor: const Color(0xFF197FF2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Продолжить',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
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
        const SnackBar(
          content: Text('Пожалуйста, введите название курса'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
