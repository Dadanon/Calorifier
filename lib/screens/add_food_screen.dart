import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models.dart';
import '../widgets/search_food_list.dart';

class AddFoodScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddFoodScreen({super.key, required this.selectedDate});

  @override
  _AddFoodScreenState createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<FoodProvider>().loadRecentFoods();
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
      context.read<FoodProvider>().searchFoods(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Поиск',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: Consumer<FoodProvider>(
              builder: (context, provider, child) {
                if (_searchController.text.isEmpty) {
                  return ListView.builder(
                    itemCount: provider.recentFoods.length,
                    itemBuilder: (context, index) => _FoodItem(
                      food: provider.recentFoods[index],
                      onAdd: () => _addFood(provider.recentFoods[index]),
                    ),
                  );
                }
                return SearchFoodList(
                  foods: provider.searchResults,
                  onAdd: _addFood,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addFood(Food food) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => WeightInputDialog(food: food),
    );

    if (result != null && result['weight'] > 0) {
      await context.read<DiaryProvider>().addEntry(
          food, widget.selectedDate, result['weight'], result['type']);
      context.read<FoodProvider>().incrementRecent(food);
      Navigator.pop(context);
    }
  }
}

class WeightInputDialog extends StatefulWidget {
  final Food food;

  const WeightInputDialog({super.key, required this.food});

  @override
  _WeightInputDialogState createState() => _WeightInputDialogState();
}

class _WeightInputDialogState extends State<WeightInputDialog> {
  final _controller = TextEditingController();
  String _selectedMealType = 'Перекус'; // Переносим состояние в виджет

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.food.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText:
                  widget.food.weight == null ? 'Вес/объём' : 'Количество',
              suffixText: widget.food.weight == null ? 'г/мл' : 'шт.',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedMealType,
            decoration: const InputDecoration(
              labelText: 'Тип приёма пищи',
              border: OutlineInputBorder(),
            ),
            items: ['Завтрак', 'Обед', 'Ужин', 'Перекус']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedMealType = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            final value = int.tryParse(_controller.text) ?? 0;
            Navigator.pop(context, {
              'weight': value,
              'type': _selectedMealType,
            });
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}

class _FoodItem extends StatelessWidget {
  final Food food;
  final VoidCallback onAdd;

  const _FoodItem({required this.food, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(food.name),
      subtitle: Text(food.kcalPerHundred != null
          ? '${food.kcalPerHundred} ккал/100г'
          : '${food.weight}г • ${food.kcalTotal} ккал'),
      trailing: IconButton(
        icon: const Icon(Icons.add),
        onPressed: onAdd,
      ),
    );
  }
}
