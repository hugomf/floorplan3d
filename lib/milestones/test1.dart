import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // For ListEquality
import 'package:uuid/uuid.dart'; // For UUID

void main() => runApp(const CombineWallTestApp());

class CombineWallTestApp extends StatelessWidget {
  const CombineWallTestApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const WallCombinerScreen(),
      );
}

/// Manages the state and logic for walls.
class WallModel {
  List<Wall> walls = [];
  int? selectedIndex;
  Offset? lastPosition;
  bool isResizing = false; // Track if a wall is being resized
  bool isResizingLeftEdge = false; // Track if the left edge is being resized

  /// Adds a wall at the given position.
  void addWall(Offset position) {
    walls = List.from(walls)..add(Wall(position));
  }

  /// Selects a wall at the given position.
  void selectWall(Offset position) {
    for (int i = walls.length - 1; i >= 0; i--) {
      final wallRect = Rect.fromLTWH(
        walls[i].position.dx,
        walls[i].position.dy,
        walls[i].width,
        Wall.height,
      );
      if (wallRect.contains(position)) {
        selectedIndex = i;
        lastPosition = position;
        return;
      }
    }
    selectedIndex = null;
    lastPosition = null;
  }

  /// Updates the position of the selected wall.
  void updateWallPosition(Offset newPosition) {
    if (selectedIndex == null || lastPosition == null) return;
    walls = List.from(walls); // Create a new list
    walls[selectedIndex!].position = Offset(
      walls[selectedIndex!].position.dx + (newPosition.dx - lastPosition!.dx),
      walls[selectedIndex!].position.dy + (newPosition.dy - lastPosition!.dy),
    );
    lastPosition = newPosition;
  }

  /// Resizes the selected wall.
  void resizeWall(Offset newPosition) {
    if (selectedIndex == null || lastPosition == null) return;

    walls = List.from(walls); // Ensure the walls list is updated immutably
    final deltaX = newPosition.dx - lastPosition!.dx;
 
    final wall = walls[selectedIndex!];

    if (isResizingLeftEdge) {
      // Adjust the left edge of the wall
      wall.width -= deltaX; // Adjust width
      wall.position = Offset(wall.position.dx + deltaX, wall.position.dy); // Update starting position
    } else {
      // Adjust the right edge of the wall
      wall.width += deltaX; // Adjust width
    }

    lastPosition = newPosition; // Update the last position for future calculations
  }
}

class WallCombinerScreen extends StatefulWidget {
  const WallCombinerScreen({super.key});

  @override
  State<WallCombinerScreen> createState() => _WallCombinerScreenState();
}

class _WallCombinerScreenState extends State<WallCombinerScreen> {
  final WallModel _wallModel = WallModel();
  bool _isAddMode = false;
  String _painterKey = const Uuid().v4(); // Initialize with a UUID
  MouseCursor _cursor = SystemMouseCursors.basic; // Default cursor

  void _updatePainterKey() {
    setState(() {
      _painterKey = const Uuid().v4(); // Generate a new UUID
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wall Combiner'),
        actions: [
          IconButton(
            icon: Icon(_isAddMode ? Icons.check : Icons.add),
            color: _isAddMode ? Colors.green : Colors.blueGrey,
            tooltip: _isAddMode ? 'Exit Add Mode' : 'Add Wall',
            onPressed: () => setState(() {
              _isAddMode = !_isAddMode;
              _wallModel.selectedIndex = null;
              _wallModel.lastPosition = null;
            }),
          ),
        ],
      ),
      body: MouseRegion(
        cursor: _cursor, // Set the cursor based on hover state
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _isAddMode
              ? (details) {
                  setState(() {
                    _wallModel.addWall(details.localPosition);
                    _updatePainterKey(); // Force rebuild
                  });
                }
              : (details) {
                  setState(() {
                    _wallModel.selectWall(details.localPosition);
                    _updatePainterKey(); // Force rebuild
                  });
                },
          onPanStart: !_isAddMode
              ? (details) {
                  final position = details.localPosition;
                  final selectedIndex = _wallModel.selectedIndex;
                  if (selectedIndex != null) {
                    final wall = _wallModel.walls[selectedIndex];
                    // Check if the user is clicking on the left or right edge
                    if (_isNearLeftEdge(position, wall)) {
                      _wallModel.isResizing = true;
                      _wallModel.isResizingLeftEdge = true;
                    } else if (_isNearRightEdge(position, wall)) {
                      _wallModel.isResizing = true;
                      _wallModel.isResizingLeftEdge = false;
                    } else {
                      _wallModel.selectWall(position);
                    }
                  } else {
                    _wallModel.selectWall(position);
                  }
                  _updatePainterKey(); // Force rebuild
                }
              : null,
          onPanUpdate: !_isAddMode
              ? (details) {
                  if (_wallModel.isResizing) {
                    setState(() {
                      _wallModel.resizeWall(details.localPosition);
                      _updatePainterKey(); // Force rebuild
                    });
                  } else {
                    setState(() {
                      _wallModel.updateWallPosition(details.localPosition);
                      _updatePainterKey(); // Force rebuild
                    });
                  }
                }
              : null,
          onPanEnd: !_isAddMode
              ? (details) {
                  setState(() {
                    _wallModel.selectedIndex = null;
                    _wallModel.lastPosition = null;
                    _wallModel.isResizing = false;
                    _wallModel.isResizingLeftEdge = false;
                    _updatePainterKey(); // Force rebuild
                  });
                }
              : null,
          onPanCancel: () {
            setState(() {
              _cursor = SystemMouseCursors.basic; // Reset cursor on cancel
            });
          },
          child: Listener(
            onPointerHover: (event) {
              final position = event.localPosition;
              final selectedIndex = _wallModel.selectedIndex;
              if (selectedIndex != null) {
                final wall = _wallModel.walls[selectedIndex];
                if (_isNearLeftEdge(position, wall) ||
                    _isNearRightEdge(position, wall)) {
                  setState(() {
                    _cursor = SystemMouseCursors
                        .resizeLeftRight; // Change cursor to resize icon
                  });
                } else {
                  setState(() {
                    _cursor = SystemMouseCursors.basic; // Reset cursor
                  });
                }
              } else {
                setState(() {
                  _cursor = SystemMouseCursors.basic; // Reset cursor
                });
              }
            },
            child: CustomPaint(
              key: ValueKey(_painterKey), // Force rebuild with new UUID
              painter: WallPainter(
                walls: _wallModel.walls,
                selectedIndex: _wallModel.selectedIndex,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }

  /// Checks if the user is clicking near the left edge of a wall.
  bool _isNearLeftEdge(Offset position, Wall wall) {
    const edgeThreshold = 15.0; // How close to the edge to consider a click
    final wallRect = Rect.fromLTWH(
      wall.position.dx,
      wall.position.dy,
      wall.width,
      Wall.height,
    );
    return position.dx >= wallRect.left - edgeThreshold &&
        position.dx <= wallRect.left + edgeThreshold;
  }

  /// Checks if the user is clicking near the right edge of a wall.
  bool _isNearRightEdge(Offset position, Wall wall) {
    const edgeThreshold = 15.0; // How close to the edge to consider a click
    final wallRect = Rect.fromLTWH(
      wall.position.dx,
      wall.position.dy,
      wall.width,
      Wall.height,
    );
    return position.dx >= wallRect.right - edgeThreshold &&
        position.dx <= wallRect.right + edgeThreshold;
  }
}

/// Represents a wall with a position and resizable width.
class Wall {
  static const double height = 15;
  Offset position;
  double width;

  Wall(this.position, {this.width = 200});
}

/// Paints the walls and grid on the canvas.
class WallPainter extends CustomPainter {
  final List<Wall> walls;
  final int? selectedIndex;

  static const _gridSpacing = 20.0;
  static const _gridAlpha = 51;
  static const double pixelsPerMeter = 100.0; // 1 meter = 100 pixels

  static final _strokePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1; // Reduced stroke width

  static final _gridPaint = Paint()
    ..color = Colors.blue.withAlpha(_gridAlpha)
    ..style = PaintingStyle.stroke;

  static final _measurementPaint = Paint()
    ..color = Colors.grey.withOpacity(0.5) // Lighter gray measurement guides
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  static final _textStyle = TextStyle(
    color: Colors.black, // Black text for better visibility
    fontSize: 12,
  );

  static final _textBackgroundPaint = Paint()
    ..color = Colors.white.withOpacity(0.8) // Semi-transparent white background
    ..style = PaintingStyle.fill;

  WallPainter({
    required this.walls,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawWalls(canvas);
  }

  /// Draws the grid on the canvas.
  void _drawGrid(Canvas canvas, Size size) {
    for (double x = 0; x < size.width; x += _gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }
    for (double y = 0; y < size.height; y += _gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }
  }

  /// Draws the walls on the canvas.
  void _drawWalls(Canvas canvas) {
    if (walls.isEmpty) return;

    // Create wall paths and detect overlaps
    final List<Path> wallPaths = walls
        .map((wall) => Path()
          ..addRect(Rect.fromLTWH(
              wall.position.dx, wall.position.dy, wall.width, Wall.height)))
        .toList();

    // Combine overlapping walls
    for (int i = 0; i < walls.length; i++) {
      for (int j = i + 1; j < walls.length; j++) {
        if (_doWallsOverlap(walls[i], walls[j])) {
          wallPaths[i] = Path.combine(
            PathOperation.union,
            wallPaths[i],
            wallPaths[j],
          );
          wallPaths[j] = Path();
        }
      }
    }

    // Draw all walls
    for (int i = 0; i < wallPaths.length; i++) {
      if (wallPaths[i].computeMetrics().isEmpty) continue;

      final isSelected = i == selectedIndex;
      final wallRect = Rect.fromLTWH(
        walls[i].position.dx,
        walls[i].position.dy,
        walls[i].width,
        Wall.height,
      );

      // Draw the wall background with a different color if selected
      if (isSelected) {
        final backgroundPaint = Paint()
          ..color = Colors.blue.withOpacity(0.3); // Semi-transparent blue
        canvas.drawPath(wallPaths[i], backgroundPaint);
      }

      // Clip the canvas to the wall's bounds
      canvas.save();
      canvas.clipRect(wallRect);

      // Draw the diagonal lines pattern
      _drawDiagonalLines(canvas, wallRect);

      // Restore the canvas to remove the clip
      canvas.restore();

      // Draw the wall border with a different color if selected
      final borderPaint = isSelected
          ? (Paint()
            ..color = Colors.blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2)
          : _strokePaint;

      canvas.drawPath(wallPaths[i], borderPaint);

      // Draw measurement guides above and below the wall
      _drawMeasurementGuides(canvas, wallRect);
    }
  }

  /// Draws diagonal lines within the given rectangle.
  void _drawDiagonalLines(Canvas canvas, Rect rect) {
    final linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3) // Lighter grey color
      ..strokeWidth = 1;

    const lineSpacing = 5.0; // More stripes (reduced spacing)
    final startX = rect.left;
    final startY = rect.top;
    final endX = rect.right;
    final endY = rect.bottom;

    // Draw lines from top-left to bottom-right
    for (double i = 0; i < rect.width + rect.height; i += lineSpacing) {
      final start = Offset(startX, startY + i);
      final end = Offset(startX + i, startY);
      if (start.dy > endY && end.dx > endX) break;
      canvas.drawLine(start, end, linePaint);
    }
  }

  /// Draws measurement guides above and below the wall.
  void _drawMeasurementGuides(Canvas canvas, Rect rect) {
    const guideHeight = 10.0; // Distance from the wall
    const arrowSize = 5.0; // Size of the arrowheads
    const textPadding = 2.5; // Padding for the text

    // Draw the top measurement guide
    final topGuideY = rect.top - guideHeight;
    _drawMeasurementGuideWithArrows(canvas, rect.left, rect.right, topGuideY,
        arrowSize, rect.width, textPadding);

    // Draw the bottom measurement guide
    final bottomGuideY = rect.bottom + guideHeight;
    _drawMeasurementGuideWithArrows(canvas, rect.left, rect.right, bottomGuideY,
        arrowSize, rect.width, textPadding);
  }

  /// Draws a measurement guide with arrows, vertical lines, and text.
  void _drawMeasurementGuideWithArrows(
      Canvas canvas,
      double startX,
      double endX,
      double y,
      double arrowSize,
      double width,
      double textPadding) {
    // Draw the horizontal line
    canvas.drawLine(
      Offset(startX, y),
      Offset(endX, y),
      _measurementPaint,
    );

    // Draw the left vertical line
    canvas.drawLine(
      Offset(startX, y - arrowSize),
      Offset(startX, y + arrowSize),
      _measurementPaint,
    );

    // Draw the right vertical line
    canvas.drawLine(
      Offset(endX, y - arrowSize),
      Offset(endX, y + arrowSize),
      _measurementPaint,
    );

    // Draw the left arrow
    canvas.drawLine(
      Offset(startX, y),
      Offset(startX + arrowSize, y - arrowSize),
      _measurementPaint,
    );
    canvas.drawLine(
      Offset(startX, y),
      Offset(startX + arrowSize, y + arrowSize),
      _measurementPaint,
    );

    // Draw the right arrow
    canvas.drawLine(
      Offset(endX, y),
      Offset(endX - arrowSize, y - arrowSize),
      _measurementPaint,
    );
    canvas.drawLine(
      Offset(endX, y),
      Offset(endX - arrowSize, y + arrowSize),
      _measurementPaint,
    );

    // Add measurement text (width of the wall)
    final widthInMeters = width / pixelsPerMeter; // Convert pixels to meters

    final textSpan = TextSpan(
      text: '${widthInMeters.toStringAsFixed(2)} m',
      style: _textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw a background for the text
    final textBackgroundRect = Rect.fromLTWH(
      (startX + endX) / 2 - textPainter.width / 2 - textPadding,
      y - textPainter.height / 2 - textPadding,
      textPainter.width + 2 * textPadding,
      textPainter.height + 2 * textPadding,
    );
    canvas.drawRect(textBackgroundRect, _textBackgroundPaint);

    // Position the text in the middle of the guide line
    final textOffset = Offset(
      (startX + endX) / 2 - textPainter.width / 2,
      y - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  /// Checks if two walls overlap.
  bool _doWallsOverlap(Wall wall1, Wall wall2) {
    return Rect.fromLTWH(
            wall1.position.dx, wall1.position.dy, wall1.width, Wall.height)
        .overlaps(Rect.fromLTWH(
            wall2.position.dx, wall2.position.dy, wall2.width, Wall.height));
  }

  @override
  bool shouldRepaint(WallPainter oldDelegate) {
    return !const ListEquality().equals(walls, oldDelegate.walls) ||
        selectedIndex != oldDelegate.selectedIndex;
  }
}