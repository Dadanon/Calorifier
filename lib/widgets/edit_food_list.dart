import 'package:calorifier/models.dart';
import 'package:calorifier/widgets/edit_food_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';

class EditFoodList extends StatefulWidget {
  const EditFoodList({super.key});

  @override
  _EditFoodListState createState() => _EditFoodListState();
}

class _EditFoodListState extends State<EditFoodList> {
  void _showEditFoodDialog(BuildContext context, Food food) {
    showDialog(
      context: context,
      builder: (context) => EditFoodDialog(food: food),
    );
  }

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
              child: Consumer<FoodProvider>(
                  builder: (context, provider, child) => ListView.builder(
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
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Row(
                                  children: [
                                    if (food.weight != null)
                                      Text('${food.weight}г. * '),
                                    if (food.kcalPerHundred != null)
                                      Text('${food.kcalPerHundred} ккал/100г'),
                                    if (food.kcalTotal != null)
                                      Text('${food.kcalTotal}ккал')
                                  ],
                                ),
                                trailing: const IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () =>
                                      _showEditFoodDialog(context, food),
                                ),
                              ));
                        },
                      )),
            ),
          ],
        );
      },
    );
  }
}
