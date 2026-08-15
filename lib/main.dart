import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('books');

  runApp(const PersonalLibraryManagementSystem());
}

class PersonalLibraryManagementSystem extends StatelessWidget {
  const PersonalLibraryManagementSystem({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Library Management System',
      home: const HomeScreen(),
    );
  }
}