import 'package:calorifier/widgets/edit_food_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models.dart';

class CreateFoodScreen extends StatefulWidget {
  const CreateFoodScreen({super.key});

  @override
  _CreateFoodScreenState createState() => _CreateFoodScreenState();
}

class _CreateFoodScreenState extends State<CreateFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _kcalController = TextEditingController();
  bool _isPortionBased = true;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _kcalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Создать продукт'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveFood,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildForm(context),
                const SizedBox(height: 24),
                const EditFoodList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Форма создания продукта
  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Название продукта'),
            validator: (value) =>
                value?.trim().isEmpty ?? true ? 'Введите название' : null,
          ),
          SwitchListTile(
            title: const Text('Режим "на 100г"'),
            subtitle: Text(_isPortionBased
                ? 'Укажите количество ккал на 100г'
                : 'Укажите вес и общую калорийность'),
            value: _isPortionBased,
            onChanged: (value) => setState(() => _isPortionBased = value),
          ),
          ..._buildKcalFields(),
        ],
      ),
    );
  }

  // Поля ввода калорийности (зависят от режима)
  List<Widget> _buildKcalFields() {
    if (_isPortionBased) {
      return [
        TextFormField(
          controller: _kcalController,
          decoration: const InputDecoration(
            labelText: 'Ккал на 100г',
            suffixText: 'ккал',
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value?.trim().isEmpty ?? true ? 'Введите калорийность' : null,
        ),
      ];
    } else {
      return [
        TextFormField(
          controller: _weightController,
          decoration: const InputDecoration(
            labelText: 'Вес/объём порции',
            suffixText: 'г/мл',
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value?.trim().isEmpty ?? true ? 'Введите вес' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _kcalController,
          decoration: const InputDecoration(
            labelText: 'Общая калорийность порции',
            suffixText: 'ккал',
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value?.trim().isEmpty ?? true ? 'Введите калорийность' : null,
        ),
      ];
    }
  }

  // Сохранение продукта
  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final name = _nameController.text.trim();

      // Парсим числа с проверкой
      final kcal = _parseNumber(_kcalController.text);
      if (kcal == null) {
        _showError('Некорректное значение калорийности');
        return;
      }

      int? weight;
      if (!_isPortionBased) {
        weight = _parseNumber(_weightController.text);
        if (weight == null) {
          _showError('Некорректное значение веса');
          return;
        }
      }

      final food = Food(
        id: 0, // ID будет присвоен на сервере/в БД
        name: name,
        weight: weight,
        kcalPerHundred: _isPortionBased ? kcal : null,
        kcalTotal: _isPortionBased ? null : kcal,
      );

      await context.read<FoodProvider>().addFood(food);
      Navigator.pop(context); // Закрываем экран

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Продукт успешно добавлен')),
        );
      }
    } catch (e) {
      _showError(
          'Продукт с названием "${_nameController.text}" уже существует');
    }
  }

  // Вспомогательный метод для парсинга чисел
  int? _parseNumber(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      return int.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  // Показ ошибки через SnackBar
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
