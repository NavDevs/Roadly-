enum ReportType { accident, roadWork, congestion, blocked }
enum ReportStatus { pending, verified, resolved }

class Report {
  final String id;
  final ReportType type;
  final String description;
  final ReportStatus status;
  final int points;
  final int createdAt;
  final Location location;
  final bool byUser;

  Report({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.points,
    required this.createdAt,
    required this.location,
    required this.byUser,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      type: ReportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReportType.accident,
      ),
      description: json['description'] as String,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      points: json['points'] as int,
      createdAt: json['createdAt'] as int,
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      byUser: json['byUser'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'status': status.name,
      'points': points,
      'createdAt': createdAt,
      'location': location.toJson(),
      'byUser': byUser,
    };
  }
}

class Location {
  final String label;

  Location({required this.label});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(label: json['label'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'label': label};
  }
}
