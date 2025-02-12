import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models.dart';

class EditFoodDialog extends StatefulWidget {
  final Food food;

  const EditFoodDialog({super.key, required this.food});

  @override
  _EditFoodDialogState createState() => _EditFoodDialogState();
}

class _EditFoodDialogState extends State<EditFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _kcalController = TextEditingController();
  late bool
      _isPortionBased; // Салат весовой - это portionBased, а Adrenaline 0.33 - это НЕ portionBased

  @override
  void initState() {
    /* 
    Сразу объясним:
    Весовой салат (_isPortionBased = true): weight = null, kcalPerHundred != null, kcalTotal = null
    Adrenaline Rush 0.33 (_isPortionBased = false): weight != null, kcalPerHundred = null, kcalTotal != null
     */
    super.initState();
    _isPortionBased = widget.food.weight == null ? true : false;
    _nameController.text = widget.food.name;

    _weightController.text =
        _isPortionBased ? '' : widget.food.weight.toString();

    _kcalController.text = _isPortionBased
        ? widget.food.kcalPerHundred.toString()
        : widget.food.kcalTotal.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _kcalController.dispose();
    super.dispose();
  }

  void _updateFood() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedFood = Food(
      id: widget.food.id,
      name: _nameController.text,
      weight: _weightController.text == ''
          ? null
          : int.parse(_weightController.text),
      kcalPerHundred: _isPortionBased ? int.parse(_kcalController.text) : null,
      kcalTotal: _isPortionBased ? null : int.parse(_kcalController.text),
    );

    try {
      await context.read<FoodProvider>().updateFood(updatedFood);
      await context.read<DiaryProvider>().updateEntriesForFood(updatedFood);
      await context.read<FoodProvider>().loadRecentFoods();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка изменения продукта')),
      );
    }
  }

  void _deleteFood() async {
    try {
      await context.read<FoodProvider>().deleteFood(widget.food.id);
      await context
          .read<DiaryProvider>()
          .reloadEntriesOnFoodDelete(widget.food.id);
      await context.read<FoodProvider>().loadRecentFoods();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка удаления продукта')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название'),
              validator: (value) =>
                  value!.isEmpty ? 'Введите имя продукта' : null,
            ),
            if (_isPortionBased)
              TextFormField(
                controller: _kcalController,
                decoration: const InputDecoration(
                  labelText: 'Ккал на 100г/мл',
                  suffixText: 'ккал',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Введите значение' : null,
              )
            else
              Column(
                children: [
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Вес/объём',
                      suffixText: 'г/мл',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Введите вес продукта' : null,
                  ),
                  TextFormField(
                    controller: _kcalController,
                    decoration: const InputDecoration(
                      labelText: 'Общая калорийность',
                      suffixText: 'ккал',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Введите значение' : null,
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => _deleteFood(), child: const Text('Удалить')),
        TextButton(
            onPressed: () => _updateFood(), child: const Text('Изменить')),
      ],
    );
  }
}
