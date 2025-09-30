import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models.dart';
import '../widgets/add_entry_dialog.dart';
import '../widgets/food_item.dart';
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
        title: const Text('Добавить запись'),
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
          itemBuilder: (context, index) => FoodItem(
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
      builder: (context) => AddEntryDialog(food: food),
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
