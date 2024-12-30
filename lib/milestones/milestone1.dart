import 'package:flutter/material.dart';
import 'dart:math';

// void main() {
//   runApp(FloorplanApp());
// }

class FloorplanApp_M1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floorplan Designer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FloorplanScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FloorplanScreen extends StatefulWidget {
  @override
  _FloorplanScreenState createState() => _FloorplanScreenState();
}

class _FloorplanScreenState extends State<FloorplanScreen> {
  List<Wall> _walls = [];
  Wall? _currentWall;
  double _wallWidth = 15.0;  // Default to external wall width (15cm)
  bool _isDrawing = false;
  WallType _wallType = WallType.external;  // Default wall type is external

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Floorplan Designer'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => setState(() => _walls.clear()),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showWallSettingsDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: FloorplanBackgroundPainter(),
          ),
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _isDrawing = true;
                _currentWall = Wall(
                  startPoint: details.localPosition,
                  endPoint: details.localPosition,
                  width: _wallWidth,
                  type: _wallType,
                );
              });
            },
            onPanUpdate: (details) {
              if (_isDrawing && _currentWall != null) {
                setState(() {
                  _currentWall?.endPoint = details.localPosition;
                });
              }
            },
            onPanEnd: (details) {
              setState(() {
                if (_currentWall != null) {
                  _walls.add(_currentWall!);
                  _currentWall = null;
                  _isDrawing = false;
                }
              });
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: WallPainter(_walls, _currentWall),
            ),
          ),
        ],
      ),
    );
  }

  void _showWallSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Wall Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<WallType>(
                value: _wallType,
                onChanged: (WallType? newValue) {
                  setState(() {
                    _wallType = newValue!;
                    _wallWidth = (_wallType == WallType.external) ? 15.0 : 10.0;
                  });
                },
                items: WallType.values.map((WallType wallType) {
                  return DropdownMenuItem<WallType>(
                    value: wallType,
                    child: Text(wallType.toString().split('.').last),
                  );
                }).toList(),
              ),
              Slider(
                value: _wallWidth,
                min: 5.0,
                max: 20.0,
                divisions: 15,
                label: '${_wallWidth.round()} cm',
                onChanged: (double value) {
                  setState(() {
                    _wallWidth = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class Wall {
  Offset startPoint;
  Offset endPoint;
  double width;
  WallType type;

  Wall({required this.startPoint, required this.endPoint, required this.width, required this.type});
}

enum WallType {
  external,
  internal,
}

class WallPainter extends CustomPainter {
  final List<Wall> walls;
  final Wall? currentWall;

  WallPainter(this.walls, this.currentWall);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black  // Color for the outline
      ..style = PaintingStyle.stroke  // Outline only
      ..strokeWidth = 2.0;  // Stroke width for the outline

    // Draw existing walls
    for (var wall in walls) {
      _drawWall(canvas, wall, paint);
    }

    // Draw the current wall being drawn
    if (currentWall != null) {
      _drawWall(canvas, currentWall!, paint);
    }
  }

  void _drawWall(Canvas canvas, Wall wall, Paint paint) {
    // Calculate perpendicular offset
    final dx = wall.endPoint.dx - wall.startPoint.dx;
    final dy = wall.endPoint.dy - wall.startPoint.dy;
    final length = sqrt(dx * dx + dy * dy);
    final offsetX = -dy / length * wall.width / 2;
    final offsetY = dx / length * wall.width / 2;

    final path = Path()
      ..moveTo(wall.startPoint.dx + offsetX, wall.startPoint.dy + offsetY)
      ..lineTo(wall.endPoint.dx + offsetX, wall.endPoint.dy + offsetY)
      ..lineTo(wall.endPoint.dx - offsetX, wall.endPoint.dy - offsetY)
      ..lineTo(wall.startPoint.dx - offsetX, wall.startPoint.dy - offsetY)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class FloorplanBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.stroke;

    const double gridSpacing = 20.0;

    // Draw grid lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}