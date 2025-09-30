import 'package:flutter/material.dart';
import '../models.dart';

class AddEntryDialog extends StatefulWidget {
  final Food food;

  const AddEntryDialog({super.key, required this.food});

  @override
  _AddEntryDialogState createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.cancel, size: 32),
              ),
              TextButton(
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
                      const SnackBar(
                          content: Text('Введите корректный вес (> 0)')),
                    );
                    return;
                  }
                  Navigator.pop(context, {
                    'weight': value,
                    'type': _selectedMealType,
                  });
                },
                child: const Icon(
                  Icons.add_rounded,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
