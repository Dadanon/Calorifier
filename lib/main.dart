import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:calorifier/database_helper.dart';
import 'package:calorifier/providers.dart';
import 'package:calorifier/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ограничение ориентации
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final database = await DatabaseHelper.init();
  final foodProvider = FoodProvider(database);
  await foodProvider.loadFoods();
  await initializeDateFormatting('ru_RU', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => foodProvider),
        ChangeNotifierProvider(create: (_) => DiaryProvider(database)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ru', 'RU'),
      title: 'Calorifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
