import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

// === Constants ===
const double pixelsPerMeter = 20.0;
const double wallHeight = 10.0;
const double handlerSize = 5.0;
const double handlerTolerance = 10.0;
const double wallSelectionTolerance = 10.0;
const double minWallDistance = 5.0;
const double guideSeparation = 10.0;
const double guideExtension = 5.0;
const double gridSpacing = 20.0;
const double diagonalSpacing = 6.0;
const double marginOffset = 40.0;
const double marginWidth = 2.0;
const double snapTolerance = 10.0;

void main() {
  runApp(
    const MaterialApp(
      home: WallDrawingTool(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

// === Data Models ===
class Wall {
  Offset start;
  Offset end;

  Wall(this.start, this.end);

  Offset get center => (start + end) / 2;
  Offset get vector => end - start;
  double get length => vector.distance;
  double get angle => vector.direction;
}

// === Wall Utility for Transformations ===
class WallUtils {
  static Matrix4 getTransform(Wall wall) {
    return Matrix4.identity()
      ..translate(wall.center.dx, wall.center.dy)
      ..rotateZ(wall.angle);
  }

  static Path createWallPath(Wall wall) {
    final path = Path();
    final rect = Rect.fromLTWH(-wall.length / 2, -wallHeight / 2, wall.length, wallHeight);
    path.addRect(rect);
    return path.transform(getTransform(wall).storage);
  }

  static Offset getHandlerPosition(Wall wall, {required bool isLeft}) {
    final handlerOffset = Offset(isLeft ? -wall.length / 2 : wall.length / 2, 0);
    return MatrixUtils.transformPoint(getTransform(wall), handlerOffset);
  }
}

// === Controller for State Management ===
class WallDrawingController extends ChangeNotifier {
  // === State Variables ===
  final List<Wall> _walls = [];
  Offset? _startPoint;
  Offset? _endPoint;
  Wall? _selectedWall;
  Offset? _dragStartPoint;
  bool _isResizingLeft = false;
  bool _isResizingRight = false;
  bool _isDraggingWall = false;
  Offset? _snapPosition;
  bool _isSnapEnabled = false;

  // === Getters for state access ===
  List<Wall> get walls => _walls;
  Wall? get currentWall => (_startPoint != null && _endPoint != null) ? Wall(_startPoint!, _endPoint!) : null;
  Wall? get selectedWall => _selectedWall;
  bool get isResizingLeft => _isResizingLeft;
  bool get isResizingRight => _isResizingRight;
  bool get isDraggingWall => _isDraggingWall;
  Offset? get snapPosition => _snapPosition;
  bool get isSnapEnabled => _isSnapEnabled;

  // === Public API to handle gestures ===
  void onTapDown(Offset tapPosition) {
    _selectedWall = _findWallAtPosition(tapPosition);
    _resetInteractionState();
    notifyListeners();
  }

  void onPanStart(Offset tapPosition) {
    _resetInteractionState();

    if (_selectedWall != null) {
      if (_checkAndStartResizing(tapPosition)) return;
      if (_checkAndStartDragging(tapPosition)) return;
    }

    if (_selectedWall == null) {
      _startDrawingNewWall(tapPosition);
    }
    notifyListeners();
  }

  void onPanUpdate(Offset currentPosition) {
    Offset snappedPosition = _isSnapEnabled ? _snapPoint(currentPosition) : currentPosition;
    _snapPosition = _isSnapEnabled ? snappedPosition : null;

    if (_selectedWall != null) {
      if (_isResizingLeft) {
        _selectedWall!.start = snappedPosition;
      } else if (_isResizingRight) {
        _selectedWall!.end = snappedPosition;
      } else if (_isDraggingWall) {
        _moveSelectedWall(currentPosition);
      }
    } else if (_startPoint != null) {
      _endPoint = snappedPosition;
    }
    notifyListeners();
  }

  void onPanEnd() {
    if (_startPoint != null && _endPoint != null) {
      _finishDrawingWall();
    }
    _resetInteractionState();
    _startPoint = null;
    _endPoint = null;
    _snapPosition = null;
    notifyListeners();
  }

  void deleteSelectedWall() {
    if (_selectedWall != null) {
      _walls.remove(_selectedWall);
      _selectedWall = null;
      notifyListeners();
    }
  }

  void clearAllWalls() {
    _walls.clear();
    _selectedWall = null;
    notifyListeners();
  }

  void toggleSnap() {
    _isSnapEnabled = !_isSnapEnabled;
    notifyListeners();
  }

  // === Private Helper Methods (Refactored for clarity) ===
  Wall? _findWallAtPosition(Offset position) {
    for (var wall in _walls) {
      if (_isPointOnWall(position, wall)) {
        return wall;
      }
    }
    return null;
  }

  bool _checkAndStartResizing(Offset tapPosition) {
    final leftHandler = WallUtils.getHandlerPosition(_selectedWall!, isLeft: true);
    final rightHandler = WallUtils.getHandlerPosition(_selectedWall!, isLeft: false);

    if ((tapPosition - leftHandler).distance < handlerTolerance) {
      _isResizingLeft = true;
      _dragStartPoint = tapPosition;
      return true;
    } else if ((tapPosition - rightHandler).distance < handlerTolerance) {
      _isResizingRight = true;
      _dragStartPoint = tapPosition;
      return true;
    }
    return false;
  }

  bool _checkAndStartDragging(Offset tapPosition) {
    if (_isPointOnWall(tapPosition, _selectedWall!)) {
      _dragStartPoint = tapPosition;
      _isDraggingWall = true;
      return true;
    }
    return false;
  }

  void _startDrawingNewWall(Offset position) {
    _startPoint = position;
    _endPoint = position;
    _selectedWall = null;
  }

  void _moveSelectedWall(Offset currentPosition) {
    final delta = currentPosition - _dragStartPoint!;
    _selectedWall!.start += delta;
    _selectedWall!.end += delta;
    _dragStartPoint = currentPosition;
  }

  void _finishDrawingWall() {
    final distance = (_endPoint! - _startPoint!).distance;
    if (distance > minWallDistance) {
      _walls.add(Wall(_startPoint!, _endPoint!));
    }
  }

  void _resetInteractionState() {
    _dragStartPoint = null;
    _isResizingLeft = false;
    _isResizingRight = false;
    _isDraggingWall = false;
  }

  bool _isPointOnWall(Offset point, Wall wall) {
    final wallVector = wall.end - wall.start;
    final wallLength = wallVector.distance;
    if (wallLength == 0) return false;

    final unitVector = wallVector / wallLength;
    final pointVector = point - wall.start;
    final projection = pointVector.dx * unitVector.dx + pointVector.dy * unitVector.dy;
    if (projection < 0 || projection > wallLength) return false;

    final perpDistance = (pointVector.dx * unitVector.dy - pointVector.dy * unitVector.dx).abs();
    return perpDistance < wallSelectionTolerance;
  }

  Offset _snapPoint(Offset position) {
    Offset snappedPoint = position;

    // Snap to grid
    double snappedX = (position.dx / gridSpacing).round() * gridSpacing;
    double snappedY = (position.dy / gridSpacing).round() * gridSpacing;
    if ((position - Offset(snappedX, snappedY)).distance < snapTolerance) {
      snappedPoint = Offset(snappedX, snappedY);
    }

    // Snap to other wall endpoints
    for (final wall in _walls) {
      final endpoints = [wall.start, wall.end];
      for (final endpoint in endpoints) {
        if ((position - endpoint).distance < snapTolerance) {
          snappedPoint = endpoint;
          break;
        }
      }
      if (snappedPoint != position) break;
    }
    return snappedPoint;
  }
}

// === Main Widget ===
class WallDrawingTool extends StatefulWidget {
  const WallDrawingTool({super.key});

  @override
  WallDrawingToolState createState() => WallDrawingToolState();
}

class WallDrawingToolState extends State<WallDrawingTool> {
  late final WallDrawingController _controller;
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _stackKey = GlobalKey();
  Offset _toolbarLocalPosition = const Offset(10.0, 10.0);

  @override
  void initState() {
    super.initState();
    _controller = WallDrawingController();
    _loadToolbarPosition(); // Load saved position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Load toolbar position from SharedPreferences
  Future<void> _loadToolbarPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final double? x = prefs.getDouble('toolbar_x');
    final double? y = prefs.getDouble('toolbar_y');
    if (x != null && y != null) {
      setState(() {
        _toolbarLocalPosition = Offset(x, y);
      });
    }
  }

  // Save toolbar position to SharedPreferences
  Future<void> _saveToolbarPosition(Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('toolbar_x', position.dx);
    await prefs.setDouble('toolbar_y', position.dy);
  }

  KeyEventResult _handleKeyEvent(FocusNode focusNode, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if ((event.logicalKey == LogicalKeyboardKey.delete ||
          event.logicalKey == LogicalKeyboardKey.backspace) &&
          _controller.selectedWall != null) {
        _controller.deleteSelectedWall();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Wall Drawing Tool'),
      ),
      body: SafeArea(
        child: RepaintBoundary(
          child: Stack(
            key: _stackKey,
            children: [
              const BackgroundGrid(),

              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    children: [
                      ..._controller.walls.map((wall) => ClipPath(
                        key: ValueKey('${wall.start}_${wall.end}'),
                        clipper: WallClipper(wall),
                        child: const DiagonalPattern(),
                      )),
                      if (_controller.currentWall != null)
                        ClipPath(
                          clipper: WallClipper(_controller.currentWall!),
                          child: const DiagonalPattern(),
                        ),

                      Focus(
                        focusNode: _focusNode,
                        autofocus: true,
                        onKey: _handleKeyEvent,
                        onFocusChange: (hasFocus) {
                          if (!hasFocus) {
                            _focusNode.requestFocus();
                          }
                        },
                        child: GestureDetector(
                          onTapDown: (details) {
                            _controller.onTapDown(details.localPosition);
                            _focusNode.requestFocus();
                          },
                          onPanStart: (details) => _controller.onPanStart(details.localPosition),
                          onPanUpdate: (details) => _controller.onPanUpdate(details.localPosition),
                          onPanEnd: (_) => _controller.onPanEnd(),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.transparent,
                            child: CustomPaint(
                              painter: WallPainter(
                                walls: _controller.walls,
                                currentWall: _controller.currentWall,
                                selectedWall: _controller.selectedWall,
                                isResizingLeft: _controller.isResizingLeft,
                                isResizingRight: _controller.isResizingRight,
                                isDragging: _controller.isDraggingWall,
                                snapPosition: _controller.snapPosition,
                                isSnapEnabled: _controller.isSnapEnabled,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              Positioned(
                top: 10,
                left: 10,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _controller.selectedWall != null
                            ? 'Selected wall - Drag to move or resize. Press Delete to remove.'
                            : 'Tap and drag to create walls',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                left: _toolbarLocalPosition.dx,
                top: _toolbarLocalPosition.dy,
                child: Draggable(
                  feedback: Opacity(
                    opacity: 0.7,
                    child: _buildToolbar(),
                  ),
                  childWhenDragging: Container(),
                  onDragEnd: (details) {
                    final RenderBox stackRenderBox = _stackKey.currentContext!.findRenderObject()! as RenderBox;
                    final localOffset = stackRenderBox.globalToLocal(details.offset);
                    final stackSize = stackRenderBox.size;

                    // Clamp the position to stay within the Stack's bounds
                    final clampedX = localOffset.dx.clamp(0.0, stackSize.width - 80.0);
                    final clampedY = localOffset.dy.clamp(0.0, stackSize.height - 120.0);

                    setState(() {
                      _toolbarLocalPosition = Offset(clampedX, clampedY);
                      _saveToolbarPosition(_toolbarLocalPosition); // Save the new position
                    });
                  },
                  child: _buildToolbar(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isSnapEnabled = _controller.isSnapEnabled;
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _controller.deleteSelectedWall,
                tooltip: 'Delete selected wall',
              ),
              const Divider(height: 10, color: Colors.grey),
              IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.blueGrey),
                onPressed: _controller.clearAllWalls,
                tooltip: 'Clear all walls',
              ),
              const Divider(height: 10, color: Colors.grey),
              IconButton(
                icon: Icon(
                  isSnapEnabled ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: isSnapEnabled ? Colors.green : Colors.black,
                ),
                onPressed: _controller.toggleSnap,
                tooltip: 'Toggle snapping (${isSnapEnabled ? 'On' : 'Off'})',
              ),
            ],
          ),
        );
      },
    );
  }
}

// === Custom Clippers ===
class WallClipper extends CustomClipper<Path> {
  final Wall wall;

  const WallClipper(this.wall);

  @override
  Path getClip(Size size) {
    return WallUtils.createWallPath(wall);
  }

  @override
  bool shouldReclip(covariant WallClipper oldClipper) {
    return oldClipper.wall.start != wall.start || oldClipper.wall.end != wall.end;
  }
}

// === Custom Painters ===
class WallPainter extends CustomPainter {
  final List<Wall> walls;
  final Wall? currentWall;
  final Wall? selectedWall;
  final bool isResizingLeft;
  final bool isResizingRight;
  final bool isDragging;
  final Offset? snapPosition;
  final bool isSnapEnabled;

  static final _wallPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  static final _selectedPaint = Paint()
    ..color = Colors.blue
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  static final _handlerPaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.fill;

  static final _snapPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;

  const WallPainter({
    required this.walls,
    this.currentWall,
    this.selectedWall,
    this.isResizingLeft = false,
    this.isResizingRight = false,
    this.isDragging = false,
    this.snapPosition,
    this.isSnapEnabled = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawAllWalls(canvas);
    _drawSelectedWall(canvas);
    if (!isDragging && selectedWall != null) {
      _drawMeasurementGuides(canvas, selectedWall!);
    }
    _drawSnapGuide(canvas);
  }

  void _drawAllWalls(Canvas canvas) {
    Path mergedPath = Path();

    for (final wall in walls) {
      final wallPath = WallUtils.createWallPath(wall);
      mergedPath = Path.combine(PathOperation.union, mergedPath, wallPath);
    }

    if (currentWall != null) {
      final currentWallPath = WallUtils.createWallPath(currentWall!);
      mergedPath = Path.combine(PathOperation.union, mergedPath, currentWallPath);
    }

    canvas.drawPath(mergedPath, _wallPaint);
  }

  void _drawSelectedWall(Canvas canvas) {
    if (selectedWall == null) return;

    final selectedPath = WallUtils.createWallPath(selectedWall!);
    canvas.drawPath(selectedPath, _selectedPaint);

    if (!isDragging) {
      _drawHandlers(canvas, selectedWall!);
    }
  }

  void _drawHandlers(Canvas canvas, Wall wall) {
    final leftHandler = WallUtils.getHandlerPosition(wall, isLeft: true);
    final rightHandler = WallUtils.getHandlerPosition(wall, isLeft: false);

    _drawHandler(canvas, leftHandler);
    _drawHandler(canvas, rightHandler);
  }

  void _drawHandler(Canvas canvas, Offset position) {
    final rect = Rect.fromCenter(center: position, width: handlerSize, height: handlerSize);
    canvas.drawRect(rect, _handlerPaint);
  }

  void _drawMeasurementGuides(Canvas canvas, Wall wall) {
    canvas.save();
    canvas.translate(wall.center.dx, wall.center.dy);
    canvas.rotate(wall.angle);

    final guidePaint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _drawGuideLines(canvas, wall.length, guidePaint);
    _drawMeasurementText(canvas, wall);

    canvas.restore();
  }

  void _drawGuideLines(Canvas canvas, double wallLength, Paint paint) {
    final halfWidth = wallLength / 2;
    final topY = -wallHeight / 2 - guideSeparation;
    final bottomY = wallHeight / 2 + guideSeparation;

    canvas.drawLine(Offset(-halfWidth, topY), Offset(halfWidth, topY), paint);
    _drawVerticalLineWithArrow(canvas, -halfWidth, topY, guideExtension, paint, isStart: true);
    _drawVerticalLineWithArrow(canvas, halfWidth, topY, guideExtension, paint, isStart: false);

    canvas.drawLine(Offset(-halfWidth, bottomY), Offset(halfWidth, bottomY), paint);
    _drawVerticalLineWithArrow(canvas, -halfWidth, bottomY, guideExtension, paint, isStart: true);
    _drawVerticalLineWithArrow(canvas, halfWidth, bottomY, guideExtension, paint, isStart: false);
  }

  void _drawMeasurementText(Canvas canvas, Wall wall) {
    final meters = wall.length / pixelsPerMeter;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${meters.toStringAsFixed(2)} m',
        style: const TextStyle(
          color: Colors.blueGrey,
          fontSize: 12,
          backgroundColor: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final isUpsideDown = wall.angle > math.pi / 2 || wall.angle < -math.pi / 2;

    _drawTextAtPosition(canvas, textPainter, -wallHeight / 2 - guideSeparation, isUpsideDown);
    _drawTextAtPosition(canvas, textPainter, wallHeight / 2 + guideSeparation, isUpsideDown);
  }

  void _drawTextAtPosition(Canvas canvas, TextPainter textPainter, double y, bool isUpsideDown) {
    canvas.save();
    canvas.translate(-textPainter.width / 2, y - textPainter.height / 2);
    if (isUpsideDown) {
      canvas.translate(textPainter.width / 2, textPainter.height / 2);
      canvas.rotate(math.pi);
      canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    }
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawVerticalLineWithArrow(Canvas canvas, double x, double y, double arrowSize, Paint paint, {required bool isStart}) {
    canvas.drawLine(Offset(x, y - arrowSize), Offset(x, y + arrowSize), paint);
    if (isStart) {
      canvas.drawLine(Offset(x, y), Offset(x + arrowSize, y - arrowSize), paint);
      canvas.drawLine(Offset(x, y), Offset(x + arrowSize, y + arrowSize), paint);
    } else {
      canvas.drawLine(Offset(x - arrowSize, y - arrowSize), Offset(x, y), paint);
      canvas.drawLine(Offset(x - arrowSize, y + arrowSize), Offset(x, y), paint);
    }
  }

  void _drawSnapGuide(Canvas canvas) {
    if (isSnapEnabled && snapPosition != null) {
      canvas.drawCircle(snapPosition!, handlerSize, _snapPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WallPainter oldDelegate) {
    return oldDelegate.walls != walls ||
        oldDelegate.currentWall != currentWall ||
        oldDelegate.selectedWall != selectedWall ||
        oldDelegate.isResizingLeft != isResizingLeft ||
        oldDelegate.isResizingRight != isResizingRight ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.snapPosition != snapPosition ||
        oldDelegate.isSnapEnabled != isSnapEnabled;
  }
}

// === Background Components ===
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
  static final _marginPaint = Paint()
    ..color = Colors.red.withOpacity(0.4)
    ..strokeWidth = marginWidth
    ..style = PaintingStyle.stroke;

  static final _gridPaint = Paint()
    ..color = const Color(0xFFADD8E6).withOpacity(0.3)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    _drawLeftMargin(canvas, size);
    _drawGrid(canvas, size);
  }

  void _drawLeftMargin(Canvas canvas, Size size) {
    canvas.drawLine(
      const Offset(marginOffset, 0),
      Offset(marginOffset, size.height),
      _marginPaint,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }

    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

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
  static final _diagonalPaint = Paint()
    ..color = Colors.blueGrey
    ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (double i = -size.height; i < size.width; i += diagonalSpacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        _diagonalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}