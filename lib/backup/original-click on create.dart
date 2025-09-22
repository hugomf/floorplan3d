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
      body: Center(
        child: GestureDetector(
          onTapUp: isAddWallMode
              ? (details) {
                  setState(() {
                    wallPositions.add(details.localPosition);
                  });
                }
              : null,
          child: CustomPaint(
            size: Size.infinite,
            painter: WallPainter(wallPositions: wallPositions),
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

  void draw() {
    final Paint wallPaint = Paint()
      ..color = Colors.deepOrange
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

  WallPainter({required this.wallPositions});

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

    for (final startPoint in wallPositions) {
      Wall(
        canvas: canvas,
        startPoint: startPoint,
      ).draw();
    }
  }

  @override
  bool shouldRepaint(covariant WallPainter oldDelegate) {
    return true;
  }
} 