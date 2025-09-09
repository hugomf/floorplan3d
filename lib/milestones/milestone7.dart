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
  Wall? selectedWall; // Track the selected wall
  Offset? dragStartPoint; // Track the start point of the drag
  bool isResizingLeft = false; // Track if the left handler is being dragged
  bool isResizingRight = false; // Track if the right handler is being dragged

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Wall Drawing Tool')),
      body: SafeArea(
        child: RepaintBoundary(
          child: Stack(
            children: [
              // Layer 1: Background grid
              const BackgroundGrid(),

              // Layer 2: Diagonal patterns (only shown inside walls)
              for (var wall in walls)
                ClipPath(
                  clipper: WallClipper(wall),
                  child: const DiagonalPattern(),
                ),

              // Layer 3: Diagonal pattern for the current wall (in real-time)
              if (startPoint != null && endPoint != null)
                ClipPath(
                  clipper: WallClipper(Wall(startPoint!, endPoint!)),
                  child: const DiagonalPattern(),
                ),

              // Layer 4: Detector of gestures for drawing, moving, and resizing walls
              GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: WallPainter(
                    walls: walls,
                    currentWall: _getCurrentWall(),
                    selectedWall: selectedWall,
                    isResizingLeft: isResizingLeft,
                    isResizingRight: isResizingRight,
                  ),
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
    final tapPosition = details.localPosition;

    if (selectedWall != null) {
      // Check if the user clicked on the left or right handler
      final leftHandlerPosition = _getHandlerPosition(selectedWall!, isLeft: true);
      final rightHandlerPosition = _getHandlerPosition(selectedWall!, isLeft: false);

      if ((tapPosition - leftHandlerPosition).distance < 10) {
        // Clicked the left handler
        setState(() {
          isResizingLeft = true;
          dragStartPoint = tapPosition;
        });
        return;
      } else if ((tapPosition - rightHandlerPosition).distance < 10) {
        // Clicked the right handler
        setState(() {
          isResizingRight = true;
          dragStartPoint = tapPosition;
        });
        return;
      }
    }

    // Check if the user clicked inside a wall
    for (var wall in walls) {
      if (_isPointOnWall(tapPosition, wall)) {
        setState(() {
          selectedWall = wall; // Select the wall
          dragStartPoint = tapPosition; // Store the drag start point
        });
        return;
      }
    }

    // If no wall is clicked, start drawing a new wall
    setState(() {
      startPoint = tapPosition;
      endPoint = tapPosition;
      selectedWall = null; // Deselect any selected wall
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final dragUpdatePosition = details.localPosition;

    if (selectedWall != null) {
      if (isResizingLeft) {
        // Resize the wall from the left handler
        setState(() {
          selectedWall!.start = dragUpdatePosition;
        });
      } else if (isResizingRight) {
        // Resize the wall from the right handler
        setState(() {
          selectedWall!.end = dragUpdatePosition;
        });
      } else if (dragStartPoint != null) {
        // Move the selected wall
        final dx = dragUpdatePosition.dx - dragStartPoint!.dx;
        final dy = dragUpdatePosition.dy - dragStartPoint!.dy;

        setState(() {
          selectedWall!.start = Offset(selectedWall!.start.dx + dx, selectedWall!.start.dy + dy);
          selectedWall!.end = Offset(selectedWall!.end.dx + dx, selectedWall!.end.dy + dy);
          dragStartPoint = dragUpdatePosition;
        });
      }
    } else if (startPoint != null && endPoint != null) {
      // Update the end point of the wall being drawn
      setState(() {
        endPoint = dragUpdatePosition;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (startPoint != null && endPoint != null) {
      // Add the new wall to the list
      final distance = (endPoint! - startPoint!).distance;
      if (distance > 5.0) {
        setState(() {
          walls.add(Wall(startPoint!, endPoint!));
        });
      }
      startPoint = null;
      endPoint = null;
    }

    // Reset the drag state
    setState(() {
      dragStartPoint = null;
      isResizingLeft = false;
      isResizingRight = false;
    });
  }

  bool _isPointOnWall(Offset point, Wall wall) {
    // Simple distance check to see if the point is near the wall
    final dx = wall.end.dx - wall.start.dx;
    final dy = wall.end.dy - wall.start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final unitDx = dx / length;
    final unitDy = dy / length;

    final projection = (point.dx - wall.start.dx) * unitDx + (point.dy - wall.start.dy) * unitDy;
    if (projection < 0 || projection > length) return false;

    final perpendicularDistance = (point.dx - wall.start.dx) * unitDy - (point.dy - wall.start.dy) * unitDx;
    return perpendicularDistance.abs() < 10.0; // Tolerance for selection
  }

  Offset _getHandlerPosition(Wall wall, {required bool isLeft}) {
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

    final handlerOffset = isLeft ? Offset(-rect.width / 2, 0) : Offset(rect.width / 2, 0);

    final matrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(angle);

    return MatrixUtils.transformPoint(matrix, handlerOffset);
  }

  Wall? _getCurrentWall() {
    if (startPoint != null && endPoint != null) {
      return Wall(startPoint!, endPoint!);
    }
    return null;
  }
}

class Wall {
  Offset start;
  Offset end;

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

    // Transform the path
    final matrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(angle);
    path = path.transform(matrix.storage);

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
  final Wall? selectedWall;
  final bool isResizingLeft;
  final bool isResizingRight;

  WallPainter({
    required this.walls,
    this.currentWall,
    this.selectedWall,
    this.isResizingLeft = false,
    this.isResizingRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var wall in walls) {
      _drawWall(canvas, wall, paint, wall == selectedWall);
      _drawMeasurementGuides(canvas, wall);
    }

    if (currentWall != null) {
      _drawWall(canvas, currentWall!, paint, false);
      _drawMeasurementGuides(canvas, currentWall!);
    }
  }

  void _drawWall(Canvas canvas, Wall wall, Paint paint, bool isSelected) {
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

    // Change color if the wall is selected
    if (isSelected) {
      final selectedPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawRect(rect, selectedPaint);
    } else {
      canvas.drawRect(rect, paint);
    }

    // Draw handlers (small filled squares) at the edges if the wall is selected
    if (isSelected) {
      final handlerPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      const handlerSize = 5.0; // Size of the handler squares

      // Draw handler at the start of the wall
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(-rect.width / 2, 0),
          width: handlerSize,
          height: handlerSize,
        ),
        handlerPaint,
      );

      // Draw handler at the end of the wall
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(rect.width / 2, 0),
          width: handlerSize,
          height: handlerSize,
        ),
        handlerPaint,
      );
    }

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

    const guideSeparation = 10.0;
    const guideExtension = 5.0;

    // Draw the measurement guide above the wall
    final topGuideY = -rect.height / 2 - guideSeparation;
    final topGuideStart = Offset(-rect.width / 2, topGuideY);
    final topGuideEnd = Offset(rect.width / 2, topGuideY);

    canvas.drawLine(topGuideStart, topGuideEnd, guidePaint);

    // Draw vertical lines at the start and end of the measurement guide above the wall
    _drawVerticalLineWithArrow(canvas, topGuideStart.dx, topGuideY, guideExtension, guidePaint, isStart: true);
    _drawVerticalLineWithArrow(canvas, topGuideEnd.dx, topGuideY, guideExtension, guidePaint, isStart: false);

    // Draw the measurement guide below the wall
    final bottomGuideY = rect.height / 2 + guideSeparation;
    final bottomGuideStart = Offset(-rect.width / 2, bottomGuideY);
    final bottomGuideEnd = Offset(rect.width / 2, bottomGuideY);
    canvas.drawLine(bottomGuideStart, bottomGuideEnd, guidePaint);

    // Draw vertical lines at the start and end of the measurement guide below the wall
    _drawVerticalLineWithArrow(canvas, bottomGuideStart.dx, bottomGuideY, guideExtension, guidePaint, isStart: true);
    _drawVerticalLineWithArrow(canvas, bottomGuideEnd.dx, bottomGuideY, guideExtension, guidePaint, isStart: false);

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

    // Determine if the wall is upside down (angle > 90° or < -90°)
    final isUpsideDown = angle > math.pi / 2 || angle < -math.pi / 2;

    // Draw the measurement value above the wall
    final topTextOffset = Offset(
      -textPainter.width / 2,
      topGuideY - (textPainter.height / 2),
    );

    // Draw the measurement value below the wall
    final bottomTextOffset = Offset(
      -textPainter.width / 2,
      bottomGuideY - (textPainter.height / 2),
    );

    // Draw the text above the wall
    canvas.save();
    canvas.translate(topTextOffset.dx + textPainter.width / 2, topTextOffset.dy + textPainter.height / 2);
    if (isUpsideDown) {
      canvas.rotate(math.pi); // Flip the text if upside down
    }
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();

    // Draw the text below the wall
    canvas.save();
    canvas.translate(bottomTextOffset.dx + textPainter.width / 2, bottomTextOffset.dy + textPainter.height / 2);
    if (isUpsideDown) {
      canvas.rotate(math.pi); // Flip the text if upside down
    }
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();

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
    return oldDelegate.walls != walls ||
        oldDelegate.currentWall != currentWall ||
        oldDelegate.selectedWall != selectedWall ||
        oldDelegate.isResizingLeft != isResizingLeft ||
        oldDelegate.isResizingRight != isResizingRight;
  }
}

// Background grid layer
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
    const marginColor = Colors.red;
    const marginWidth = 2.0;
    const marginOffset = 40.0;

    final paint = Paint()
      ..color = marginColor.withOpacity(0.4)
      ..strokeWidth = marginWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(marginOffset, 0),
      Offset(marginOffset, size.height),
      paint,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    const gridColor = Color(0xFFADD8E6);
    const gridSpacing = 20.0;
    final paint = Paint()
      ..color = gridColor.withOpacity(0.3)
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

// Diagonal pattern layer
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

    // Draw diagonals at 45 degrees
    for (double i = -size.height; i < size.width; i += 6) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}