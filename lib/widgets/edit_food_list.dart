import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';

class EditFoodList extends StatefulWidget {
  const EditFoodList({super.key});

  @override
  _EditFoodListState createState() => _EditFoodListState();
}

class _EditFoodListState extends State<EditFoodList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<FoodProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Список всех продуктов',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 400, // Фиксированная высота или MediaQuery
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: provider.foods.length,
                itemBuilder: (context, index) {
                  final food = provider.foods[index];
                  return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(food.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
