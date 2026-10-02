class FormatUtils {
  static String timeAgo(int timestamp) {
    final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
    final minutes = diff ~/ 60000;
    
    if (minutes < 1) return 'just now';
    if (minutes < 60) return '${minutes}m ago';
    
    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h ago';
    
    final days = hours ~/ 24;
    return '${days}d ago';
  }

  /// Configured resolution durations (hours) — mirrors the backend
  /// DURATION_HOURS so countdowns agree everywhere.
  static const Map<String, int> issueDurationsHours = {
    'accident': 2,
    'fire': 1,
    'congestion': 3,
    'blocked': 4,
    'flooding': 6,
    'pothole': 48,
    'roadwork': 4,
    'other': 4,
  };

  static int durationHoursFor(String type) =>
      issueDurationsHours[type.toLowerCase()] ?? 4;

  /// "5h 42m left" / "47h 12m left" / "Expired". Prefers the backend's
  /// remaining_seconds when the server supplied it.
  static String remainingLabel({int? remainingSeconds, int? createdAtMs, String? type}) {
    int? secs = remainingSeconds;
    secs ??= createdAtMs == null
        ? null
        : ((createdAtMs + durationHoursFor(type ?? '') * 3600000) -
                DateTime.now().millisecondsSinceEpoch) ~/
            1000;
    if (secs == null) return '—';
    if (secs <= 0) return 'Expired';
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    if (h <= 0) return '${m}m left';
    return '${h}h ${m.toString().padLeft(2, '0')}m left';
  }
}
