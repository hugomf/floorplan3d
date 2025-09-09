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
  final List<Offset> wallPositions = [];
  bool isAddWallMode = false;
  int? selectedWallIndex; // Track the selected wall
  Offset? _initialTouchPosition; // Track the initial touch position for dragging

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
                selectedWallIndex = null; // Deselect any selected wall when switching modes
              });
            },
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onTapUp: isAddWallMode
              ? (details) {
                  setState(() {
                    wallPositions.add(details.localPosition); // Add a new wall at the tapped position
                  });
                }
              : null,
          onPanStart: (details) {
            if (!isAddWallMode) {
              for (int i = 0; i < wallPositions.length; i++) {
                final rect = Rect.fromLTWH(
                  wallPositions[i].dx,
                  wallPositions[i].dy,
                  Wall.defaultWidth,
                  Wall.defaultHeight,
                );
                if (rect.contains(details.localPosition)) {
                  setState(() {
                    selectedWallIndex = i; // Select the wall
                    _initialTouchPosition = details.localPosition; // Store the initial touch position
                  });
                  break;
                }
              }
            }
          },
          onPanUpdate: (details) {
            if (!isAddWallMode && selectedWallIndex != null && _initialTouchPosition != null) {
              setState(() {
                // Update the wall's position based on the drag offset
                wallPositions[selectedWallIndex!] = Offset(
                  wallPositions[selectedWallIndex!].dx + (details.localPosition.dx - _initialTouchPosition!.dx),
                  wallPositions[selectedWallIndex!].dy + (details.localPosition.dy - _initialTouchPosition!.dy),
                );
                _initialTouchPosition = details.localPosition; // Update the initial touch position
              });
            }
          },
          onPanEnd: (details) {
            if (!isAddWallMode) {
              setState(() {
                selectedWallIndex = null; // Deselect the wall after moving
                _initialTouchPosition = null; // Reset the initial touch position
              });
            }
          },
          child: CustomPaint(
            size: Size.infinite,
            painter: WallPainter(wallPositions: wallPositions, selectedWallIndex: selectedWallIndex),
          ),
        ),
      ),
    );
  }
}

class Wall {
  static const double defaultWidth = 200.0;
  static const double defaultHeight = 15.0;

  final Canvas canvas;
  final Offset startPoint;
  final double width;
  final double height;

  Wall({
    required this.canvas,
    required this.startPoint,
    this.width = defaultWidth,
    this.height = defaultHeight,
  });

  void draw({bool isSelected = false}) {
    final Paint wallPaint = Paint()
      ..color = isSelected ? Colors.green : Colors.deepOrange // Highlight selected wall
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Path wallPath = Path()
      ..addRect(Rect.fromLTWH(
        startPoint.dx,
        startPoint.dy,
        width,
        height,
      ));

    canvas.drawPath(wallPath, wallPaint);
  }
}

class WallPainter extends CustomPainter {
  static const double gridSpacing = 20.0;
  static const double gridOpacity = 0.2;

  final List<Offset> wallPositions;
  final int? selectedWallIndex;

  WallPainter({required this.wallPositions, this.selectedWallIndex});

  void _drawGrid(Canvas canvas, Size size) {
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
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    for (int i = 0; i < wallPositions.length; i++) {
      Wall(
        canvas: canvas,
        startPoint: wallPositions[i],
      ).draw(isSelected: i == selectedWallIndex); // Pass whether the wall is selected
    }
  }

  @override
  bool shouldRepaint(covariant WallPainter oldDelegate) {
    return true;
  }
}