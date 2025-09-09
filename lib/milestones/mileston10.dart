import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
const double snapTolerance = 10.0; // Tolerance for snapping

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
  double get angle => math.atan2(vector.dy, vector.dx);
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
  bool _isSnapEnabled = false; // New state variable for snap toggle
  Offset? _snapPosition; // For visual feedback of the snap target

  // === Getters for state access ===
  List<Wall> get walls => _walls;
  Wall? get currentWall => (_startPoint != null && _endPoint != null) ? Wall(_startPoint!, _endPoint!) : null;
  Wall? get selectedWall => _selectedWall;
  bool get isResizingLeft => _isResizingLeft;
  bool get isResizingRight => _isResizingRight;
  bool get isDraggingWall => _isDraggingWall;
  bool get isSnapEnabled => _isSnapEnabled; // Getter for snap toggle
  Offset? get snapPosition => _snapPosition;

  // === Public API to handle gestures ===
  void onTapDown(Offset tapPosition) {
    _selectedWall = _findWallAtPosition(tapPosition);
    _resetInteractionState();
    notifyListeners();
  }

  void onPanStart(Offset tapPosition) {
    _resetInteractionState();
    Offset potentialSnapPoint = _isSnapEnabled ? _snapPoint(tapPosition) : tapPosition;

    if (_selectedWall != null) {
      if (_checkAndStartResizing(potentialSnapPoint)) return;
      if (_checkAndStartDragging(potentialSnapPoint)) return;
    }

    if (_selectedWall == null) {
      _startDrawingNewWall(potentialSnapPoint);
    }
    notifyListeners();
  }

  void onPanUpdate(Offset currentPosition) {
    Offset positionToUpdate = _isSnapEnabled ? _snapPoint(currentPosition) : currentPosition;
    _snapPosition = _isSnapEnabled ? positionToUpdate : null; // Update snap visual only if enabled

    if (_selectedWall != null) {
      if (_isResizingLeft) {
        _selectedWall!.start = positionToUpdate;
      } else if (_isResizingRight) {
        _selectedWall!.end = positionToUpdate;
      } else if (_isDraggingWall) {
        _moveSelectedWall(positionToUpdate);
      }
    } else if (_startPoint != null) {
      _endPoint = positionToUpdate;
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
    _snapPosition = null; // Clear snap visual
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

  // New method to toggle snap functionality
  void toggleSnap() {
    _isSnapEnabled = !_isSnapEnabled;
    if (!_isSnapEnabled) {
      _snapPosition = null; // Clear snap visual if snapping is turned off
    }
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
      _dragStartPoint = tapPosition; // Use original tap position for delta calculation
      return true;
    } else if ((tapPosition - rightHandler).distance < handlerTolerance) {
      _isResizingRight = true;
      _dragStartPoint = tapPosition; // Use original tap position for delta calculation
      return true;
    }
    return false;
  }

  bool _checkAndStartDragging(Offset tapPosition) {
    if (_isPointOnWall(tapPosition, _selectedWall!)) {
      _dragStartPoint = tapPosition; // Use original tap position for delta calculation
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
    // Delta is calculated from the original drag start point to the current snapped position
    final delta = currentPosition - _dragStartPoint!;
    _selectedWall!.start += delta;
    _selectedWall!.end += delta;
    _dragStartPoint = currentPosition; // Update drag start to the current position for next update
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

    // Store original position before snapping for delta calculations
    final originalPosition = position;

    // --- Snapping Logic ---
    Offset gridSnapped = Offset(
      (position.dx / gridSpacing).round() * gridSpacing,
      (position.dy / gridSpacing).round() * gridSpacing,
    );

    if ((position - gridSnapped).distance < snapTolerance) {
      snappedPoint = gridSnapped;
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
      if (snappedPoint != position) break; // Found a snap point, no need to check further
    }
    // --- End Snapping Logic ---

    // If resizing or dragging, and we snapped, ensure dragStartPoint is updated correctly
    // to maintain delta calculation accuracy.
    if (_isResizingLeft || _isResizingRight || _isDraggingWall) {
       // If we snapped, the dragStartPoint needs to reflect the new 'anchor' point.
       // This is a bit tricky. If the dragStartPoint was based on the original position,
       // and we snapped, the delta calculation needs to be relative to the snapped point.
       // For simplicity here, we ensure the dragStartPoint is updated to the *newly* snapped position
       // on the *next* panUpdate. For the *current* panUpdate, the delta uses the old dragStartPoint.
       // The _moveSelectedWall method handles updating dragStartPoint to the currentPosition (which is snappedPosition).
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
                      // Draw existing walls with diagonal pattern
                      ..._controller.walls.map((wall) => ClipPath(
                        clipper: WallClipper(wall),
                        child: const DiagonalPattern(),
                      )),
                      // Draw the wall currently being created
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
                                snapPosition: _controller.snapPosition, // Pass snap position for painter
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Informational Text
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

              // Toolbar
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
                    final clampedX = localOffset.dx.clamp(0.0, stackSize.width - 80.0); // Adjust based on toolbar width
                    final clampedY = localOffset.dy.clamp(0.0, stackSize.height - 120.0); // Adjust based on toolbar height

                    setState(() {
                      _toolbarLocalPosition = Offset(clampedX, clampedY);
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

  // Builds the toolbar with delete, clear, and snap buttons
  Widget _buildToolbar() {
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
          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _controller.deleteSelectedWall,
            tooltip: 'Delete selected wall',
          ),
          const Divider(height: 10, color: Colors.grey),
          // Clear All Button
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.blueGrey),
            onPressed: _controller.clearAllWalls,
            tooltip: 'Clear all walls',
          ),
          const Divider(height: 10, color: Colors.grey),
          // Snap Toggle Button
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return IconButton(
                icon: Icon(
                  _controller.isSnapEnabled ? Icons.link_off : Icons.link, // Link for snapping on, Link Off for snapping off
                  color: _controller.isSnapEnabled ? Colors.orange : Colors.grey,
                ),
                onPressed: _controller.toggleSnap,
                tooltip: _controller.isSnapEnabled ? 'Disable snapping' : 'Enable snapping',
              );
            },
          ),
        ],
      ),
    );
  }
}

// === Custom Clippers ===
class WallClipper extends CustomClipper<Path> {
  final Wall wall;

  WallClipper(this.wall);

  @override
  Path getClip(Size size) {
    return WallUtils.createWallPath(wall);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// === Custom Painters ===
class WallPainter extends CustomPainter {
  final List<Wall> walls;
  final Wall? currentWall;
  final Wall? selectedWall;
  final bool isResizingLeft;
  final bool isResizingRight;
  final bool isDragging;
  final Offset? snapPosition; // Receive snap position for drawing

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

  // Paint for the snap guide
  static final _snapPaint = Paint()
    ..color = Colors.red.withOpacity(0.6) // Slightly transparent red
    ..style = PaintingStyle.fill;

  WallPainter({
    required this.walls,
    this.currentWall,
    this.selectedWall,
    this.isResizingLeft = false,
    this.isResizingRight = false,
    this.isDragging = false,
    this.snapPosition, // Initialize snapPosition
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawAllWalls(canvas);
    _drawSelectedWall(canvas);
    if (!isDragging && selectedWall != null) {
      _drawMeasurementGuides(canvas, selectedWall!);
    }
    _drawSnapGuide(canvas); // Draw the snap guide if snapPosition is not null
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

  // Draws a visual indicator for the snap position
  void _drawSnapGuide(Canvas canvas) {
    if (snapPosition != null) {
      canvas.drawCircle(snapPosition!, handlerSize / 1.5, _snapPaint); // Draw a small circle at the snap point
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
        oldDelegate.snapPosition != snapPosition; // Repaint if snapPosition changes
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