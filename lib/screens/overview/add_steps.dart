import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart';

class AddSteps extends StatefulWidget {
  final String title;
  final String userId;

  const AddSteps({super.key, required this.title, required this.userId});

  @override
  _AddStepsState createState() => _AddStepsState();
}

class _AddStepsState extends State<AddSteps> {
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputField(_stepsController, 'Шаги'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Дата', style: TextStyle(color: Colors.black)),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Row(
                    children: [
                      Text(
                        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputField(_commentController, 'Комментарий',
                isNumeric: false),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _saveSteps,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint,
      {bool isNumeric = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              hint,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            maxLength: isNumeric ? 5 : null,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveSteps() async {
    final int? steps = int.tryParse(_stepsController.text);

    if (steps != null) {
      try {
        await DatabaseService.addStepsData(
          _selectedDate.toIso8601String(),
          steps,
          widget.userId,
          comment: _commentController.text,
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при сохранении данных: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Пожалуйста, введите корректное количество шагов')),
      );
    }
  }
}
