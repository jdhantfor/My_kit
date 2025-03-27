import 'package:flutter/material.dart';

Widget buildCircularIconButton({
  required String iconAsset,
  required VoidCallback onPressed,
  double size = 38,
}) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
    ),
    child: InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          iconAsset,
          width: size - 16,
          height: size - 16,
        ),
      ),
    ),
  );
}
