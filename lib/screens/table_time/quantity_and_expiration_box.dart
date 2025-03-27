import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '/styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuantityAndExpirationBox extends StatefulWidget {
  final String unit;
  final DateTime expirationDate;
  final Function(DateTime) onExpirationDateChanged;
  final int quantity;
  final Function(int) onQuantityChanged;

  const QuantityAndExpirationBox({
    super.key,
    required this.unit,
    required this.expirationDate,
    required this.onExpirationDateChanged,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  _QuantityAndExpirationBoxState createState() =>
      _QuantityAndExpirationBoxState();
}

class _QuantityAndExpirationBoxState extends State<QuantityAndExpirationBox> {
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController =
        TextEditingController(text: widget.quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              'Количество и сроки',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryGrey,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 16, bottom: 8, left: 4, right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // Растягиваем элементы по ширине
                      crossAxisAlignment: CrossAxisAlignment
                          .baseline, // Выравниваем по базовой линии текста
                      textBaseline: TextBaseline
                          .alphabetic, // Указываем тип базовой линии
                      children: [
                        Text(
                          'Осталось единиц',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment
                              .baseline, // Выравниваем вложенные элементы по базовой линии
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            SizedBox(
                              width: 48, // Фиксированная ширина для TextField
                              child: TextField(
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    final newQuantity = int.parse(value);
                                    widget.onQuantityChanged(newQuantity);
                                    setState(() {});
                                  } else {
                                    widget.onQuantityChanged(0);
                                  }
                                },
                                controller: _quantityController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.primaryBlue,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor: Color.fromARGB(0, 97, 97, 97),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 0),
                                ),
                              ),
                            ),
                            const SizedBox(
                                width:
                                    8), // Отступ между полем ввода и единицей измерения
                            Text(
                              widget.unit,
                              style: const TextStyle(
                                fontFamily: 'Commissioner',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                height: 22 / 16,
                                color: Color.fromARGB(141, 0, 0, 0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 0),
                    child: Divider(
                      color: AppColors.fieldBackground,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Срок годности',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        InkWell(
                          onTap: () {
                            _showExpirationDatePicker(context);
                          },
                          child: Row(
                            children: [
                              Text(
                                DateFormat('dd.MM.yyyy')
                                    .format(widget.expirationDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SvgPicture.asset(
                                'assets/arrow_forward_blue.svg',
                                width: 20,
                                height: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  void _showExpirationDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.expirationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      widget.onExpirationDateChanged(pickedDate);
    }
  }
}
