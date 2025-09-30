import 'package:flutter/material.dart';

Widget mealTypeBadge(String type) {
  Color bgColor;
  switch (type) {
    case 'Завтрак':
      bgColor = Colors.green;
    case 'Обед':
      bgColor = Colors.orange;
    case 'Ужин':
      bgColor = Colors.blue;
    default:
      bgColor = Colors.grey;
  }

  return Container(
    width: 66,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      type,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
