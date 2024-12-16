import 'package:flutter/material.dart';
import 'drawing_screen.dart';
import 'viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Floor Plan 3D')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DrawingScreen()),
                );
              },
              child: Text('Start Drawing'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewerScreen()),
                );
              },
              child: Text('View in 3D'),
            ),
          ],
        ),
      ),
    );
  }
}
