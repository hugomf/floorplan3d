import 'dart:typed_data'; // For Float32List
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';

class WebGLViewer extends StatefulWidget {
  @override
  _WebGLViewerState createState() => _WebGLViewerState();
}

class _WebGLViewerState extends State<WebGLViewer> {
  late FlutterGlPlugin glPlugin;
  late dynamic glContext;
  bool isInitialized = false;

  // List of shapes (walls) to draw
  List<Map<String, dynamic>> shapes = [];

  @override
  void initState() {
    print("Iniciando Floorplan designer");
    super.initState();
    initializeFlutterGl();
  }

  Future<void> initializeFlutterGl() async {
    glPlugin = FlutterGlPlugin();
    await glPlugin.initialize(options: {
      "width": 800,
      "height": 600,
      "antialias": true,
      "alpha": true,
    });

    glContext = glPlugin.gl;

    setState(() {
      isInitialized = true;
    });

    setupShaders();
    drawScene();
  }

  late int shaderProgram;
  late int vertexBuffer;

  // Setup shaders for rendering
  void setupShaders() {
    String vertexShaderSource = '''
      attribute vec4 a_position;
      void main() {
        gl_Position = a_position;
      }
    ''';

    String fragmentShaderSource = '''
      precision mediump float;
      uniform vec4 u_color;
      void main() {
        gl_FragColor = u_color;
      }
    ''';

    // Compile vertex shader
    int vertexShader = glContext.createShader(glContext.VERTEX_SHADER);
    glContext.shaderSource(vertexShader, vertexShaderSource);
    glContext.compileShader(vertexShader);

    // Compile fragment shader
    int fragmentShader = glContext.createShader(glContext.FRAGMENT_SHADER);
    glContext.shaderSource(fragmentShader, fragmentShaderSource);
    glContext.compileShader(fragmentShader);

    // Link shaders to create program
    shaderProgram = glContext.createProgram();
    glContext.attachShader(shaderProgram, vertexShader);
    glContext.attachShader(shaderProgram, fragmentShader);
    glContext.linkProgram(shaderProgram);
    glContext.useProgram(shaderProgram);

    // Get attribute and uniform locations
    glContext.getAttribLocation(shaderProgram, "a_position");
    glContext.getUniformLocation(shaderProgram, "u_color");
  }

  // Draw all shapes on the canvas
  void drawScene() {
    glContext.clearColor(1.0, 1.0, 1.0, 1.0); // White background
    glContext.clear(glContext.COLOR_BUFFER_BIT);

    // Loop through each shape and draw it
    for (var shape in shapes) {
      drawRectangle(
        shape["x"],
        shape["y"],
        shape["width"],
        shape["height"],
        shape["color"],
      );
    }
  }

  // Function to draw a rectangle (wall or window)
  void drawRectangle(double x, double y, double width, double height, List<double> color) {
    // Define the rectangle vertices (4 vertices for a rectangle)
    var vertices = [
      x, y,  // Bottom left corner
      x + width, y,  // Bottom right corner
      x, y + height,  // Top left corner
      x + width, y + height,  // Top right corner
    ];

    // Create a buffer for the vertices
    vertexBuffer = glContext.createBuffer();
    glContext.bindBuffer(glContext.ARRAY_BUFFER, vertexBuffer);
    glContext.bufferDataTyped(
      glContext.ARRAY_BUFFER,
      Float32List.fromList(vertices),
      glContext.STATIC_DRAW,
    );

    // Get position attribute location from the shader program
    int position = glContext.getAttribLocation(shaderProgram, "a_position");
    glContext.vertexAttribPointer(position, 2, glContext.FLOAT, false, 0, 0);
    glContext.enableVertexAttribArray(position);

    // Set color using the uniform location
    glContext.uniform4fv(glContext.getUniformLocation(shaderProgram, "u_color"), color);

    // Draw the rectangle (two triangles forming the rectangle)
    glContext.drawArrays(glContext.TRIANGLE_STRIP, 0, 4);  // 4 vertices to form a rectangle
  }


  void onPointerDown(PointerEvent details) {
    final localPosition = details.localPosition;
    print("Pointer clicked at: ${localPosition.dx}, ${localPosition.dy}");
    shapes.add({
      "x": localPosition.dx,
      "y": localPosition.dy,
      "width": 100.0,  
      "height": 50.0,  
      "color": [0.7, 0.4, 0.2, 1.0], 
    });
    drawScene();
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text("WebGL Viewer")),
      body: Listener(
        onPointerDown: onPointerDown,  
        child: Container(
          width: 800,
          height: 600,
          color: Colors.black,
          child: Texture(
            textureId: glPlugin.textureId!,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    glPlugin.dispose();
    super.dispose();
  }
}
