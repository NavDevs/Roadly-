enum ReportType { accident, fire, other, roadWork, congestion, blocked, flooding, pothole }
enum ReportStatus { pending, verified, resolved, rejected }

class Report {
  final String id;
  final ReportType type;
  final String description;
  final ReportStatus status;
  final int points;
  final int createdAt;
  final Location location;
  final bool byUser;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final String? lifecycleState; // Response status for citizen display
  final int? remainingSeconds; // Backend-computed countdown (authoritative)
  final String? expiresAt;

  Report({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.points,
    required this.createdAt,
    required this.location,
    required this.byUser,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.lifecycleState,
    this.remainingSeconds,
    this.expiresAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] ?? 'accident').toString();
    final statusRaw = (json['status'] ?? 'pending').toString();
    return Report(
      id: json['id'].toString(),
      type: ReportType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeRaw.toLowerCase(),
        orElse: () => ReportType.accident,
      ),
      description: (json['description'] ?? '').toString(),
      status: ReportStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statusRaw.toLowerCase(),
        orElse: () => ReportStatus.pending,
      ),
      points: int.tryParse('${json['points'] ?? 0}') ?? 0,
      createdAt: json['createdAt'] is int
          ? json['createdAt'] as int
          : (int.tryParse('${json['createdAt'] ?? ''}') ??
              DateTime.now().millisecondsSinceEpoch),
      location: Location.fromJson(
        (json['location'] as Map<String, dynamic>?) ??
            {'label': json['address'] ?? 'Unknown location'},
      ),
      byUser: json['byUser'] == true,
      photoUrl: json['photo_url']?.toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      lifecycleState: json['lifecycle_state']?.toString(),
      remainingSeconds: json['remaining_seconds'] != null
          ? int.tryParse('${json['remaining_seconds']}')
          : null,
      expiresAt: json['expires_at']?.toString(),
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
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'lifecycle_state': lifecycleState,
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
