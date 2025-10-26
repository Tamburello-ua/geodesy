import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geodesy/screen/combo_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ComboScreen(), debugShowCheckedModeBanner: false);
  }
}
