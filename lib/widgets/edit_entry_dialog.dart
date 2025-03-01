import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models.dart';

class EditEntryDialog extends StatefulWidget {
  final DiaryEntry entry;

  const EditEntryDialog({super.key, required this.entry});

  @override
  _EditEntryDialogState createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends State<EditEntryDialog> {
  late TextEditingController _controller;
  late String _selectedMealType;
  final List<String> _mealTypes = ['Завтрак', 'Обед', 'Ужин', 'Перекус'];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry.weight.toString());
    _selectedMealType = widget.entry.type;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Изменить ${widget.entry.food.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: widget.entry.food.weight == null
                  ? 'Вес (г/мл)'
                  : 'Количество',
              suffixText: widget.entry.food.weight == null ? 'г/мл' : 'шт.',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedMealType,
            decoration: const InputDecoration(
              labelText: 'Тип приёма пищи',
              border: OutlineInputBorder(),
            ),
            items: _mealTypes
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
          onPressed: () async {
            await context.read<DiaryProvider>().deleteEntry(widget.entry);
            Navigator.pop(context);
          },
          child: const Text('Удалить', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            final newWeight = int.tryParse(_controller.text) ?? 0;
            if (newWeight > 0) {
              context.read<DiaryProvider>().updateEntry(
                    widget.entry,
                    newWeight,
                    _selectedMealType, // Передаем новый тип
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
