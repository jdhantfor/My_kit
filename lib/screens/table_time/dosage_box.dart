import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DosageBox extends StatefulWidget {
  final List<Map<String, dynamic>> timesAndDosages;
  final Function(String, int)
      onTimeAndDosageAdded; // Изменено: принимает String для времени
  final Function(int, int) onTimeAndDosageUpdated;
  final Function(int) onTimeAndDosageRemoved;

  const DosageBox({
    super.key,
    required this.timesAndDosages,
    required this.onTimeAndDosageAdded,
    required this.onTimeAndDosageUpdated,
    required this.onTimeAndDosageRemoved,
  });

  @override
  _DosageBoxState createState() => _DosageBoxState();
}

class _DosageBoxState extends State<DosageBox> {
  final TimeOfDay _selectedTime = TimeOfDay.now();

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
          'Время приема и дозировка',
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
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Редактируемое поле для дозировки
                            SizedBox(
                              width: 80,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      widget.onTimeAndDosageUpdated(
                                          index, int.parse(value));
                                    });
                                  }
                                },
                                controller: TextEditingController(
                                    text: timeAndDosage['dosage'].toString()),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF197FF2),
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const Text(' мг'), // Пример единицы измерения
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          widget.onTimeAndDosageRemoved(index);
                        },
                      ),
                    ],
                  ),
                );
              }),
              Center(
                child: TextButton(
                  onPressed: () {
                    _showTimeAndDosagePicker(context);
                  },
                  child: const Text(
                    '+ Добавить время приема',
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

  void _showTimeAndDosagePicker(BuildContext context) async {
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
      widget.onTimeAndDosageAdded(formattedTime, 1);
    }
  }
}
