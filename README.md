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

### Milestone 8: Wall Merging and Splitting

- Implemented wall merging functionality
- Added wall splitting capability
- Automatic measurement updates during merge/split operations
- Visual indicators for mergeable walls
- Robust collision detection for merge operations

### Milestone 9: Advanced Wall Editing

- Added wall deletion functionality
- Implemented undo/redo system for wall operations
- Improved wall movement precision
- Enhanced selection highlight stability
- Optimized performance for complex floorplans
- Fixed clipping path alignment issues
