import 'package:flutter/material.dart';

void main() {
  runApp(const CombineWallTestApp());
}

class CombineWallTestApp extends StatelessWidget {
  const CombineWallTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WallCombinerScreen(),
    );
  }
}

class WallCombinerScreen extends StatefulWidget {
  const WallCombinerScreen({super.key});

  @override
  State<WallCombinerScreen> createState() => _WallCombinerScreenState();
}

class _WallCombinerScreenState extends State<WallCombinerScreen> {
  final List<Wall> walls = [];
  bool isAddWallMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Combine Walls with Path.combine'),
        actions: [
          IconButton(
            icon: Icon(
              isAddWallMode ? Icons.check : Icons.add,
              color: isAddWallMode ? Colors.green : Colors.blueGrey,
            ),
            tooltip: isAddWallMode ? 'Exit Add Wall Mode' : 'Add a wall',
            onPressed: () {
              setState(() {
                isAddWallMode = !isAddWallMode;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: WallsPainter(walls: walls),
          ),
          if (isAddWallMode)
            GestureDetector(
              onTapUp: (details) {
                setState(() {
                  walls.add(Wall(
                    startPoint: details.localPosition,
                    onUpdate: () => setState(() {}),
                  ));
                });
              },
            ),
          for (final wall in walls)
            Positioned(
              left: wall.startPoint.dx,
              top: wall.startPoint.dy,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    wall.isSelected = !wall.isSelected;
                  });
                },
                onPanUpdate: (details) {
                  if (wall.isSelected) {
                    setState(() {
                      wall.startPoint = Offset(
                        wall.startPoint.dx + details.delta.dx,
                        wall.startPoint.dy + details.delta.dy,
                      );
                    });
                  }
                },
                onPanEnd: (details) {
                  setState(() {
                    wall.isSelected = false;
                  });
                },
                child: Container(
                  width: Wall.defaultWidth,
                  height: Wall.defaultHeight,
                  color: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Wall {
  static const double defaultWidth = 200.0;
  static const double defaultHeight = 15.0;

  Offset startPoint;
  bool isSelected = false;
  final VoidCallback onUpdate;

  Wall({
    required this.startPoint,
    required this.onUpdate,
  });

  Rect get rect => Rect.fromLTWH(
        startPoint.dx,
        startPoint.dy,
        defaultWidth,
        defaultHeight,
      );

  Path get path => Path()..addRect(rect);
}

class WallsPainter extends CustomPainter {
  final List<Wall> walls;

  WallsPainter({required this.walls});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint wallPaint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.fill;

    final Paint selectedPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (walls.isEmpty) return;

    // Create combined path for all walls
    Path combinedPath = Path();
    
    // Start with the first wall
    for (int i = 0; i < walls.length; i++) {
      final Wall currentWall = walls[i];
      Path currentPath = currentWall.path;

      // Check for overlapping walls
      for (int j = 0; j < walls.length; j++) {
        if (i != j) {
          final Wall otherWall = walls[j];
          if (_doWallsOverlap(currentWall, otherWall)) {
            // Combine the paths using PathOperation.union
            currentPath = Path.combine(
              PathOperation.union,
              currentPath,
              otherWall.path,
            );
          }
        }
      }

      // Add the resulting path to the combined path
      combinedPath = Path.combine(
        PathOperation.union,
        combinedPath,
        currentPath,
      );

      // Draw selection highlight for selected walls
      if (currentWall.isSelected) {
        canvas.drawPath(currentWall.path, selectedPaint);
      }
    }

    // Draw the combined walls
    canvas.drawPath(combinedPath, wallPaint);
    canvas.drawPath(combinedPath, strokePaint);
  }

  bool _doWallsOverlap(Wall wall1, Wall wall2) {
    return wall1.rect.overlaps(wall2.rect);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class GridPainter extends CustomPainter {
  static const double gridSpacing = 20.0;
  static const double gridOpacity = 0.2;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.blue.withOpacity(gridOpacity)
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}