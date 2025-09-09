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
  List<Offset> walls = [];
  int? selectedIndex;
  Offset? lastPosition;

  /// Adds a wall at the given position.
  void addWall(Offset position) {
    walls = List.from(walls)..add(position); // Create a new list
  }

  /// Selects a wall at the given position.
  void selectWall(Offset position) {
    for (int i = walls.length - 1; i >= 0; i--) {
      final wallRect = Rect.fromLTWH(walls[i].dx, walls[i].dy, Wall.width, Wall.height);
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
    walls[selectedIndex!] = Offset(
      walls[selectedIndex!].dx + (newPosition.dx - lastPosition!.dx),
      walls[selectedIndex!].dy + (newPosition.dy - lastPosition!.dy),
    );
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
                setState(() {
                  _wallModel.selectWall(details.localPosition);
                  _updatePainterKey(); // Force rebuild
                });
              }
            : null,
        onPanUpdate: !_isAddMode
            ? (details) {
                setState(() {
                  _wallModel.updateWallPosition(details.localPosition);
                  _updatePainterKey(); // Force rebuild
                });
              }
            : null,
        onPanEnd: !_isAddMode
            ? (details) {
                setState(() {
                  _wallModel.selectedIndex = null;
                  _wallModel.lastPosition = null;
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
}

/// Represents a wall with fixed dimensions.
class Wall {
  static const double width = 200;
  static const double height = 15;
}

/// Paints the walls and grid on the canvas.
class WallPainter extends CustomPainter {
  final List<Offset> walls;
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

    // Create wall paths and detect overlaps
    final List<Path> wallPaths = walls.map((pos) => Path()
      ..addRect(Rect.fromLTWH(pos.dx, pos.dy, Wall.width, Wall.height)))
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
      canvas.drawPath(wallPaths[i], isSelected ? _selectedPaint : _wallPaint);
      canvas.drawPath(wallPaths[i], _strokePaint);
    }
  }

  /// Checks if two walls overlap.
  bool _doWallsOverlap(Offset wall1, Offset wall2) {
    return Rect.fromLTWH(wall1.dx, wall1.dy, Wall.width, Wall.height)
        .overlaps(Rect.fromLTWH(wall2.dx, wall2.dy, Wall.width, Wall.height));
  }

  @override
  bool shouldRepaint(WallPainter oldDelegate) {
    return !const ListEquality().equals(walls, oldDelegate.walls) ||
        selectedIndex != oldDelegate.selectedIndex;
  }
}