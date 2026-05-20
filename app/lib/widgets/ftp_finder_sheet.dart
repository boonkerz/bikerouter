import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';
import '../services/ftp_route_finder.dart';

class FtpFinderResult {
  final FtpTestCandidate candidate;
  final FtpTestType test;
  const FtpFinderResult({required this.candidate, required this.test});
}

/// Bottom-sheet picker for the FTP test route finder. The user dials in
/// a test type + terrain mode + search radius; the sheet calls
/// [FtpRouteFinder.findCandidates] and renders the top results. Tap a
/// result to commit — the parent screen overlays the polyline on the
/// map.
Future<FtpFinderResult?> showFtpFinderSheet(
  BuildContext context, {
  required LatLng center,
}) {
  return showModalBottomSheet<FtpFinderResult>(
    context: context,
    backgroundColor: const Color(0xFFf5e9d8),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _Sheet(center: center),
  );
}

class _Sheet extends StatefulWidget {
  final LatLng center;
  const _Sheet({required this.center});

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  FtpTestType _test = FtpTestType.twentyMinute;
  FtpRouteMode _mode = FtpRouteMode.either;
  double _radiusKm = 10;
  List<FtpTestCandidate>? _results;
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });
    try {
      final hits = await FtpRouteFinder.findCandidates(
        lat: widget.center.latitude,
        lon: widget.center.longitude,
        radiusKm: _radiusKm,
        test: _test,
        mode: _mode,
      );
      if (!mounted) return;
      setState(() {
        _results = hits;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, sc) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(l.ftpFinderTitle,
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _typePicker(l),
            const SizedBox(height: 8),
            _modePicker(l),
            const SizedBox(height: 8),
            _radiusSlider(l),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Color(0xFFf5e9d8), strokeWidth: 2),
                    )
                  : const Icon(Icons.search, size: 18),
              label: Text(l.ftpFinderSearch),
              onPressed: _loading ? null : _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6a4a28),
                foregroundColor: const Color(0xFFf5e9d8),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
            const Divider(color: Colors.black26, height: 24),
            Expanded(child: _body(sc, l)),
          ],
        ),
      ),
    );
  }

  Widget _typePicker(AppLocalizations l) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: FtpTestType.values
          .map((t) => _chip(_localTestLabel(l, t), t == _test, () {
                setState(() => _test = t);
              }))
          .toList(),
    );
  }

  Widget _modePicker(AppLocalizations l) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: FtpRouteMode.values
          .map((m) => _chip(_localModeLabel(l, m), m == _mode, () {
                setState(() => _mode = m);
              }))
          .toList(),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF6a4a28)
              : const Color(0xFF6a4a28).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? const Color(0xFF6a4a28) : Colors.black26,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFf5e9d8) : const Color(0xFF6a4a28),
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _radiusSlider(AppLocalizations l) {
    return Row(
      children: [
        Text(l.ftpFinderRadius(_radiusKm.round()),
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
        Expanded(
          child: Slider(
            value: _radiusKm,
            min: 2,
            max: 50,
            divisions: 24,
            activeColor: const Color(0xFF6a4a28),
            inactiveColor: Colors.black26,
            onChanged: (v) => setState(() => _radiusKm = v),
          ),
        ),
      ],
    );
  }

  Widget _body(ScrollController sc, AppLocalizations l) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6a4a28)));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.black54)),
      );
    }
    final r = _results;
    if (r == null) {
      return Center(
        child: Text(l.ftpFinderPickToSearch,
            style: const TextStyle(color: Colors.black54)),
      );
    }
    if (r.isEmpty) {
      return Center(
        child: Text(l.ftpFinderEmpty,
            style: const TextStyle(color: Colors.black54)),
      );
    }
    return ListView.separated(
      controller: sc,
      itemCount: r.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Colors.black12, height: 1),
      itemBuilder: (ctx, i) => _resultRow(r[i], l),
    );
  }

  Widget _resultRow(FtpTestCandidate c, AppLocalizations l) {
    final gradStr = c.avgGradientPercent >= 0
        ? '+${c.avgGradientPercent.toStringAsFixed(1)} %'
        : '${c.avgGradientPercent.toStringAsFixed(1)} %';
    final title = c.name ?? l.ftpFinderUnnamed;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF6a4a28),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          c.score.round().toString(),
          style: const TextStyle(
            color: Color(0xFFf5e9d8),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${c.lengthKm.toStringAsFixed(1)} km · $gradStr · ±${c.gradientStdDev.toStringAsFixed(1)} %  ·  ${c.highway}',
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: () =>
          Navigator.pop(context, FtpFinderResult(candidate: c, test: _test)),
    );
  }

  String _localTestLabel(AppLocalizations l, FtpTestType t) {
    switch (t) {
      case FtpTestType.twentyMinute:
        return l.ftpFinderTest20;
      case FtpTestType.eightMinute:
        return l.ftpFinderTest8;
      case FtpTestType.ramp:
        return l.ftpFinderTestRamp;
      case FtpTestType.sweetSpot:
        return l.ftpFinderTestSweetSpot;
    }
  }

  String _localModeLabel(AppLocalizations l, FtpRouteMode m) {
    switch (m) {
      case FtpRouteMode.flat:
        return l.ftpFinderModeFlat;
      case FtpRouteMode.climb:
        return l.ftpFinderModeClimb;
      case FtpRouteMode.either:
        return l.ftpFinderModeEither;
    }
  }
}
