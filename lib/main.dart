import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(FloorPlanApp());
}

class FloorPlanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floor Plan 3D',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
