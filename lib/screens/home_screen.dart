import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models.dart';
import '../widgets/edit_entry_dialog.dart';
import 'create_food_screen.dart';
import 'add_food_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadEntries(_selectedDay!);
    });
  }

  Widget _mealTypeBadge(String type) {
    Color bgColor;
    switch (type) {
      case 'Завтрак':
        bgColor = Colors.green;
      case 'Обед':
        bgColor = Colors.orange;
      case 'Ужин':
        bgColor = Colors.blue;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      width: 66,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMMd('ru_RU').format(_focusedDay)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToCreateFood(context),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ru_RU',
            calendarFormat: CalendarFormat.twoWeeks,
            headerStyle: HeaderStyle(formatButtonVisible: false),
            firstDay: DateTime(2000),
            lastDay: DateTime(2050),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              context.read<DiaryProvider>().loadEntries(selectedDay);
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            eventLoader: (day) {
              final entries = context.read<DiaryProvider>().entries;
              return entries.any((e) => isSameDay(e.date, day)) ? [day] : [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      width: 8,
                      height: 8,
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          Expanded(
            child: Consumer<DiaryProvider>(
              builder: (context, provider, child) => ListView.separated(
                separatorBuilder: (context, index) => Divider(
                  height: 0,
                ),
                itemCount: provider.entries.length,
                itemBuilder: (context, index) {
                  final entry = provider.entries[index];
                  return ListTile(
                      title: Text(entry.food.name),
                      subtitle: Row(spacing: 8, children: [
                        Expanded(
                            child: Text(
                          entry.food.weight == null
                              ? '${entry.weight}г • ${entry.kcalTotal}ккал'
                              : '${entry.weight * entry.food.weight!}г • ${entry.kcalTotal}ккал',
                        )),
                        _mealTypeBadge(entry.type),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(context, entry),
                        )
                      ]));
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Всего: ${context.watch<DiaryProvider>().totalKcal} ккал',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddFood(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateFood(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateFoodScreen()),
    );
  }

  void _navigateToAddFood(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFoodScreen(selectedDate: _selectedDay!),
      ),
    );
  }

  void _showEditDialog(BuildContext context, DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => EditEntryDialog(entry: entry),
    );
  }
}
