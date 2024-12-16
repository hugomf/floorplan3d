import 'package:flutter/material.dart';

class GridCanvas extends StatefulWidget {
  @override
  _GridCanvasState createState() => _GridCanvasState();
}

class _GridCanvasState extends State<GridCanvas> {
  final List<Offset> _lines = [];

  void _addLine(Offset start, Offset end) {
    setState(() {
      _lines.add(start);
      _lines.add(end);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final localPosition = details.localPosition;
        if (_lines.isNotEmpty && _lines.length % 2 == 1) {
          _addLine(_lines.last, localPosition);
        }
      },
      onPanStart: (details) {
        final start = details.localPosition;
        _addLine(start, start);
      },
      child: CustomPaint(
        painter: GridPainter(_lines),
        size: Size.infinite,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final List<Offset> lines;

  GridPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.grey[300]!;
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;

    // Draw grid
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 0; j < size.height; j += 20) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }

    // Draw user-drawn lines
    for (int i = 0; i < lines.length; i += 2) {
      canvas.drawLine(lines[i], lines[i + 1], linePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
