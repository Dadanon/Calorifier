import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models.dart';
import '../widgets/edit_entry_dialog.dart';
import '../widgets/meal_type_badge.dart';
import 'create_food_screen.dart';
import 'add_food_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Форматтер для заголовка календаря
  static String _formatMonthYear(DateTime date, String locale) {
    final monthFormat = DateFormat('MMMM', locale);
    final yearFormat = DateFormat('yyyy', locale);
    final month = monthFormat.format(date);
    final year = yearFormat.format(date);
    return '${month[0].toUpperCase()}${month.substring(1)} $year';
  }

  // Обновление выбранной даты
  void _updateDate(DateTime newDate) {
    setState(() {
      _selectedDay = newDate;
      _focusedDay = newDate;
    });
    context.read<DiaryProvider>().loadEntries(newDate);
  }

  // Обработка горизонтального свайпа
  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return; // Игнорируем медленные свайпы

    final offset = velocity > 0 ? -1 : 1; // Свайп вправо → предыдущий день
    _updateDate(_selectedDay.add(Duration(days: offset)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              DateFormat.yMMMMd('ru_RU').format(_selectedDay),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        body: Column(
          children: [
            _buildCalendar(context),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: _onHorizontalDragEnd,
                child: Container(
                  color: Colors.transparent,
                  child: _buildEntryList(context),
                ),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // Виджет календаря
  Widget _buildCalendar(BuildContext context) {
    return TableCalendar<DateTime>(
      calendarStyle: const CalendarStyle(),
      availableGestures: AvailableGestures.horizontalSwipe,
      headerStyle: HeaderStyle(
        leftChevronIcon: const SizedBox.shrink(),
        rightChevronIcon: const SizedBox.shrink(),
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        titleTextFormatter: (date, locale) =>
            _formatMonthYear(date, locale), // ✅ Корректно добавлено
      ),
      locale: 'ru_RU',
      calendarFormat: CalendarFormat.twoWeeks,
      firstDay: DateTime(2000),
      lastDay: DateTime(2050),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        _updateDate(selectedDay);
      },
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
      },
      eventLoader: (day) {
        final entries = context.read<DiaryProvider>().entries;
        return entries.any((e) => isSameDay(e.date, day)) ? [day] : [];
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return null;
          return Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }

  // Список записей
  Widget _buildEntryList(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, provider, child) {
        if (provider.entries.isEmpty) {
          return Center(
            child: Text(
              'Нет записей за ${DateFormat.yMMMMd('ru_RU').format(_selectedDay)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.separated(
          separatorBuilder: (context, index) => const Divider(height: 0),
          itemCount: provider.entries.length,
          itemBuilder: (context, index) {
            final entry = provider.entries[index];
            return ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    entry.food.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )
                ],
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.food.weight == null
                          ? '${entry.weight}г • ${entry.kcalTotal}ккал'
                          : '${entry.weight * entry.food.weight!}г • ${entry.kcalTotal}ккал',
                    ),
                  ),
                  mealTypeBadge(entry.type),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(context, entry),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Нижняя панель с кнопками и итогами
  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(
            icon: Icons.edit,
            backgroundColor: const Color.fromARGB(255, 92, 107, 192),
            onPressed: () => _navigateToCreateFood(context),
          ),
          Text(
            'Всего: ${context.watch<DiaryProvider>().totalKcal} ккал',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          _buildCircleButton(
            icon: Icons.add,
            backgroundColor: const Color.fromARGB(255, 92, 107, 192),
            onPressed: () => _navigateToAddFood(context),
          ),
        ],
      ),
    );
  }

  // Круглая кнопка
  Widget _buildCircleButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
        backgroundColor: backgroundColor,
        elevation: 6,
      ),
      child: Icon(icon, size: 24, color: Colors.white),
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
        builder: (context) => AddFoodScreen(selectedDate: _selectedDay),
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
