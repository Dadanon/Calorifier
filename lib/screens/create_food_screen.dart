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
              title: const Text('Создать'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveFood,
                ),
              ],
            ),
            body: SingleChildScrollView(
                child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Название'),
                        validator: (value) =>
                            value!.isEmpty ? 'Введите имя продукта' : null,
                      ),
                      SwitchListTile(
                        title: const Text('Порция'),
                        value: _isPortionBased,
                        onChanged: (value) =>
                            setState(() => _isPortionBased = value),
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
                              validator: (value) => value!.isEmpty
                                  ? 'Введите вес продукта'
                                  : null,
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
              ),
              EditFoodList()
            ]))));
  }

  void _saveFood() async {
    if (!_formKey.currentState!.validate()) return;

    final food = Food(
      id: 0,
      name: _nameController.text,
      weight: _isPortionBased ? null : int.parse(_weightController.text),
      kcalPerHundred: _isPortionBased ? int.parse(_kcalController.text) : null,
      kcalTotal: _isPortionBased ? null : int.parse(_kcalController.text),
    );

    try {
      await context.read<FoodProvider>().addFood(food);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Продукт с названием ${food.name} уже существует')),
      );
    }
  }
}
