import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(
    MaterialApp(
      home: const WallDrawingTool(),
      debugShowCheckedModeBanner: false, // Optional: Remove debug banner
    ),
  );
}

class WallDrawingTool extends StatefulWidget {
  const WallDrawingTool({super.key});

  @override
  WallDrawingToolState createState() => WallDrawingToolState();
}

class WallDrawingToolState extends State<WallDrawingTool> {
  List<Wall> walls = [];
  Offset? startPoint;
  Offset? endPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color
      appBar: AppBar(title: const Text('Wall Drawing Tool')),
      body: SafeArea(
        child: Stack(
          children: [
            // Background Layer: Grid
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
            // Foreground Layer: Wall Drawing
            Positioned.fill(
              child: RepaintBoundary(
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: WallPainter(walls: walls, currentWall: _getCurrentWall()),
                    child: Container(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Removed the drawer and floating action button
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      startPoint = details.localPosition;
      endPoint = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      endPoint = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (startPoint != null && endPoint != null) {
      final distance = (endPoint! - startPoint!).distance;
      if (distance > 5.0) {
        setState(() {
          walls.add(Wall(startPoint!, endPoint!));
        });
      }
      startPoint = null;
      endPoint = null;
    }
  }

  Wall? _getCurrentWall() {
    if (startPoint != null && endPoint != null) {
      return Wall(startPoint!, endPoint!);
    }
    return null;
  }
}

class Wall {
  final Offset start;
  final Offset end;

  Wall(this.start, this.end);
}

class WallPainter extends CustomPainter {
  final List<Wall> walls;
  final Wall? currentWall;

  WallPainter({required this.walls, this.currentWall});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var wall in walls) {
      _drawWall(canvas, wall, paint);
    }

    if (currentWall != null) {
      _drawWall(canvas, currentWall!, paint);
    }
  }

  void _drawWall(Canvas canvas, Wall wall, Paint paint) {
    final dx = wall.end.dx - wall.start.dx;
    final dy = wall.end.dy - wall.start.dy;
    final angle = math.atan2(dy, dx);

    final wallLength = math.sqrt(dx * dx + dy * dy);
    final wallHeight = 10.0;

    final center = Offset(
      (wall.start.dx + wall.end.dx) / 2,
      (wall.start.dy + wall.end.dy) / 2,
    );

    final rect = Rect.fromLTWH(
      -wallLength / 2,
      -wallHeight / 2,
      wallLength,
      wallHeight,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WallPainter oldDelegate) {
    return oldDelegate.walls != walls || oldDelegate.currentWall != currentWall;
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 20.0; // Size of each grid square

    // Draw vertical lines
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}