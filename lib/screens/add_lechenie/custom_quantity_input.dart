import 'package:flutter/material.dart';

class CustomQuantityInput extends StatefulWidget {
  final double quantity;
  final Function(double) onQuantityChanged;

  const CustomQuantityInput({
    super.key,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  _CustomQuantityInputState createState() => _CustomQuantityInputState();
}

class _CustomQuantityInputState extends State<CustomQuantityInput> {
  bool _isFocused = false;
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.quantity.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFocused = true;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: _isFocused ? const Color(0x14197FF2) : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Количество выпитой воды (литров)',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: _isFocused ? Colors.black : Colors.grey,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    double? newQuantity = double.tryParse(value);
                    if (newQuantity != null) {
                      widget.onQuantityChanged(newQuantity);
                    }
                  });
                },
                onTapOutside: (event) {
                  setState(() {
                    _isFocused = false;
                  });
                },
              ),
            ),
            if (_isFocused)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  _controller.text.isEmpty ? '' : _controller.text,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
