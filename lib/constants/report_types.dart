import 'package:flutter/material.dart';
import '../models/report.dart';

class ReportTypeMeta {
  final ReportType id;
  final String label;
  final String short;
  final int points;
  final Color color;
  final String iconName;

  const ReportTypeMeta({
    required this.id,
    required this.label,
    required this.short,
    required this.points,
    required this.color,
    required this.iconName,
  });
}

class ReportTypes {
  static const List<ReportTypeMeta> types = [
    ReportTypeMeta(
      id: ReportType.accident,
      label: 'Accident',
      short: 'Accident',
      points: 15,
      color: Color(0xFFEF4444),
      iconName: 'alert_octagon',
    ),
    ReportTypeMeta(
      id: ReportType.roadWork,
      label: 'Road Work',
      short: 'Road work',
      points: 10,
      color: Color(0xFFF59E0B),
      iconName: 'tool',
    ),
    ReportTypeMeta(
      id: ReportType.congestion,
      label: 'Congestion',
      short: 'Congestion',
      points: 5,
      color: Color(0xFFEAB308),
      iconName: 'truck',
    ),
    ReportTypeMeta(
      id: ReportType.blocked,
      label: 'Blocked Road',
      short: 'Blocked',
      points: 20,
      color: Color(0xFFDC2626),
      iconName: 'slash',
    ),
  ];

  static ReportTypeMeta getMeta(ReportType type) {
    return types.firstWhere(
      (t) => t.id == type,
      orElse: () => types.first,
    );
  }
}
