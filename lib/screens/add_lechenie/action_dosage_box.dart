import 'package:flutter/material.dart';

class ActionDosageBox extends StatefulWidget {
  final List<Map<String, dynamic>> timesAndDosages;
  final Function(String) onTimeAdded;
  final Function(int, String) onTimeUpdated;
  final Function(int) onTimeRemoved;

  const ActionDosageBox({
    super.key,
    required this.timesAndDosages,
    required this.onTimeAdded,
    required this.onTimeUpdated,
    required this.onTimeRemoved,
  });

  @override
  _ActionDosageBoxState createState() => _ActionDosageBoxState();
}

class _ActionDosageBoxState extends State<ActionDosageBox> {
  final TimeOfDay _selectedTime = TimeOfDay.now();

  String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Text(
            'Время действия',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              timeAndDosage['time'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF197FF2),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                _showTimePicker(context, index);
                              },
                              child: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF197FF2),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            widget.onTimeRemoved(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (widget.timesAndDosages.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      _showTimePicker(context);
                    },
                    child: const Text(
                      '+ Добавить время действия',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF197FF2),
                      ),
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

  void _showTimePicker(BuildContext context, [int? index]) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: index != null && widget.timesAndDosages.isNotEmpty
          ? TimeOfDay(
              hour: int.parse(
                  widget.timesAndDosages[index]['time'].split(':')[0]),
              minute: int.parse(
                  widget.timesAndDosages[index]['time'].split(':')[1]),
            )
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF197FF2),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black),
            ),
          ),
          child: Localizations.override(
            context: context,
            locale: const Locale('ru', 'RU'),
            child: child!,
          ),
        );
      },
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (pickedTime != null) {
      final formattedTime = formatTime(pickedTime);
      if (index != null) {
        widget.onTimeUpdated(index, formattedTime);
      } else {
        widget.onTimeAdded(formattedTime);
      }
    }
  }
}
