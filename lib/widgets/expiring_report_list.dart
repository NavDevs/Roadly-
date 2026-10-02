import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/report.dart';
import 'report_card.dart';

/// Recent-reports list whose items gracefully animate OUT the moment their
/// server-side TTL ends: the card fades and collapses in place, then leaves
/// the list — no countdown, no flash. A report that becomes live again
/// (re-opened by an admin) animates back in.
class ExpiringReportList extends StatefulWidget {
  final List<Report> reports;

  const ExpiringReportList({super.key, required this.reports});

  @override
  State<ExpiringReportList> createState() => _ExpiringReportListState();
}

class _ExpiringReportListState extends State<ExpiringReportList> {
  late List<Report> _shown;
  final Set<String> _exiting = {};

  @override
  void initState() {
    super.initState();
    _shown = List.of(widget.reports);
  }

  @override
  void didUpdateWidget(ExpiringReportList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.reports;
    final liveIds = incoming.map((r) => r.id).toSet();

    // Reports that left the live set start their exit; ones that came back
    // cancel theirs (e.g. an incident re-activated on the dashboard).
    _exiting.removeWhere(liveIds.contains);
    _exiting.addAll(_shown
        .where((r) => !liveIds.contains(r.id))
        .map((r) => r.id));

    final incomingById = {for (final r in incoming) r.id: r};
    final next = <Report>[];
    for (final old in _shown) {
      if (liveIds.contains(old.id)) {
        // Survivor: slot kept, content refreshed (description, lifecycle...).
        next.add(incomingById[old.id] ?? old);
      } else if (_exiting.contains(old.id)) {
        // Expiring: stays until its collapse animation finishes.
        next.add(old);
      }
    }
    // Brand-new reports enter at their position within the live list
    // (newest first) — exiting cards don't block the insertion.
    for (var i = 0; i < incoming.length; i++) {
      final r = incoming[i];
      if (_shown.any((e) => e.id == r.id)) continue;
      var at = next.length;
      for (var j = 0; j < next.length; j++) {
        final liveIdx = incoming.indexWhere((e) => e.id == next[j].id);
        if (liveIdx > i) {
          at = j;
          break;
        }
      }
      next.insert(at, r);
    }

    _shown = next;
    setState(() {});
  }

  void _finishExit(String id) {
    if (!_exiting.remove(id)) return;
    setState(() => _shown.removeWhere((r) => r.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final r in _shown)
          _ExitTile(
            key: ValueKey(r.id),
            report: r,
            exiting: _exiting.contains(r.id),
            onExited: () => _finishExit(r.id),
          ),
      ],
    );
  }
}

/// One report card with a reversible fade+collapse animation, keyed by report
/// id so its state (and entrance animation) survives list reordering.
class _ExitTile extends StatefulWidget {
  final Report report;
  final bool exiting;
  final VoidCallback onExited;

  const _ExitTile({
    super.key,
    required this.report,
    required this.exiting,
    required this.onExited,
  });

  @override
  State<_ExitTile> createState() => _ExitTileState();
}

class _ExitTileState extends State<_ExitTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );
  late bool _wasExiting;

  @override
  void initState() {
    super.initState();
    _wasExiting = widget.exiting;
    if (_wasExiting) _c.value = 0;
    _c.addListener(_handleTick);
  }

  void _handleTick() {
    if (widget.exiting && _c.value == 0.0) widget.onExited();
  }

  @override
  void didUpdateWidget(_ExitTile old) {
    super.didUpdateWidget(old);
    if (widget.exiting && !_wasExiting) {
      _c.reverse();
    } else if (!widget.exiting && _wasExiting && _c.value < 1) {
      _c.forward();
    }
    _wasExiting = widget.exiting;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: curved,
        child: ReportCard(report: widget.report)
            .animate()
            .fade(duration: 350.ms, curve: Curves.easeOut)
            .slideY(
                begin: 0.08,
                end: 0,
                duration: 350.ms,
                curve: Curves.easeOutQuad),
      ),
    );
  }
}
