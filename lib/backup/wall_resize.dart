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
    walls = List.from(walls); // Create a new list
    final deltaX = newPosition.dx - lastPosition!.dx;
    walls[selectedIndex!].width += deltaX; // Update the width
    lastPosition = newPosition;
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
      body: GestureDetector(
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
                  if (_isNearEdge(position, wall)) {
                    _wallModel.isResizing = true;
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
                  _updatePainterKey(); // Force rebuild
                });
              }
            : null,
        child: CustomPaint(
          key: ValueKey(_painterKey), // Force rebuild with new UUID
          painter: WallPainter(
            walls: _wallModel.walls,
            selectedIndex: _wallModel.selectedIndex,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  /// Checks if the user is clicking near the left or right edge of a wall.
  bool _isNearEdge(Offset position, Wall wall) {
    const edgeThreshold = 10.0; // How close to the edge to consider a click
    final wallRect = Rect.fromLTWH(
      wall.position.dx,
      wall.position.dy,
      wall.width,
      Wall.height,
    );
    return (position.dx >= wallRect.left - edgeThreshold &&
            position.dx <= wallRect.left + edgeThreshold) ||
        (position.dx >= wallRect.right - edgeThreshold &&
            position.dx <= wallRect.right + edgeThreshold);
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

  static final _wallPaint = Paint()
    ..color = Colors.deepOrange
    ..style = PaintingStyle.fill;

  static final _selectedPaint = Paint()
    ..color = Colors.green
    ..style = PaintingStyle.fill;

  static final _strokePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static final _gridPaint = Paint()
    ..color = Colors.blue.withAlpha(_gridAlpha)
    ..style = PaintingStyle.stroke;

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

    for (int i = 0; i < walls.length; i++) {
      final wall = walls[i];
      final wallRect = Rect.fromLTWH(
        wall.position.dx,
        wall.position.dy,
        wall.width,
        Wall.height,
      );
      final isSelected = i == selectedIndex;
      canvas.drawRect(wallRect, isSelected ? _selectedPaint : _wallPaint);
      canvas.drawRect(wallRect, _strokePaint);
    }
  }

  @override
  bool shouldRepaint(WallPainter oldDelegate) {
    return !const ListEquality().equals(walls, oldDelegate.walls) ||
        selectedIndex != oldDelegate.selectedIndex;
  }
}