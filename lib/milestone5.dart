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
    Path path = Path(); // Eliminamos 'final' para permitir la reasignación
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
      _drawMeasurementGuides(canvas, wall);
    }

    if (currentWall != null) {
      _drawWall(canvas, currentWall!, paint);
      _drawMeasurementGuides(canvas, currentWall!);
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

  void _drawMeasurementGuides(Canvas canvas, Wall wall) {
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

    final guidePaint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const guideSeparation =
        10.0; // Separation between the wall and the measurement guide
    const guideExtension =
        5.0; // Length of the vertical lines at the ends of the measurement guide

    // Draw the measurement guide above the wall
    final topGuideY = -rect.height / 2 - guideSeparation;
    final topGuideStart = Offset(-rect.width / 2, topGuideY);
    final topGuideEnd = Offset(rect.width / 2, topGuideY);

  
    canvas.drawLine(topGuideStart, topGuideEnd, guidePaint);

    // Draw vertical lines at the start and end of the measurement guide above the wall
     _drawVerticalLineWithArrow(canvas, topGuideStart.dx, topGuideY, guideExtension, guidePaint, isStart:true);
     _drawVerticalLineWithArrow(canvas, topGuideEnd.dx, topGuideY, guideExtension, guidePaint, isStart:false);


    // Draw the measurement guide below the wall
    final bottomGuideY = rect.height / 2 + guideSeparation;
    final bottomGuideStart = Offset(-rect.width / 2, bottomGuideY);
    final bottomGuideEnd = Offset(rect.width / 2, bottomGuideY);
    canvas.drawLine(bottomGuideStart, bottomGuideEnd, guidePaint);

    // Draw vertical lines at the start and end of the measurement guide below the wall
     _drawVerticalLineWithArrow(canvas, bottomGuideStart.dx, bottomGuideY, guideExtension, guidePaint, isStart:true);
     _drawVerticalLineWithArrow(canvas, bottomGuideEnd.dx, bottomGuideY, guideExtension, guidePaint, isStart:false);


   
    // Prepare the text painter for the measurement value
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${wallLength.toStringAsFixed(1)}px',
        style: const TextStyle(
          color: Colors.blueGrey,
          fontSize: 12,
          backgroundColor: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Calculate the vertical center of the guideline
    final textHeight = textPainter.height;

    // Determine if the angle is beyond 90 degrees or -90 degrees
    final isUpsideDown = angle > math.pi / 2 || angle < -math.pi / 2;

    // Draw the measurement value above the wall
    final topTextOffset = Offset(
      -textPainter.width / 2, // Horizontally center the text
      topGuideY - (textHeight / 2), // Vertically center the text
    );
    if (isUpsideDown) {
      canvas.save();
      canvas.translate(topTextOffset.dx + textPainter.width / 2,
          topTextOffset.dy + textHeight / 2);
      canvas.rotate(math.pi);
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textHeight / 2));
      canvas.restore();
    } else {
      textPainter.paint(canvas, topTextOffset);
    }

    // Draw the measurement value below the wall
    final bottomTextOffset = Offset(
      -textPainter.width / 2, // Horizontally center the text
      bottomGuideY - (textHeight / 2), // Vertically center the text
    );
    if (isUpsideDown) {
      canvas.save();
      canvas.translate(bottomTextOffset.dx + textPainter.width / 2,
          bottomTextOffset.dy + textHeight / 2);
      canvas.rotate(math.pi);
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textHeight / 2));
      canvas.restore();
    } else {
      textPainter.paint(canvas, bottomTextOffset);
    }

    canvas.restore();
  }

  void _drawVerticalLineWithArrow(Canvas canvas, double x, double y, double arrowSize, Paint paint, {required bool isStart}) {
  // Draw the vertical line
  canvas.drawLine(Offset(x, y - arrowSize), Offset(x, y + arrowSize), paint);

  // Draw the arrowhead
  if (isStart) {
    // Arrow pointing to the left
    canvas.drawLine(Offset(x, y), Offset(x + arrowSize, y - arrowSize), paint);
    canvas.drawLine(Offset(x, y), Offset(x + arrowSize, y + arrowSize), paint);
  } else {
    // Arrow pointing to the right
    canvas.drawLine(Offset(x - arrowSize, y - arrowSize), Offset(x, y), paint);
    canvas.drawLine(Offset(x - arrowSize, y + arrowSize), Offset(x, y), paint);
  }
}

  @override
  bool shouldRepaint(covariant WallPainter oldDelegate) {
    return oldDelegate.walls != walls || oldDelegate.currentWall != currentWall;
  }
}

// Capa de fondo con grid
class BackgroundGrid extends StatelessWidget {
  const BackgroundGrid({super.key});

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
    
    _drawLeftMargin(canvas, size);
    _drawGrid(canvas, size);

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