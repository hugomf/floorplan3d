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
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Combine Walls with Path.combine'),
        ),
        body: const Center(
          child: WallPainterWidget(),
        ),
      ),
    );
  }
}

class WallPainterWidget extends StatefulWidget {
  const WallPainterWidget({super.key});

  @override
  State<WallPainterWidget> createState() => _WallPainterWidgetState();
}

class _WallPainterWidgetState extends State<WallPainterWidget> {
  Rect verticalWall = const Rect.fromLTWH(100, 50, 15, 200);
  Rect horizontalWall = const Rect.fromLTWH(100, 235, 200, 15);

  bool isDraggingVerticalWall = false;
  bool isDraggingHorizontalWall = false;
  Offset lastDragPosition = Offset.zero;

  void onPanStart(DragStartDetails details) {
    final Offset touchPosition = details.localPosition;

    if (verticalWall.contains(touchPosition)) {
      isDraggingVerticalWall = true;
    } else if (horizontalWall.contains(touchPosition)) {
      isDraggingHorizontalWall = true;
    }

    lastDragPosition = touchPosition;
  }

  void onPanUpdate(DragUpdateDetails details) {
    final Offset dragDelta = details.localPosition - lastDragPosition;

    setState(() {
      if (isDraggingVerticalWall) {
        verticalWall = verticalWall.shift(dragDelta);
      } else if (isDraggingHorizontalWall) {
        horizontalWall = horizontalWall.shift(dragDelta);
      }
    });

    lastDragPosition = details.localPosition;
  }

  void onPanEnd(DragEndDetails details) {
    isDraggingVerticalWall = false;
    isDraggingHorizontalWall = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: CustomPaint(
        size: const Size(400, 400), // Canvas size
        painter: WallPainter(
          verticalWall: verticalWall,
          horizontalWall: horizontalWall,
        ),
      ),
    );
  }
}

class WallPainter extends CustomPainter {
  final Rect verticalWall;
  final Rect horizontalWall;

  WallPainter({required this.verticalWall, required this.horizontalWall});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint wallPaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Path verticalWallPath = Path()..addRect(verticalWall);
    final Path horizontalWallPath = Path()..addRect(horizontalWall);

    canvas.drawPath(verticalWallPath, wallPaint);
    canvas.drawPath(horizontalWallPath, wallPaint);
  }

  @override
  bool shouldRepaint(covariant WallPainter oldDelegate) {
    return verticalWall != oldDelegate.verticalWall ||
        horizontalWall != oldDelegate.horizontalWall;
  }
}
