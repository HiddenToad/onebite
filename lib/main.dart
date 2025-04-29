import 'package:flutter/material.dart';
import 'package:onebite/libraryscn.dart';

void main() {
  runApp(const OnebiteApp());
}

class OnebiteApp extends StatelessWidget {
  const OnebiteApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // This is the theme of the application.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan.shade200,
          brightness: Brightness.dark,
        ),
      ),
      home: const TasklistLibrary(),
    );
  }
}
