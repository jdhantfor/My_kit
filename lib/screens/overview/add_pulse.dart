import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для TextInputFormatter
import 'package:my_aptechka/screens/database_service.dart';

class AddPulse extends StatefulWidget {
  final String title;
  final String userId;

  const AddPulse({super.key, required this.title, required this.userId});

  @override
  _AddPulseState createState() => _AddPulseState();
}

class _AddPulseState extends State<AddPulse> {
  bool _showBloodPressure = false;
  final TextEditingController _pulseController = TextEditingController();
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  DateTime _measurementTime = DateTime.now();

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
            _buildInputField(_pulseController, 'Пульс'),
            const SizedBox(height: 16),
            if (!_showBloodPressure)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showBloodPressure = true;
                  });
                },
                child: const Text(
                  '+ Добавить измерение давления',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            if (_showBloodPressure) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildInputField(
                          _systolicController, 'Систолическое')),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildInputField(
                          _diastolicController, 'Диастолическое')),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Время измерения',
                    style: TextStyle(color: Colors.black)),
                GestureDetector(
                  onTap: () => _selectDateTime(context),
                  child: Row(
                    children: [
                      Text(
                        '${_measurementTime.day}.${_measurementTime.month}.${_measurementTime.year} ${_measurementTime.hour}:${_measurementTime.minute}',
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
            _buildInputField(_commentController, 'Комментарий к измерению',
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
              onPressed: _savePulse,
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
        color: Colors.blue.withOpacity(0.1), // Оставляем голубой фон
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
            maxLength: isNumeric ? 3 : null,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              filled: false, // Отключаем заливку фона из темы
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              counterText: '',
            ),
            inputFormatters: isNumeric
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    // Ограничение на ввод значений от 1 до 200
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final value = int.tryParse(newValue.text);
                      if (value == null || value < 1 || value > 200) {
                        return oldValue; // Отклоняем ввод, если значение вне диапазона
                      }
                      return newValue;
                    }),
                  ]
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _measurementTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_measurementTime),
      );
      if (pickedTime != null) {
        setState(() {
          _measurementTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _savePulse() async {
    final int? pulse = int.tryParse(_pulseController.text);
    final int? systolic =
        _showBloodPressure ? int.tryParse(_systolicController.text) : null;
    final int? diastolic =
        _showBloodPressure ? int.tryParse(_diastolicController.text) : null;
    final String comment = _commentController.text;

    // Дополнительная валидация перед сохранением
    if (pulse == null || pulse < 0 || pulse > 299) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Пульс должен быть в диапазоне от 1 до 299')),
      );
      return;
    }

    print('Сохраняем данные пульса:');
    print('Время измерения: ${_measurementTime.toIso8601String()}');
    print('Пульс: $pulse');
    print('Систолическое давление: $systolic');
    print('Диастолическое давление: $diastolic');
    print('Комментарий: $comment');
    print('UserId: ${widget.userId}');

    try {
      await DatabaseService.addPulseData(
        _measurementTime.toIso8601String(),
        pulse,
        widget.userId,
        systolic: systolic,
        diastolic: diastolic,
        comment: comment.isNotEmpty ? comment : null,
      );
      print('Данные успешно сохранены в базу данных');
      Navigator.pop(context);
    } catch (e) {
      print('Ошибка при сохранении данных: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении данных: $e')),
      );
    }
  }
}
