import 'package:flutter/material.dart';
import '../widgets/webgl_viewer.dart';

class ViewerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('3D Viewer')),
      body: WebGLViewer(),
    );
  }
}
