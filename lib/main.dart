import 'package:card_master/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      home: HomeScreen(),
      theme: ThemeData.from(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green[700]!)),
    ),
  );
}
