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
        child: RepaintBoundary(
          child: Stack(
            children: [
              // Capa 1: Fondo con grid
              BackgroundGrid(),

              // Capa 2: Patrones diagonales (solo se muestra dentro de los muros)
              for (var wall in walls)
                ClipPath(
                  clipper: WallClipper(wall),
                  child: DiagonalPattern(),
                ),

              // Capa 3: Patrón de diagonales para el muro actual (en tiempo real)
              if (startPoint != null && endPoint != null)
                ClipPath(
                  clipper: WallClipper(Wall(startPoint!, endPoint!)),
                  child: DiagonalPattern(),
                ),

              // Capa 4: Detector de gestos para dibujar muros
              GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: WallPainter(walls: walls, currentWall: _getCurrentWall()),
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
      ),
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

class WallClipper extends CustomClipper<Path> {
  final Wall wall;

  WallClipper(this.wall);

  @override
  Path getClip(Size size) {
    Path path = Path(); 
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

    path.addRect(rect);

    // Transformación de la matriz
    final matrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(angle);
    path = path.transform(matrix.storage); // Reasignamos 'path' con la transformación

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
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

// Capa de fondo con grid
class BackgroundGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(),
      size: Size.infinite,
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {

    _drawGrid(canvas, size);
    _drawLeftMargin(canvas, size);
   
  }

   void _drawLeftMargin(Canvas canvas, Size size) {
    const marginColor = Colors.red; // Red color for the line
    const marginWidth = 2.0; // Thickness of the line
    const marginOffset = 40.0; // Distance from the left edge

    final paint = Paint()
      ..color = marginColor.withOpacity(0.4)
      ..strokeWidth = marginWidth
      ..style = PaintingStyle.stroke;

    // Draw a vertical line
    canvas.drawLine(
      Offset(marginOffset, 0), // Start point (top)
      Offset(marginOffset, size.height), // End point (bottom)
      paint,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    const gridColor = Color(0xFFADD8E6); // Light blue color
    const gridSpacing = 20.0; // Spacing between grid lines
    final paint = Paint()
      ..color = gridColor.withOpacity(0.3) // Reduce opacity to make it lighter
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Capa de patrones diagonales
class DiagonalPattern extends StatelessWidget {
  const DiagonalPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DiagonalPatternPainter(),
      size: Size.infinite,
    );
  }
}

class DiagonalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 1.0;

    // Dibuja diagonales a 45 grados
    for (double i = -size.height; i < size.width; i += 6) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}