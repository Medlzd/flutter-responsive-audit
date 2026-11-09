import 'package:flutter/material.dart';

import 'screens/shell.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 2.0,
        child: child!,
      ),
      home: const Shell(),
    );
  }
}
