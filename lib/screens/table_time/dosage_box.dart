import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DosageBox extends StatefulWidget {
  final List<Map<String, dynamic>> timesAndDosages;
  final Function(String, int) onTimeAndDosageAdded;
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

  // Настраиваемые параметры
  final double horizontalPadding = 12.0;
  final double verticalPadding = 12.0;
  final double sectionSpacing = 16.0;
  final double dividerHorizontalPadding = 16.0;
  final double iconSize = 20.0;
  final double appBarTitleSpacing = 8.0;
  final double containerInnerPadding = 4.0;
  final double dosageFieldWidth = 24.0; // Уменьшенная ширина для TextField

  /// Преобразует TimeOfDay в строку формата 'HH:mm'
  String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _editTime(BuildContext context, int index) async {
    final currentTime = widget.timesAndDosages[index]['time'];
    final hoursAndMinutes = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(hoursAndMinutes[0]),
      minute: int.parse(hoursAndMinutes[1]),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: AppColors.primaryText),
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
      setState(() {
        widget.timesAndDosages[index]['time'] = formattedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 4),
            child: Text(
              'Время приема и дозировка',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryGrey,
                  ),
            ),
          ),
          SizedBox(height: verticalPadding / 3),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Padding(
              padding:
                  EdgeInsets.all(containerInnerPadding), // Внутренние отступы 4
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.timesAndDosages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final timeAndDosage = entry.value;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          title: Row(
                            children: [
                              InkWell(
                                onTap: () => _editTime(context, index),
                                child: Row(
                                  children: [
                                    Text(
                                      timeAndDosage['time'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.primaryBlue,
                                          ),
                                    ),
                                    SizedBox(width: appBarTitleSpacing),
                                    SvgPicture.asset(
                                      'assets/arrow_forward_blue.svg',
                                      width: iconSize,
                                      height: iconSize,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: appBarTitleSpacing),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width:
                                          dosageFieldWidth, // Уменьшенная ширина
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(8),
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
                                            text: timeAndDosage['dosage']
                                                .toString()),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.primaryBlue,
                                            ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          filled: true,
                                          fillColor: Colors
                                              .transparent, // Прозрачный фон
                                          contentPadding: EdgeInsets
                                              .zero, // Убираем внутренние отступы
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ' мг',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: SvgPicture.asset(
                                  'assets/delete.svg',
                                  width: iconSize,
                                  height: iconSize,
                                  color: AppColors.errorRed,
                                ),
                                onPressed: () {
                                  widget.onTimeAndDosageRemoved(index);
                                },
                              ),
                            ],
                          ),
                        ),
                        if (index < widget.timesAndDosages.length - 1)
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: dividerHorizontalPadding),
                            child: const Divider(
                              color: AppColors.fieldBackground,
                              thickness: 1,
                            ),
                          ),
                      ],
                    );
                  }),
                  if (widget.timesAndDosages.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: dividerHorizontalPadding),
                      child: const Divider(
                        color: AppColors.fieldBackground,
                        thickness: 1,
                      ),
                    ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        _showTimeAndDosagePicker(context);
                      },
                      child: Text(
                        '+ Добавить время приема',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primaryBlue,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
              primary: AppColors.primaryBlue,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: AppColors.primaryText),
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
      widget.onTimeAndDosageAdded(formattedTime, 1);
    }
  }
}
