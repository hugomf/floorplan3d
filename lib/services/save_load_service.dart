import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/floor_plan.dart';

class SaveLoadService {
  Future<void> savePlan(FloorPlan plan) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/floor_plan.json');
    await file.writeAsString(jsonEncode(plan.toJson()));
  }

  Future<FloorPlan?> loadPlan() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/floor_plan.json');
    if (!file.existsSync()) return null;
    final json = jsonDecode(await file.readAsString());
    return FloorPlan.fromJson(json);
  }
}
