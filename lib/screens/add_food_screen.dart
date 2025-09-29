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
  final _formKey = GlobalKey<FormState>();
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
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        context.read<FoodProvider>().searchFoods(query);
      }
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
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _buildFoodList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(BuildContext context) {
    return Consumer<FoodProvider>(
      builder: (context, provider, child) {
        final isSearching = _searchController.text.trim().isNotEmpty;
        final hasRecent = provider.recentFoods.isNotEmpty;
        final hasSearchResults = provider.searchResults.isNotEmpty;

        if (isSearching) {
          if (!hasSearchResults) {
            return const Center(child: Text('Ничего не найдено'));
          }
          return SearchFoodList(
            foods: provider.searchResults,
            onAdd: _addFood,
          );
        }

        if (!hasRecent) {
          return const Center(child: Text('Нет недавних продуктов'));
        }

        return ListView.builder(
          itemCount: provider.recentFoods.length,
          itemBuilder: (context, index) => _FoodItem(
            food: provider.recentFoods[index],
            onAdd: () => _addFood(provider.recentFoods[index]),
          ),
        );
      },
    );
  }

  void _addFood(Food food) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => WeightInputDialog(food: food),
    );

    if (result == null) return;

    final weight = result['weight'] as int?;
    final type = result['type'] as String?;

    if (weight == null || weight <= 0 || type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Некорректные данные')),
      );
      return;
    }

    try {
      await context
          .read<DiaryProvider>()
          .addEntry(food, widget.selectedDate, weight, type);
      await context.read<FoodProvider>().incrementRecent(food);
      if (mounted) Navigator.pop(context); // защита от unmounted
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
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
  late final TextEditingController _controller;
  String _selectedMealType = 'Перекус'; // Переносим состояние в виджет

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: AlertDialog(
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
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Обязательно';
                final n = int.tryParse(value);
                if (n == null || n <= 0) return 'Введите число > 0';
                return null;
              },
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
          ElevatedButton(
            onPressed: () {
              final input = _controller.text.trim();
              if (input.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите вес')),
                );
                return;
              }
              final value = int.tryParse(input);
              if (value == null || value <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите корректный вес (> 0)')),
                );
                return;
              }
              Navigator.pop(context, {
                'weight': value,
                'type': _selectedMealType,
              });
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    ));
  }
}

class _FoodItem extends StatelessWidget {
  final Food food;
  final VoidCallback onAdd;

  const _FoodItem({required this.food, required this.onAdd});

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
        subtitle: Text(
          food.kcalPerHundred != null
              ? '${food.kcalPerHundred} ккал/100г'
              : '${food.weight}г • ${food.kcalTotal} ккал',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green),
          onPressed: onAdd,
        ),
      ),
    );
  }
}
