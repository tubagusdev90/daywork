
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

class TukangPayApp extends StatelessWidget {
  const TukangPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Text(
            'daywork Berhasil Dibuka',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
