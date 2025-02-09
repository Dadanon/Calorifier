import 'package:flutter/material.dart';
import '../models.dart';

class SearchFoodList extends StatelessWidget {
  final List<Food> foods;
  final Function(Food) onAdd;

  const SearchFoodList({
    super.key,
    required this.foods,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: foods.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(foods[index].name),
        subtitle: Text(foods[index].kcalPerHundred != null
            ? '${foods[index].kcalPerHundred} ккал/100г'
            : '${foods[index].weight}г • ${foods[index].kcalTotal} ккал'),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => onAdd(foods[index]),
        ),
      ),
    );
  }
}
