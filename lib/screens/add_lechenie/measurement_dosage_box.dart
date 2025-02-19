import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MeasurementDosageBox extends StatefulWidget {
  final List<Map<String, dynamic>> timesAndDosages;
  final Function(String) onTimeAdded; // Изменено: принимает String для времени
  final Function(int, String) onTimeUpdated;
  final Function(int) onTimeRemoved;

  const MeasurementDosageBox({
    super.key,
    required this.timesAndDosages,
    required this.onTimeAdded,
    required this.onTimeUpdated,
    required this.onTimeRemoved,
  });

  @override
  _MeasurementDosageBoxState createState() => _MeasurementDosageBoxState();
}

class _MeasurementDosageBoxState extends State<MeasurementDosageBox> {
  TimeOfDay _selectedTime = TimeOfDay.now();

  /// Преобразует TimeOfDay в строку формата 'HH:mm'
  String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Время измерения',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...widget.timesAndDosages.asMap().entries.map((entry) {
                final index = entry.key;
                final timeAndDosage = entry.value;
                return ListTile(
                  title: Row(
                    children: [
                      Text(
                        timeAndDosage[
                            'time'], // Используем уже сохраненное время в формате 'HH:mm'
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF197FF2),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          widget.onTimeRemoved(index);
                        },
                      ),
                    ],
                  ),
                );
              }),
              Center(
                child: TextButton(
                  onPressed: () {
                    _showTimePicker(context);
                  },
                  child: const Text(
                    '+ Добавить время измерения',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF197FF2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTimePicker(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF197FF2), // Цвет кнопки "OK"
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black), // Цвет текста
            ),
          ),
          child: Localizations.override(
            context: context,
            locale: const Locale('ru', 'RU'), // Устанавливаем локаль на русский
            child: child!,
          ),
        );
      },
      initialEntryMode:
          TimePickerEntryMode.dial, // Используем dial для выбора времени
    );
    if (pickedTime != null) {
      // Преобразуем выбранное время в строку формата 'HH:mm' и передаем её
      final formattedTime = formatTime(pickedTime);
      widget.onTimeAdded(formattedTime);
    }
  }
}
