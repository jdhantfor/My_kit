import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart'; // Убедитесь, что путь к файлу правильный

class AddBloodPressure extends StatefulWidget {
  final String title;
  final String userId;

  const AddBloodPressure(
      {super.key, required this.title, required this.userId});

  @override
  _AddBloodPressureState createState() => _AddBloodPressureState();
}

class _AddBloodPressureState extends State<AddBloodPressure> {
  bool _showPulse = false;
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
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
            Row(
              children: [
                Expanded(
                    child:
                        _buildInputField(_systolicController, 'Систолическое')),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildInputField(
                        _diastolicController, 'Диастолическое')),
              ],
            ),
            const SizedBox(height: 16),
            if (!_showPulse)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showPulse = true;
                  });
                },
                child: const Text(
                  '+ Добавить измерение пульса',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            if (_showPulse) ...[
              const SizedBox(height: 16),
              _buildInputField(_pulseController, 'Пульс'),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Время измерения',
                    style: TextStyle(color: Colors.black)),
                GestureDetector(
                  onTap: _selectDateTime,
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
              onPressed: _saveBloodPressure,
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
            maxLength: isNumeric ? 3 : null,
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

  Future<void> _selectDateTime() async {
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

  void _saveBloodPressure() async {
    final int? systolic = int.tryParse(_systolicController.text);
    final int? diastolic = int.tryParse(_diastolicController.text);
    final int? pulse = _showPulse ? int.tryParse(_pulseController.text) : null;

    if (systolic != null && diastolic != null) {
      try {
        await DatabaseService.addBloodPressureData(
          _measurementTime.toIso8601String(),
          systolic,
          diastolic,
          widget.userId,
          pulse: pulse,
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
            content: Text('Пожалуйста, введите корректные значения давления')),
      );
    }
  }
}
