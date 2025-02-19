import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Количество и сроки',
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
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Осталось',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0B102B),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _showQuantityPicker(context);
                      },
                      child: Row(
                        children: [
                          Text(
                            '${widget.quantity} ${widget.unit}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF197FF2),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF197FF2),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                color: Color(0xFFE0E0E0),
                thickness: 1,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Срок годности',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0B102B),
                      ),
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
                              color: Color(0xFF197FF2),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF197FF2),
                            size: 24,
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
      ],
    );
  }

  void _showQuantityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 42.0,
                  onSelectedItemChanged: (int index) {
                    widget.onQuantityChanged(index + 1);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: widget.quantity == index + 1 ? 24 : 16,
                            fontWeight: widget.quantity == index + 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                    childCount: 100,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF197FF2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExpirationDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.expirationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      widget.onExpirationDateChanged(pickedDate);
    }
  }
}
