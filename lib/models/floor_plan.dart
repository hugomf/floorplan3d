import 'dart:ui';

class FloorPlan {
  final List<Offset> lines;

  FloorPlan(this.lines);

  Map<String, dynamic> toJson() => {
        'lines': lines.map((line) => {'x': line.dx, 'y': line.dy}).toList(),
      };

  static FloorPlan fromJson(Map<String, dynamic> json) {
    final lines = (json['lines'] as List)
        .map((point) => Offset(point['x'], point['y']))
        .toList();
    return FloorPlan(lines);
  }
}
