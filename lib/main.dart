import 'package:floorplan_3d/milestones/combinewalls.dart';
import 'package:floorplan_3d/milestones/test1.dart';
import 'package:flutter/material.dart';
import 'milestones/milestone1.dart';
import 'milestones/milestone2.dart';
import 'milestones/musicplayer.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Milestone Menu',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Milestone Menu')),
      body: ListView(
        children: [
          _buildMenuItem(context, 'Test', CombineWallTestApp()),
          _buildMenuItem(context, 'Milestone 0', CombineWallsApp()),
          _buildMenuItem(context, 'Milestone 1', FloorplanApp_M1()),
          _buildMenuItem(context, 'Milestone 2', TimerApp()),
          _buildMenuItem(context, 'Milestone 2', MusicPlayerApp()),
         ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, Widget screen) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
