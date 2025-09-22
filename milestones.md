# Floorplan Designer App

## Getting Started

### Prerequisites

- Flutter SDK installed (version 3.0.0 or higher)
- Android Studio or VS Code with Flutter/Dart plugins
- Chrome browser (for web development)

### Running on Windows

1. Open terminal in project directory
2. Run `flutter pub get` to install dependencies
3. Connect an Android device or start an emulator
4. Run `flutter run` to launch on Android
5. For desktop: `flutter run -d windows`

### Running on macOS

1. Open terminal in project directory  
2. Run `flutter pub get` to install dependencies
3. For iOS: Connect iPhone or start simulator, then run `flutter run`
4. For macOS desktop: `flutter run -d macos`

### Running in Chrome

1. Ensure Chrome is installed
2. Run `flutter pub get` to install dependencies
3. Run `flutter run -d chrome`
4. The app will automatically open in Chrome

### Troubleshooting

- If you get "No devices found", ensure:
  - For Android: USB debugging is enabled
  - For iOS: Xcode is properly configured
  - For web: Chrome is installed and updated
- Run `flutter doctor` to diagnose any setup issues
- Ensure Flutter channel is stable: `flutter channel stable`

---

## Milestones Overview

This section outlines the key features and functionality added in each milestone of the Floorplan Designer App.

### Milestone 1: Basic Wall Drawing

- Initial implementation of wall drawing functionality
- Basic gesture recognition for wall creation
- Simple wall rendering with black lines
- Basic grid background for reference

### Milestone 2: Measurement Guides

- Added measurement guides above and below walls
- Real-time length display in pixels
- Guide lines extend beyond wall endpoints
- Measurement text automatically orients correctly

### Milestone 3: Diagonal Patterns

- Added diagonal pattern fill within walls
- Patterns clipped to wall boundaries
- Real-time pattern rendering for walls in progress
- Subtle blue-grey color scheme for patterns

### Milestone 4: Wall Selection

- Implemented wall selection capability
- Selected walls highlighted in blue
- Selection handles at wall endpoints
- Tap detection with 10px tolerance

### Milestone 5: Measurement Arrows

- Added arrow indicators to measurement guides
- Directional arrows at guide endpoints
- Improved measurement text visibility
- Consistent blue-grey color scheme

### Milestone 6: Enhanced Selection

- Smaller 5px selection handles
- Visual feedback during selection
- Maintained measurement guides while selected
- Improved selection detection algorithm

### Milestone 7: Wall Manipulation

- Added wall movement capability
- Implemented wall resizing via endpoint handles
- Smooth translation of wall positions
- Real-time measurement updates during manipulation
- Robust gesture handling for different operations

### Milestone 8: Wall Merging

- Implemented wall merging functionality
- Combined multiple walls into single paths
- Improved wall selection and manipulation
- Wall handlers for resizing
- Gesture handling for drawing, moving and resizing walls

### Milestone 9: Dragging Improvements

- Enhanced wall dragging with visual feedback
- Improved wall selection highlighting
- Measurement guides hide during dragging
- Wall handlers hide during dragging
- Merged wall path rendering
- Background grid with left margin
- Diagonal pattern fill for walls

### Milestone 10: Dragging Improvements

- Added Snap-to-Grid and Wall-Endpoint Logic
I implemented a new snapping feature to improve the precision of drawing. This functionality is handled in a private method, _snapPoint, within the WallDrawingController. When active, this method modifies a drag or tap position to align with either the nearest grid line or the endpoint of an existing wall.
- Introduced a Toggleable Snap Feature
- Added Visual Feedback for Snapping
To provide a clear visual cue to the user, the WallPainter now draws a small red circle at the snapPosition when snapping is active and the user is interacting with the canvas. This lets the user know exactly where the wall or handler has been snapped to.


### Milestone 11: Toolbar Position and Snap Tool

## 1. Toolbar Position Persistence 💾
- **Added `shared_preferences` dependency**  
  Used for storing small amounts of data locally on the device.

- **Implemented `_loadToolbarPosition()`**  
  Asynchronous method called in `initState` to retrieve saved `toolbar_x` and `toolbar_y` values from `SharedPreferences`.  
  If values exist, `_toolbarLocalPosition` is updated, repositioning the toolbar.

- **Implemented `_saveToolbarPosition(Offset position)`**  
  Asynchronous method invoked within `onDragEnd` of the `Draggable` widget.  
  Saves the new `dx` and `dy` coordinates to `SharedPreferences`.

- **Modified `Draggable`'s `onDragEnd`**  
  The existing `setState` now also calls `_saveToolbarPosition` to persist the updated coordinates.

## 2. Minor Refinements in Previous Version
*(for clarity in comparison)*  
While less significant than the persistence feature, the “Prev File” contained small adjustments that were refined in the “Current File”:

- **`_snapPoint` Logic**  
  Snapping calculations improved to correctly determine the closest snap point, including better handling of grid and endpoint snapping.

- **`onPanStart` & `onPanUpdate` with Snapping**  
  Updated in `WallDrawingController` to integrate `_snapPoint` more robustly, ensuring snapped positions are used when snapping is enabled.

- **`_resetInteractionState()`**  
  Now also clears `_snapPosition` when resetting interaction states, guaranteeing a clean slate after gestures end.

&gt; These changes collectively enhance UX by enabling personalized toolbar placement and delivering smoother snapping behavior.


### Milestone 12

  - Kept the removal of the `const` modifier from the `WallPainter` constructor to resolve the build error caused by non-final fields (`_cachedWallPath`, `_lastWallCount`, `_lastCurrentWallStart`, `_lastCurrentWallEnd`).
  - Maintained the `InteractionState` enum for clearer state management.
  - Retained the undo functionality for wall creation, deletion, and clearing.
  - Kept accessibility support with `Semantics` for toolbar buttons.
  - Preserved relative toolbar coordinates for screen rotation handling.
  - Maintained validation of `SharedPreferences` values and prevention of zero-length walls during resizing.
  - Replaced boolean flags (_isResizingLeft, _isResizingRight, _isDraggingWall) with an InteractionState enum (none, resizingLeft, resizingRight, draggingWall, drawing) in WallDrawingController. This improves state management clarity and prevents invalid state combinations.
  - Added Semantics widgets to toolbar buttons (delete, clear, undo, snap toggle) with appropriate labels for screen reader support, enhancing inclusivity
  - Relative Toolbar Coordinates
  - Prevent Zero-Length Walls
  - SharedPreferences Validation
  - Grouped Constants
  - Prevent Toolbar Overlap with AppBar



### Milestone 13
- 3D View Toggle - New button in the toolbar with a 3D icon
- Simple 3D Renderer - Custom painter that projects your 2D walls into 3D space
- Interactive 3D View - Drag to rotate around the scene
- Ground Grid - Visual reference grid on the floor plane