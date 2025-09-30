// INFO: виджет, обозначающий позицию еды (food) на экране добавления записей
import 'package:flutter/material.dart';
import '../models.dart';

class FoodItem extends StatelessWidget {
  final Food food;
  final VoidCallback onAdd;

  const FoodItem({required this.food, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          food.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text(
              food.kcalPerHundred != null
                  ? '${food.kcalPerHundred} ккал/100г'
                  : '${food.weight}г • ${food.kcalTotal} ккал',
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.add,
            size: 32,
          ),
          onPressed: onAdd,
        ),
      ),
    );
  }
}
