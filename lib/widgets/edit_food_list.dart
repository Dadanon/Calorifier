import 'dart:async';

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
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<FoodProvider>().filterFoods(_searchController.text);
    });
    print('Length: ${context.read<FoodProvider>().filteredFoods.length}');
  }

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
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Поиск',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(
              height: 400, // Фиксированная высота или MediaQuery
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: provider.filteredFoods.length,
                itemBuilder: (context, index) {
                  final food = provider.filteredFoods[index];

                  return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(food.name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold))
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            if (food.weight != null)
                              Text('${food.weight}г. * '),
                            if (food.kcalPerHundred != null)
                              Expanded(
                                  child:
                                      Text('${food.kcalPerHundred} ккал/100г')),
                            if (food.kcalTotal != null)
                              Expanded(child: Text('${food.kcalTotal}ккал')),
                            IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () =>
                                    _showEditFoodDialog(context, food)),
                          ],
                        ),
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
