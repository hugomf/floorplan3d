import 'package:flutter/material.dart';
import '../widgets/grid_canvas.dart';
import '../services/save_load_service.dart';
import '../models/floor_plan.dart';

class DrawingScreen extends StatelessWidget {
  final SaveLoadService saveLoadService = SaveLoadService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Draw Floor Plan'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              // Example: Save lines from the canvas (implement fetching drawn lines)
              final plan = FloorPlan([]);
              await saveLoadService.savePlan(plan);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Floor plan saved!')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.folder_open),
            onPressed: () async {
              final plan = await saveLoadService.loadPlan();
              if (plan != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Floor plan loaded!')),
                );
                // TODO: Load lines into the canvas
              }
            },
          ),
        ],
      ),
      body: GridCanvas(),
    );
  }
}
