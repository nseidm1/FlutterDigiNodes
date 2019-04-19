import 'package:diginodes/ui/home_screen.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digi Nodes',
      theme: ThemeData(
        primaryColor: const Color(0xFF008577),
        primaryColorDark: const Color(0xFF00574B),
        accentColor: const Color(0xFFD81B60),
      ),
      home: HomeScreen(),
    );
  }
}
