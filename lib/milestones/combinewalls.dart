import 'package:flutter/material.dart';


class CombineWallsApp extends StatelessWidget {
  const CombineWallsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Combine Walls with Path.combine'),
        ),
        body: const Center(
          child: WallPainterWidget(),
        ),
      ),
    );
  }
}

class WallPainterWidget extends StatelessWidget {
  const WallPainterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(400, 400), // Canvas size
      painter: WallPainter(),
    );
  }
}

class WallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Define the paint for the wall outline
    final Paint wallPaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2; // Outline thickness

    // Define the wall paths
    final Path verticalWall = Path()
      ..addRect(Rect.fromLTWH(100, 50, 15, 200)); // Vertical wall

    final Path horizontalWall = Path()
      ..addRect(Rect.fromLTWH(100, 235, 200, 15)); // Horizontal wall

    // Combine the paths into one using Path.combine
    final Path combinedWall = Path.combine(
      PathOperation.union, // Union of the two paths
      verticalWall,
      horizontalWall,
    );

    // Draw the combined wall on the canvas
    canvas.drawPath(combinedWall, wallPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
