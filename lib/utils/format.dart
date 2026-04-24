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
}
