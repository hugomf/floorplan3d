import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

// Add this to pubspec.yaml dependencies:
// cube: ^0.1.1

// === Constants ===
// Wall Properties
const double pixelsPerMeter = 20.0;
const double wallHeight = 10.0;
const double minWallDistance = 5.0;
const double wall3DHeight = 3.0; // Height in meters for 3D view

// Interaction Tolerances
const double handlerSize = 5.0;
const double handlerTolerance = 10.0;
const double wallSelectionTolerance = 10.0;
const double snapTolerance = 10.0;

// Grid and Guides
const double gridSpacing = 20.0;
const double diagonalSpacing = 6.0;
const double guideSeparation = 10.0;
const double guideExtension = 5.0;

// UI Elements
const double marginOffset = 40.0;
const double marginWidth = 2.0;

void main() {
  runApp(
    const MaterialApp(
      home: WallDrawingTool(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

// === Data Models ===
/// Represents a wall defined by its start and end points.
class Wall {
  Offset start;
  Offset end;

  Wall(this.start, this.end);

  Offset get center => (start + end) / 2;
  Offset get vector => end - start;
  double get length => vector.distance;
  double get angle => vector.direction;
}

// === Simple 3D Renderer ===
class Simple3DRenderer {
  static String generateWalls3D(List<Wall> walls) {
    if (walls.isEmpty) return '';
    
    final buffer = StringBuffer();
    
    // Add vertices and faces for each wall
    int vertexOffset = 0;
    for (int i = 0; i < walls.length; i++) {
      final wall = walls[i];
      
      // Convert to meters and center around origin
      final startX = (wall.start.dx - 200) / pixelsPerMeter;
      final startZ = (wall.start.dy - 200) / pixelsPerMeter;
      final endX = (wall.end.dx - 200) / pixelsPerMeter;
      final endZ = (wall.end.dy - 200) / pixelsPerMeter;
      
      // Create 8 vertices for a wall (rectangular prism)
      final vertices = [
        '$startX 0 $startZ',           // 0: bottom-start
        '$endX 0 $endZ',               // 1: bottom-end
        '$endX $wall3DHeight $endZ',   // 2: top-end
        '$startX $wall3DHeight $startZ', // 3: top-start
      ];
      
      for (final vertex in vertices) {
        buffer.writeln('v $vertex');
      }
      
      // Add faces (using 1-based indexing for OBJ format)
      final baseIndex = vertexOffset + 1;
      
      // Front face
      buffer.writeln('f $baseIndex ${baseIndex + 1} ${baseIndex + 2} ${baseIndex + 3}');
      // Back face (if needed for thickness)
      
      vertexOffset += 4;
    }
    
    return buffer.toString();
  }
}

// === Simple 3D View Widget ===
class Simple3DView extends StatefulWidget {
  final List<Wall> walls;
  
  const Simple3DView({super.key, required this.walls});
  
  @override
  State<Simple3DView> createState() => _Simple3DViewState();
}

class _Simple3DViewState extends State<Simple3DView> {
  double _rotationY = 0.0;
  double _rotationX = -0.3;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: widget.walls.isEmpty 
        ? const Center(
            child: Text(
              'No walls to display\nDraw some walls in 2D view',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          )
        : GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rotationY += details.delta.dx * 0.01;
                _rotationX += details.delta.dy * 0.01;
                _rotationX = _rotationX.clamp(-1.5, 1.5);
              });
            },
            child: CustomPaint(
              painter: Simple3DPainter(
                walls: widget.walls,
                rotationX: _rotationX,
                rotationY: _rotationY,
              ),
              size: Size.infinite,
            ),
          ),
    );
  }
}

class Simple3DPainter extends CustomPainter {
  final List<Wall> walls;
  final double rotationX;
  final double rotationY;
  
  Simple3DPainter({
    required this.walls,
    required this.rotationX,
    required this.rotationY,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (walls.isEmpty) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final scale = 10.0;
    
    final wallPaint = Paint()
      ..color = Colors.blue[300]!
      ..style = PaintingStyle.fill;
      
    final edgePaint = Paint()
      ..color = Colors.blue[800]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Draw each wall as a 3D rectangular prism
    for (final wall in walls) {
      final startX = (wall.start.dx - 200) / pixelsPerMeter;
      final startZ = (wall.start.dy - 200) / pixelsPerMeter;
      final endX = (wall.end.dx - 200) / pixelsPerMeter;
      final endZ = (wall.end.dy - 200) / pixelsPerMeter;
      
      // Define 8 vertices of the wall box
      final vertices3D = [
        Vector3(startX, 0, startZ),           // 0: bottom-start
        Vector3(endX, 0, endZ),               // 1: bottom-end
        Vector3(endX, wall3DHeight, endZ),    // 2: top-end
        Vector3(startX, wall3DHeight, startZ), // 3: top-start
      ];
      
      // Project 3D vertices to 2D screen coordinates
      final vertices2D = vertices3D.map((v3d) {
        final rotated = _rotatePoint(v3d);
        return Offset(
          center.dx + rotated.x * scale,
          center.dy - rotated.y * scale + rotated.z * scale * 0.5,
        );
      }).toList();
      
      // Draw the wall faces
      final wallPath = Path()
        ..moveTo(vertices2D[0].dx, vertices2D[0].dy)
        ..lineTo(vertices2D[1].dx, vertices2D[1].dy)
        ..lineTo(vertices2D[2].dx, vertices2D[2].dy)
        ..lineTo(vertices2D[3].dx, vertices2D[3].dy)
        ..close();
      
      canvas.drawPath(wallPath, wallPaint);
      canvas.drawPath(wallPath, edgePaint);
      
      // Draw bottom edge
      canvas.drawLine(vertices2D[0], vertices2D[1], edgePaint);
    }
    
    // Draw ground plane grid
    _drawGroundGrid(canvas, center, scale);
  }
  
  Vector3 _rotatePoint(Vector3 point) {
    // Rotate around Y axis
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    final rotatedY = Vector3(
      point.x * cosY - point.z * sinY,
      point.y,
      point.x * sinY + point.z * cosY,
    );
    
    // Rotate around X axis
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);
    return Vector3(
      rotatedY.x,
      rotatedY.y * cosX - rotatedY.z * sinX,
      rotatedY.y * sinX + rotatedY.z * cosX,
    );
  }
  
  void _drawGroundGrid(Canvas canvas, Offset center, double scale) {
    final gridPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 0.5;
    
    const gridSize = 10;
    const gridSpacing = 1.0;
    
    for (int i = -gridSize; i <= gridSize; i++) {
      // Grid lines parallel to X axis
      final start3D = Vector3(i * gridSpacing, 0, -gridSize * gridSpacing);
      final end3D = Vector3(i * gridSpacing, 0, gridSize * gridSpacing);
      
      final start2D = _project3DTo2D(start3D, center, scale);
      final end2D = _project3DTo2D(end3D, center, scale);
      
      canvas.drawLine(start2D, end2D, gridPaint);
      
      // Grid lines parallel to Z axis
      final start3D2 = Vector3(-gridSize * gridSpacing, 0, i * gridSpacing);
      final end3D2 = Vector3(gridSize * gridSpacing, 0, i * gridSpacing);
      
      final start2D2 = _project3DTo2D(start3D2, center, scale);
      final end2D2 = _project3DTo2D(end3D2, center, scale);
      
      canvas.drawLine(start2D2, end2D2, gridPaint);
    }
  }
  
  Offset _project3DTo2D(Vector3 point3D, Offset center, double scale) {
    final rotated = _rotatePoint(point3D);
    return Offset(
      center.dx + rotated.x * scale,
      center.dy - rotated.y * scale + rotated.z * scale * 0.5,
    );
  }
  
  @override
  bool shouldRepaint(covariant Simple3DPainter oldDelegate) {
    return oldDelegate.walls.length != walls.length ||
           oldDelegate.rotationX != rotationX ||
           oldDelegate.rotationY != rotationY;
  }
}

// Simple Vector3 class
class Vector3 {
  final double x, y, z;
  
  Vector3(this.x, this.y, this.z);
}

// === Wall Utility for Transformations ===
class WallUtils {
  /// Creates a transformation matrix for the wall centered at its midpoint with its rotation.
  static Matrix4 getTransform(Wall wall) {
    return Matrix4.identity()
      ..translate(wall.center.dx, wall.center.dy)
      ..rotateZ(wall.angle);
  }

  /// Creates a rectangular path for the wall, transformed to its position and angle.
  static Path createWallPath(Wall wall) {
    final path = Path();
    final rect = Rect.fromLTWH(-wall.length / 2, -wallHeight / 2, wall.length, wallHeight);
    path.addRect(rect);
    return path.transform(getTransform(wall).storage);
  }

  /// Gets the position of the left or right handler for resizing the wall.
  static Offset getHandlerPosition(Wall wall, {required bool isLeft}) {
    final handlerOffset = Offset(isLeft ? -wall.length / 2 : wall.length / 2, 0);
    return MatrixUtils.transformPoint(getTransform(wall), handlerOffset);
  }
}

// === Controller for State Management ===
enum InteractionState { none, resizingLeft, resizingRight, draggingWall, drawing }

class WallDrawingController extends ChangeNotifier {
  // === State Variables ===
  final List<Wall> _walls = [];
  final List<List<Wall>> _undoStack = [];
  static const int maxUndoSteps = 10;
  Offset? _startPoint;
  Offset? _endPoint;
  Wall? _selectedWall;
  Offset? _dragStartPoint;
  InteractionState _interactionState = InteractionState.none;
  Offset? _snapPosition;
  bool _isSnapEnabled = false;
  bool _is3DViewVisible = false; // New state for 3D view

  // === Getters for state access ===
  List<Wall> get walls => _walls;
  Wall? get currentWall => (_startPoint != null && _endPoint != null) ? Wall(_startPoint!, _endPoint!) : null;
  Wall? get selectedWall => _selectedWall;
  bool get isResizingLeft => _interactionState == InteractionState.resizingLeft;
  bool get isResizingRight => _interactionState == InteractionState.resizingRight;
  bool get isDraggingWall => _interactionState == InteractionState.draggingWall;
  bool get isDrawing => _interactionState == InteractionState.drawing;
  Offset? get snapPosition => _snapPosition;
  bool get isSnapEnabled => _isSnapEnabled;
  bool get is3DViewVisible => _is3DViewVisible;

  /// Toggles between 2D and 3D view
  void toggle3DView() {
    _is3DViewVisible = !_is3DViewVisible;
    notifyListeners();
  }

  /// Handles tap down to select a wall at the given position.
  void onTapDown(Offset tapPosition) {
    _selectedWall = _findWallAtPosition(tapPosition);
    _resetInteractionState();
    notifyListeners();
  }

  /// Starts a new interaction (drawing, resizing, or dragging) based on the tap position.
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

  /// Updates the current interaction (drawing, resizing, or dragging) with the new position.
  void onPanUpdate(Offset currentPosition) {
    Offset snappedPosition = _isSnapEnabled ? _snapPoint(currentPosition) : currentPosition;
    _snapPosition = _isSnapEnabled ? snappedPosition : null;

    if (_selectedWall != null) {
      switch (_interactionState) {
        case InteractionState.resizingLeft:
          if ((snappedPosition - _selectedWall!.end).distance > minWallDistance) {
            _selectedWall!.start = snappedPosition;
          }
          break;
        case InteractionState.resizingRight:
          if ((snappedPosition - _selectedWall!.start).distance > minWallDistance) {
            _selectedWall!.end = snappedPosition;
          }
          break;
        case InteractionState.draggingWall:
          _moveSelectedWall(currentPosition);
          break;
        default:
          break;
      }
    } else if (_startPoint != null) {
      _interactionState = InteractionState.drawing;
      _endPoint = snappedPosition;
    }
    notifyListeners();
  }

  /// Completes the current interaction, finalizing a new wall if applicable.
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

  /// Deletes the selected wall and saves the state for undo.
  void deleteSelectedWall() {
    if (_selectedWall != null) {
      _saveStateForUndo();
      _walls.remove(_selectedWall);
      _selectedWall = null;
      notifyListeners();
    }
  }

  /// Clears all walls and saves the state for undo.
  void clearAllWalls() {
    if (_walls.isNotEmpty) {
      _saveStateForUndo();
      _walls.clear();
      _selectedWall = null;
      notifyListeners();
    }
  }

  /// Undoes the last wall modification (creation, deletion, or clear).
  void undo() {
    if (_undoStack.isNotEmpty) {
      _walls.clear();
      _walls.addAll(_undoStack.removeLast());
      _selectedWall = null;
      notifyListeners();
    }
  }

  /// Toggles snapping to grid and wall endpoints.
  void toggleSnap() {
    _isSnapEnabled = !_isSnapEnabled;
    notifyListeners();
  }

  // === Private Helper Methods ===
  /// Finds the wall at the given position, if any.
  Wall? _findWallAtPosition(Offset position) {
    for (var wall in _walls) {
      if (_isPointOnWall(position, wall)) {
        return wall;
      }
    }
    return null;
  }

  /// Checks if the tap is on a handler and starts resizing if so.
  bool _checkAndStartResizing(Offset tapPosition) {
    final leftHandler = WallUtils.getHandlerPosition(_selectedWall!, isLeft: true);
    final rightHandler = WallUtils.getHandlerPosition(_selectedWall!, isLeft: false);

    if ((tapPosition - leftHandler).distance < handlerTolerance) {
      _interactionState = InteractionState.resizingLeft;
      _dragStartPoint = tapPosition;
      return true;
    } else if ((tapPosition - rightHandler).distance < handlerTolerance) {
      _interactionState = InteractionState.resizingRight;
      _dragStartPoint = tapPosition;
      return true;
    }
    return false;
  }

  /// Checks if the tap is on the wall and starts dragging if so.
  bool _checkAndStartDragging(Offset tapPosition) {
    if (_isPointOnWall(tapPosition, _selectedWall!)) {
      _dragStartPoint = tapPosition;
      _interactionState = InteractionState.draggingWall;
      return true;
    }
    return false;
  }

  /// Starts drawing a new wall at the given position.
  void _startDrawingNewWall(Offset position) {
    _startPoint = position;
    _endPoint = position;
    _selectedWall = null;
  }

  /// Moves the selected wall by the delta between the current and drag start positions.
  void _moveSelectedWall(Offset currentPosition) {
    final delta = currentPosition - _dragStartPoint!;
    _selectedWall!.start += delta;
    _selectedWall!.end += delta;
    _dragStartPoint = currentPosition;
  }

  /// Finalizes a new wall if it meets the minimum distance requirement.
  void _finishDrawingWall() {
    final distance = (_endPoint! - _startPoint!).distance;
    if (distance > minWallDistance) {
      _saveStateForUndo();
      _walls.add(Wall(_startPoint!, _endPoint!));
    }
  }

  /// Resets the interaction state to none.
  void _resetInteractionState() {
    _dragStartPoint = null;
    _interactionState = InteractionState.none;
  }

  /// Saves the current wall state to the undo stack.
  void _saveStateForUndo() {
    _undoStack.add([..._walls.map((w) => Wall(w.start, w.end))]);
    if (_undoStack.length > maxUndoSteps) {
      _undoStack.removeAt(0);
    }
  }

  /// Determines if a point is on a wall within the selection tolerance.
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

  /// Snaps a point to the grid or wall endpoints if snapping is enabled.
  Offset _snapPoint(Offset position) {
    if (!_isSnapEnabled) return position;

    Offset snappedPoint = _snapToGrid(position);
    if ((snappedPoint - position).distance < snapTolerance) return snappedPoint;

    snappedPoint = _snapToWallEndpoints(position);
    return snappedPoint != position ? snappedPoint : position;
  }

  /// Snaps a point to the nearest grid intersection.
  Offset _snapToGrid(Offset position) {
    final snappedX = (position.dx / gridSpacing).round() * gridSpacing;
    final snappedY = (position.dy / gridSpacing).round() * gridSpacing;
    return Offset(snappedX, snappedY);
  }

  /// Snaps a point to the nearest wall endpoint, if within tolerance.
  Offset _snapToWallEndpoints(Offset position) {
    for (final wall in _walls) {
      for (final endpoint in [wall.start, wall.end]) {
        if ((position - endpoint).distance < snapTolerance) {
          return endpoint;
        }
      }
    }
    return position;
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
      final stackRenderBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (stackRenderBox != null) {
        _loadToolbarPosition(stackRenderBox.size);
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Loads the toolbar position from SharedPreferences, using relative coordinates.
  Future<void> _loadToolbarPosition(Size stackSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? xPercent = prefs.getDouble('toolbar_x_percent');
      final double? yPercent = prefs.getDouble('toolbar_y_percent');
      if (xPercent != null && yPercent != null && xPercent.isFinite && yPercent.isFinite) {
        final newX = (xPercent * stackSize.width).clamp(0.0, stackSize.width - 80.0);
        final newY = (yPercent * stackSize.height).clamp(0.0, stackSize.height - 120.0);
        if (newX != _toolbarLocalPosition.dx || newY != _toolbarLocalPosition.dy) {
          setState(() {
            _toolbarLocalPosition = Offset(newX, newY);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading toolbar position: $e');
    }
  }

  /// Saves the toolbar position to SharedPreferences using relative coordinates.
  Future<void> _saveToolbarPosition(Offset position, Size stackSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('toolbar_x_percent', position.dx / stackSize.width);
      await prefs.setDouble('toolbar_y_percent', position.dy / stackSize.height);
    } catch (e) {
      debugPrint('Error saving toolbar position: $e');
    }
  }

  /// Handles keyboard events for deleting walls.
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
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return _controller.is3DViewVisible
                      ? Simple3DView(walls: _controller.walls)
                      : _build2DView();
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
                        _controller.is3DViewVisible
                            ? 'Drag to rotate 3D view'
                            : (_controller.selectedWall != null
                                ? 'Selected wall - Drag to move or resize. Press Delete to remove.'
                                : 'Tap and drag to create walls'),
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
                    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
                    final clampedX = localOffset.dx.clamp(0.0, stackSize.width - 80.0);
                    final clampedY = localOffset.dy.clamp(appBarHeight, stackSize.height - 160.0);

                    setState(() {
                      _toolbarLocalPosition = Offset(clampedX, clampedY);
                      _saveToolbarPosition(_toolbarLocalPosition, stackSize);
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

  Widget _build2DView() {
    return Stack(
      children: [
        const BackgroundGrid(),
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
            child: Semantics(
              label: _controller.selectedWall != null
                  ? 'Wall selected. Length: ${(_controller.selectedWall!.length / pixelsPerMeter).toStringAsFixed(2)} meters.'
                  : 'Canvas with ${_controller.walls.length} walls. Tap and drag to create a new wall.',
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
        ),
      ],
    );
  }

  /// Builds the draggable toolbar with action buttons.
  Widget _buildToolbar() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isSnapEnabled = _controller.isSnapEnabled;
        final is3DView = _controller.is3DViewVisible;
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
              // 3D View Toggle
              Semantics(
                button: true,
                label: 'Toggle 3D view (${is3DView ? 'On' : 'Off'})',
                child: IconButton(
                  icon: Icon(
                    Icons.view_in_ar,
                    color: is3DView ? Colors.green : Colors.black,
                  ),
                  onPressed: _controller.toggle3DView,
                  tooltip: 'Toggle 3D view',
                ),
              ),
              const Divider(height: 10, color: Colors.grey),
              // Delete selected wall
              Semantics(
                button: true,
                label: 'Delete selected wall',
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: is3DView ? null : _controller.deleteSelectedWall,
                  tooltip: 'Delete selected wall',
                ),
              ),
              const Divider(height: 10, color: Colors.grey),
              // Clear all walls
              Semantics(
                button: true,
                label: 'Clear all walls',
                child: IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.blueGrey),
                  onPressed: _controller.clearAllWalls,
                  tooltip: 'Clear all walls',
                ),
              ),
              const Divider(height: 10, color: Colors.grey),
              // Undo
              Semantics(
                button: true,
                label: 'Undo last action',
                child: IconButton(
                  icon: const Icon(Icons.undo, color: Colors.blue),
                  onPressed: is3DView ? null : _controller.undo,
                  tooltip: 'Undo last action',
                ),
              ),
              const Divider(height: 10, color: Colors.grey),
              // Snap toggle
              Semantics(
                button: true,
                label: 'Toggle snapping (${isSnapEnabled ? 'On' : 'Off'})',
                child: IconButton(
                  icon: Icon(
                    isSnapEnabled ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: isSnapEnabled ? Colors.green : Colors.black,
                  ),
                  onPressed: is3DView ? null : _controller.toggleSnap,
                  tooltip: 'Toggle snapping (${isSnapEnabled ? 'On' : 'Off'})',
                ),
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

  Path? _cachedWallPath;
  int _lastWallCount = 0;
  Offset? _lastCurrentWallStart;
  Offset? _lastCurrentWallEnd;

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

  WallPainter({
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

  /// Draws all walls and the current wall being drawn, merging overlapping paths.
  void _drawAllWalls(Canvas canvas) {
    if (_cachedWallPath == null ||
        _lastWallCount != walls.length ||
        (currentWall != null &&
            (_lastCurrentWallStart != currentWall!.start ||
                _lastCurrentWallEnd != currentWall!.end))) {
      if (walls.isEmpty && currentWall == null) {
        _cachedWallPath = Path();
      } else {
        _cachedWallPath = Path();
        for (final wall in walls) {
          final wallPath = WallUtils.createWallPath(wall);
          _cachedWallPath = Path.combine(PathOperation.union, _cachedWallPath!, wallPath);
        }
        if (currentWall != null) {
          final currentWallPath = WallUtils.createWallPath(currentWall!);
          _cachedWallPath = Path.combine(PathOperation.union, _cachedWallPath!, currentWallPath);
        }
      }
      _lastWallCount = walls.length;
      _lastCurrentWallStart = currentWall?.start;
      _lastCurrentWallEnd = currentWall?.end;
    }
    if (_cachedWallPath!.getBounds().isEmpty) return;
    canvas.drawPath(_cachedWallPath!, _wallPaint);
  }

  /// Draws the selected wall with handlers.
  void _drawSelectedWall(Canvas canvas) {
    if (selectedWall == null) return;

    final selectedPath = WallUtils.createWallPath(selectedWall!);
    canvas.drawPath(selectedPath, _selectedPaint);

    if (!isDragging) {
      _drawHandlers(canvas, selectedWall!);
    }
  }

  /// Draws resize handlers for the selected wall.
  void _drawHandlers(Canvas canvas, Wall wall) {
    final leftHandler = WallUtils.getHandlerPosition(wall, isLeft: true);
    final rightHandler = WallUtils.getHandlerPosition(wall, isLeft: false);
    _drawHandler(canvas, leftHandler);
    _drawHandler(canvas, rightHandler);
  }

  /// Draws a single handler at the given position.
  void _drawHandler(Canvas canvas, Offset position) {
    final rect = Rect.fromCenter(center: position, width: handlerSize, height: handlerSize);
    canvas.drawRect(rect, _handlerPaint);
  }

  /// Draws measurement guides and text for the selected wall.
  void _drawMeasurementGuides(Canvas canvas, Wall wall) {
    canvas.save();
    canvas.translate(wall.center.dx, wall.center.dy);
    canvas.rotate(wall.angle);

    final guidePaint = Paint()
      ..color = Colors.blueGrey.shade700
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _drawGuideLines(canvas, wall.length, guidePaint);
    _drawMeasurementText(canvas, wall);

    canvas.restore();
  }

  /// Draws guide lines above and below the wall.
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

  /// Draws measurement text above and below the wall.
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

  /// Draws text at the specified position, handling upside-down text.
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

  /// Draws a vertical line with arrows for measurement guides.
  void _drawVerticalLineWithArrow(
      Canvas canvas, double x, double y, double arrowSize, Paint paint, {required bool isStart}) {
    canvas.drawLine(Offset(x, y - arrowSize), Offset(x, y + arrowSize), paint);
    if (isStart) {
      canvas.drawLine(Offset(x, y), Offset(x + arrowSize, y - arrowSize), paint);
      canvas.drawLine(Offset(x, y), Offset(x + arrowSize, y + arrowSize), paint);
    } else {
      canvas.drawLine(Offset(x - arrowSize, y - arrowSize), Offset(x, y), paint);
      canvas.drawLine(Offset(x - arrowSize, y + arrowSize), Offset(x, y), paint);
    }
  }

  /// Draws a visual indicator for the snap position.
  void _drawSnapGuide(Canvas canvas) {
    if (isSnapEnabled && snapPosition != null) {
      canvas.drawCircle(snapPosition!, handlerSize, _snapPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WallPainter oldDelegate) {
    return oldDelegate.walls.length != walls.length ||
        oldDelegate.currentWall?.start != currentWall?.start ||
        oldDelegate.currentWall?.end != currentWall?.end ||
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
    ..color = Colors.red
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