import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/route_segment.dart';

enum ProfileMode {
  gradient,
  surface,
  highway,
  smoothness,
  maxspeed,
  cost,
}

class ElevationChart extends StatefulWidget {
  final List<List<double>> coordinates;
  final List<RouteSegment> segments;
  final List<List<double>> waypoints; // [lat, lon]
  final ValueChanged<int?>? onHover;

  const ElevationChart({
    super.key,
    required this.coordinates,
    this.segments = const [],
    this.waypoints = const [],
    this.onHover,
  });

  @override
  State<ElevationChart> createState() => _ElevationChartState();
}

class _ElevationChartState extends State<ElevationChart> {
  static const _prefHeightKey = 'elevationChart.height';
  static const _prefModeKey = 'elevationChart.mode';
  static const _minHeight = 120.0;
  static const _maxHeight = 320.0;
  static const _maxPoints = 800;

  double _height = 160;
  ProfileMode _mode = ProfileMode.gradient;
  bool _locked = false;

  // Zoom window expressed as fraction [0, 1] of total distance
  double _zoomStart = 0;
  double _zoomEnd = 1;

  // Pinch state
  double? _pinchStartSpan;
  double _pinchStartZoomStart = 0;
  double _pinchStartZoomEnd = 1;
  double? _panStartLocalX;
  double _panStartZoomStart = 0;
  double _panStartZoomEnd = 1;

  // Hover / tooltip
  int? _hoverIdx;
  Offset? _hoverLocal;

  // Cached precomputed data
  _ProfileData? _cache;
  int _cacheSig = -1;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _height = (p.getDouble(_prefHeightKey) ?? 160).clamp(_minHeight, _maxHeight);
      final modeStr = p.getString(_prefModeKey);
      if (modeStr != null) {
        _mode = ProfileMode.values.firstWhere(
          (m) => m.name == modeStr,
          orElse: () => ProfileMode.gradient,
        );
      }
    });
  }

  Future<void> _saveHeight() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_prefHeightKey, _height);
  }

  Future<void> _saveMode() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefModeKey, _mode.name);
  }

  _ProfileData get _data {
    final sig = Object.hash(
      widget.coordinates.length,
      widget.segments.length,
      widget.coordinates.isEmpty ? 0 : widget.coordinates.first[0],
      widget.coordinates.isEmpty ? 0 : widget.coordinates.last[0],
    );
    if (_cache != null && sig == _cacheSig) return _cache!;
    _cache = _ProfileData.compute(widget.coordinates);
    _cacheSig = sig;
    return _cache!;
  }

  void _updateHover(Offset local, Size size, double axisLeft, double axisBottom) {
    final plotW = size.width - axisLeft;
    final plotH = size.height - axisBottom;
    if (local.dx < axisLeft || local.dx > size.width || local.dy < 0 || local.dy > plotH) {
      if (_hoverIdx != null) {
        setState(() {
          _hoverIdx = null;
          _hoverLocal = null;
        });
        widget.onHover?.call(null);
      }
      return;
    }
    final xRatio = ((local.dx - axisLeft) / plotW).clamp(0.0, 1.0);
    final data = _data;
    final windowStartKm = _zoomStart * data.totalKm;
    final windowEndKm = _zoomEnd * data.totalKm;
    final targetKm = windowStartKm + xRatio * (windowEndKm - windowStartKm);
    // Binary search sampled indices by km
    final idx = _nearestSampleByKm(data, targetKm);
    final origIdx = data.originalIdx[idx];
    setState(() {
      _hoverIdx = origIdx;
      _hoverLocal = local;
    });
    widget.onHover?.call(origIdx);
  }

  int _nearestSampleByKm(_ProfileData d, double km) {
    int lo = 0, hi = d.cumKm.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (d.cumKm[mid] < km) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    if (lo > 0 && (km - d.cumKm[lo - 1]).abs() < (d.cumKm[lo] - km).abs()) {
      return lo - 1;
    }
    return lo;
  }

  void _clearHover() {
    if (_hoverIdx != null) {
      setState(() {
        _hoverIdx = null;
        _hoverLocal = null;
      });
      widget.onHover?.call(null);
    }
  }

  void _zoomAt(double anchorRatio, double factor) {
    if (_locked) return;
    final start = _zoomStart;
    final end = _zoomEnd;
    final span = end - start;
    final anchor = start + anchorRatio * span;
    double newSpan = (span / factor).clamp(0.001, 1.0);
    double newStart = anchor - anchorRatio * newSpan;
    double newEnd = newStart + newSpan;
    if (newStart < 0) {
      newStart = 0;
      newEnd = newSpan;
    }
    if (newEnd > 1) {
      newEnd = 1;
      newStart = 1 - newSpan;
    }
    setState(() {
      _zoomStart = newStart;
      _zoomEnd = newEnd;
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomStart = 0;
      _zoomEnd = 1;
    });
  }

  bool get _isSimplified {
    return widget.coordinates.length > _maxPoints && (_zoomEnd - _zoomStart) > 0.25;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coordinates.length < 2) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final data = _data;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ResizeHandle(
            onDrag: (dy) {
              setState(() {
                _height = (_height - dy).clamp(_minHeight, _maxHeight);
              });
            },
            onEnd: _saveHeight,
          ),
          _ModeBar(
            mode: _mode,
            locked: _locked,
            simplified: _isSimplified,
            canReset: _zoomStart > 0 || _zoomEnd < 1,
            onModeChanged: (m) {
              setState(() => _mode = m);
              _saveMode();
            },
            onToggleLock: () => setState(() => _locked = !_locked),
            onResetZoom: _resetZoom,
          ),
          SizedBox(
            height: _height,
            width: double.infinity,
            child: _ChartArea(
              data: data,
              segments: widget.segments,
              mode: _mode,
              zoomStart: _zoomStart,
              zoomEnd: _zoomEnd,
              waypoints: widget.waypoints,
              hoverIdx: _hoverIdx,
              hoverLocal: _hoverLocal,
              l: l,
              locked: _locked,
              onPointerHover: _updateHover,
              onExit: _clearHover,
              onTap: _updateHover,
              onScroll: (offset, size, axisLeft, axisBottom) {
                final plotW = size.width - axisLeft;
                if (offset.dx < axisLeft) return;
                final ratio = ((offset.dx - axisLeft) / plotW).clamp(0.0, 1.0);
                _zoomAt(ratio, 1.25);
              },
              onScrollOut: (offset, size, axisLeft, axisBottom) {
                final plotW = size.width - axisLeft;
                if (offset.dx < axisLeft) return;
                final ratio = ((offset.dx - axisLeft) / plotW).clamp(0.0, 1.0);
                _zoomAt(ratio, 0.8);
              },
              onPanStart: (details, size, axisLeft) {
                _panStartLocalX = details.localPosition.dx;
                _panStartZoomStart = _zoomStart;
                _panStartZoomEnd = _zoomEnd;
              },
              onPanUpdate: (details, size, axisLeft) {
                if (_locked) return;
                if (_panStartLocalX == null) return;
                final plotW = size.width - axisLeft;
                if (plotW <= 0) return;
                final span = _panStartZoomEnd - _panStartZoomStart;
                if (span >= 1.0) return;
                final dx = details.localPosition.dx - _panStartLocalX!;
                final delta = -dx / plotW * span;
                double ns = _panStartZoomStart + delta;
                double ne = _panStartZoomEnd + delta;
                if (ns < 0) {
                  ns = 0;
                  ne = span;
                }
                if (ne > 1) {
                  ne = 1;
                  ns = 1 - span;
                }
                setState(() {
                  _zoomStart = ns;
                  _zoomEnd = ne;
                });
              },
              onScaleStart: (details, size, axisLeft) {
                _pinchStartSpan = null;
                _pinchStartZoomStart = _zoomStart;
                _pinchStartZoomEnd = _zoomEnd;
              },
              onScaleUpdate: (details, size, axisLeft) {
                if (_locked) return;
                if (details.pointerCount < 2) return;
                final plotW = size.width - axisLeft;
                if (plotW <= 0) return;
                _pinchStartSpan ??= details.horizontalScale;
                final factor = details.horizontalScale;
                if (factor == 0) return;
                final origSpan = _pinchStartZoomEnd - _pinchStartZoomStart;
                double newSpan = (origSpan / factor).clamp(0.001, 1.0);
                final focalRatio = ((details.localFocalPoint.dx - axisLeft) / plotW).clamp(0.0, 1.0);
                final anchor = _pinchStartZoomStart + focalRatio * origSpan;
                double ns = anchor - focalRatio * newSpan;
                double ne = ns + newSpan;
                if (ns < 0) {
                  ns = 0;
                  ne = newSpan;
                }
                if (ne > 1) {
                  ne = 1;
                  ns = 1 - newSpan;
                }
                setState(() {
                  _zoomStart = ns;
                  _zoomEnd = ne;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  final ValueChanged<double> onDrag;
  final VoidCallback onEnd;

  const _ResizeHandle({required this.onDrag, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
        onVerticalDragEnd: (_) => onEnd(),
        child: Container(
          height: 8,
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  final ProfileMode mode;
  final bool locked;
  final bool simplified;
  final bool canReset;
  final ValueChanged<ProfileMode> onModeChanged;
  final VoidCallback onToggleLock;
  final VoidCallback onResetZoom;

  const _ModeBar({
    required this.mode,
    required this.locked,
    required this.simplified,
    required this.canReset,
    required this.onModeChanged,
    required this.onToggleLock,
    required this.onResetZoom,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final modes = <(ProfileMode, IconData, String)>[
      (ProfileMode.gradient, Icons.trending_up, l.profileModeGradient),
      (ProfileMode.surface, Icons.texture, l.profileModeSurface),
      (ProfileMode.highway, Icons.alt_route, l.profileModeHighway),
      (ProfileMode.smoothness, Icons.waves, l.profileModeSmoothness),
      (ProfileMode.maxspeed, Icons.speed, l.profileModeMaxSpeed),
      (ProfileMode.cost, Icons.calculate, l.profileModeCost),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final m in modes)
                    _ModeButton(
                      icon: m.$2,
                      label: m.$3,
                      active: mode == m.$1,
                      onTap: () => onModeChanged(m.$1),
                    ),
                ],
              ),
            ),
          ),
          if (simplified)
            Tooltip(
              message: l.profileSimplifiedWarning,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Colors.amber.withValues(alpha: 0.9),
                ),
              ),
            ),
          if (canReset)
            IconButton(
              tooltip: l.profileZoomReset,
              icon: const Icon(Icons.zoom_out_map, size: 18),
              color: Colors.white.withValues(alpha: 0.7),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onResetZoom,
            ),
          IconButton(
            tooltip: locked ? l.profileZoomLocked : l.profileZoomUnlocked,
            icon: Icon(locked ? Icons.lock : Icons.lock_open, size: 18),
            color: locked
                ? Colors.amber.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.5),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onToggleLock,
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4fc3f7).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? const Color(0xFF4fc3f7) : Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? const Color(0xFF4fc3f7) : Colors.white.withValues(alpha: 0.75),
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartArea extends StatelessWidget {
  final _ProfileData data;
  final List<RouteSegment> segments;
  final ProfileMode mode;
  final double zoomStart;
  final double zoomEnd;
  final List<List<double>> waypoints;
  final int? hoverIdx;
  final Offset? hoverLocal;
  final AppLocalizations l;
  final bool locked;
  final void Function(Offset local, Size size, double axisLeft, double axisBottom) onPointerHover;
  final VoidCallback onExit;
  final void Function(Offset local, Size size, double axisLeft, double axisBottom) onTap;
  final void Function(Offset local, Size size, double axisLeft, double axisBottom) onScroll;
  final void Function(Offset local, Size size, double axisLeft, double axisBottom) onScrollOut;
  final void Function(DragStartDetails, Size, double) onPanStart;
  final void Function(DragUpdateDetails, Size, double) onPanUpdate;
  final void Function(ScaleStartDetails, Size, double) onScaleStart;
  final void Function(ScaleUpdateDetails, Size, double) onScaleUpdate;

  const _ChartArea({
    required this.data,
    required this.segments,
    required this.mode,
    required this.zoomStart,
    required this.zoomEnd,
    required this.waypoints,
    required this.hoverIdx,
    required this.hoverLocal,
    required this.l,
    required this.locked,
    required this.onPointerHover,
    required this.onExit,
    required this.onTap,
    required this.onScroll,
    required this.onScrollOut,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onScaleStart,
    required this.onScaleUpdate,
  });

  static const double _axisLeft = 44;
  static const double _axisBottom = 20;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          onPointerSignal: (e) {
            if (e is PointerScrollEvent) {
              if (e.scrollDelta.dy < 0) {
                onScroll(e.localPosition, size, _axisLeft, _axisBottom);
              } else if (e.scrollDelta.dy > 0) {
                onScrollOut(e.localPosition, size, _axisLeft, _axisBottom);
              }
            }
          },
          child: MouseRegion(
            onHover: (e) => onPointerHover(e.localPosition, size, _axisLeft, _axisBottom),
            onExit: (_) => onExit(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => onTap(d.localPosition, size, _axisLeft, _axisBottom),
              onScaleStart: (d) => onScaleStart(d, size, _axisLeft),
              onScaleUpdate: (d) {
                if (d.pointerCount >= 2) {
                  onScaleUpdate(d, size, _axisLeft);
                } else {
                  // Single-pointer drag: forward as pan
                  final start = DragStartDetails(localPosition: d.localFocalPoint);
                  onPanStart(start, size, _axisLeft);
                  onPanUpdate(
                    DragUpdateDetails(
                      globalPosition: d.focalPoint,
                      localPosition: d.localFocalPoint,
                      delta: d.focalPointDelta,
                    ),
                    size,
                    _axisLeft,
                  );
                }
              },
              child: CustomPaint(
                size: size,
                painter: _ProfilePainter(
                  data: data,
                  segments: segments,
                  mode: mode,
                  zoomStart: zoomStart,
                  zoomEnd: zoomEnd,
                  waypointKm: _waypointKmPositions(),
                  hoverIdx: hoverIdx,
                  hoverLocal: hoverLocal,
                  l: l,
                  axisLeft: _axisLeft,
                  axisBottom: _axisBottom,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Compute each waypoint's cumulative-km position by snapping to the nearest
  /// coordinate on the route.
  List<double> _waypointKmPositions() {
    if (waypoints.isEmpty || data.originalCoords.isEmpty) return const [];
    final out = <double>[];
    for (final w in waypoints) {
      final wlat = w[0];
      final wlon = w[1];
      int best = 0;
      double bestD = double.infinity;
      for (int i = 0; i < data.originalCoords.length; i++) {
        final c = data.originalCoords[i];
        final d = (c[0] - wlon).abs() + (c[1] - wlat).abs();
        if (d < bestD) {
          bestD = d;
          best = i;
        }
      }
      out.add(data.originalCumKm[best]);
    }
    return out;
  }
}

class _ProfilePainter extends CustomPainter {
  final _ProfileData data;
  final List<RouteSegment> segments;
  final ProfileMode mode;
  final double zoomStart;
  final double zoomEnd;
  final List<double> waypointKm;
  final int? hoverIdx;
  final Offset? hoverLocal;
  final AppLocalizations l;
  final double axisLeft;
  final double axisBottom;

  _ProfilePainter({
    required this.data,
    required this.segments,
    required this.mode,
    required this.zoomStart,
    required this.zoomEnd,
    required this.waypointKm,
    required this.hoverIdx,
    required this.hoverLocal,
    required this.l,
    required this.axisLeft,
    required this.axisBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plotRect = Rect.fromLTWH(
      axisLeft,
      0,
      size.width - axisLeft,
      size.height - axisBottom,
    );
    if (plotRect.width <= 0 || plotRect.height <= 0) return;

    final startKm = zoomStart * data.totalKm;
    final endKm = zoomEnd * data.totalKm;
    if (endKm <= startKm) return;

    // Sample visible points for drawing (cap for performance).
    final visIdx = _visibleIndices(startKm, endKm);
    if (visIdx.length < 2) return;

    // Determine Y range (elevation) within the visible window.
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (final i in visIdx) {
      final y = data.elev[i];
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    if (!minY.isFinite || !maxY.isFinite) return;
    final yPad = max(10, (maxY - minY) * 0.15);
    minY -= yPad;
    maxY += yPad;

    // Paint background grid + axes.
    _paintGrid(canvas, plotRect, minY, maxY, startKm, endKm);

    // Build colored segments of the elevation line.
    _paintProfile(canvas, plotRect, visIdx, startKm, endKm, minY, maxY);

    // Waypoint marker ticks at bottom of plot.
    _paintWaypoints(canvas, plotRect, startKm, endKm);

    // Hover crosshair + tooltip.
    if (hoverIdx != null) _paintHover(canvas, size, plotRect, startKm, endKm, minY, maxY);
  }

  List<int> _visibleIndices(double startKm, double endKm) {
    final total = data.cumKm.length;
    if (total == 0) return const [];
    int lo = 0, hi = total - 1;
    // Binary search first >= startKm
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (data.cumKm[mid] < startKm) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final firstIdx = max(0, lo - 1);
    lo = 0;
    hi = total - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (data.cumKm[mid] > endKm) {
        hi = mid - 1;
      } else {
        lo = mid;
      }
    }
    final lastIdx = min(total - 1, lo + 1);
    final range = lastIdx - firstIdx + 1;
    if (range <= 0) return const [];
    const cap = 1200;
    if (range <= cap) {
      return [for (int i = firstIdx; i <= lastIdx; i++) i];
    }
    // Downsample by stride but always include local extrema to preserve shape.
    final stride = (range / cap).ceil();
    final out = <int>[];
    for (int i = firstIdx; i <= lastIdx; i += stride) {
      out.add(i);
    }
    if (out.last != lastIdx) out.add(lastIdx);
    return out;
  }

  double _kmToX(double km, Rect r, double startKm, double endKm) {
    return r.left + (km - startKm) / (endKm - startKm) * r.width;
  }

  double _elevToY(double e, Rect r, double minY, double maxY) {
    return r.bottom - (e - minY) / (maxY - minY) * r.height;
  }

  void _paintGrid(Canvas canvas, Rect r, double minY, double maxY, double startKm, double endKm) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    final yInterval = _niceInterval(maxY - minY, 4);
    final yStart = (minY / yInterval).ceil() * yInterval;
    for (double y = yStart; y < maxY; y += yInterval) {
      final py = _elevToY(y, r, minY, maxY);
      canvas.drawLine(Offset(r.left, py), Offset(r.right, py), gridPaint);
      _drawText(
        canvas,
        '${y.round()} m',
        Offset(r.left - 4, py - 6),
        align: TextAlign.right,
        maxWidth: axisLeft - 4,
        color: Colors.white.withValues(alpha: 0.4),
      );
    }

    final xInterval = _niceInterval(endKm - startKm, 6);
    final xStart = (startKm / xInterval).ceil() * xInterval;
    for (double x = xStart; x < endKm; x += xInterval) {
      final px = _kmToX(x, r, startKm, endKm);
      _drawText(
        canvas,
        '${_fmtKm(x)} km',
        Offset(px - 20, r.bottom + 4),
        align: TextAlign.center,
        maxWidth: 40,
        color: Colors.white.withValues(alpha: 0.4),
      );
    }
  }

  void _paintProfile(
    Canvas canvas,
    Rect r,
    List<int> visIdx,
    double startKm,
    double endKm,
    double minY,
    double maxY,
  ) {
    // Fill under the curve using a neutral blue tint.
    final fillPath = Path();
    fillPath.moveTo(_kmToX(data.cumKm[visIdx.first], r, startKm, endKm), r.bottom);
    for (final i in visIdx) {
      fillPath.lineTo(
        _kmToX(data.cumKm[i], r, startKm, endKm),
        _elevToY(data.elev[i], r, minY, maxY),
      );
    }
    fillPath.lineTo(_kmToX(data.cumKm[visIdx.last], r, startKm, endKm), r.bottom);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );

    // Draw colored segments.
    final linePaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int k = 0; k < visIdx.length - 1; k++) {
      final i0 = visIdx[k];
      final i1 = visIdx[k + 1];
      final x0 = _kmToX(data.cumKm[i0], r, startKm, endKm);
      final x1 = _kmToX(data.cumKm[i1], r, startKm, endKm);
      final y0 = _elevToY(data.elev[i0], r, minY, maxY);
      final y1 = _elevToY(data.elev[i1], r, minY, maxY);
      final color = _colorForSegment(i0, i1);
      linePaint.color = color;
      canvas.drawLine(Offset(x0, y0), Offset(x1, y1), linePaint);
    }
  }

  Color _colorForSegment(int i0, int i1) {
    switch (mode) {
      case ProfileMode.gradient:
        final dEl = data.elev[i1] - data.elev[i0];
        final dKm = (data.cumKm[i1] - data.cumKm[i0]).abs();
        final pct = dKm > 0 ? (dEl / (dKm * 1000)) * 100 : 0;
        return _gradientColor(pct.toDouble());
      case ProfileMode.surface:
        final seg = _segmentAtCoord(data.originalIdx[i0]);
        return seg?.category.color ?? SurfaceCategory.unknown.color;
      case ProfileMode.highway:
        final seg = _segmentAtCoord(data.originalIdx[i0]);
        return seg?.highwayCategory.color ?? HighwayCategory.unknown.color;
      case ProfileMode.smoothness:
        final seg = _segmentAtCoord(data.originalIdx[i0]);
        return seg?.smoothnessCategory.color ?? SmoothnessCategory.unknown.color;
      case ProfileMode.maxspeed:
        final seg = _segmentAtCoord(data.originalIdx[i0]);
        return _maxSpeedColor(seg?.maxSpeedKmh);
      case ProfileMode.cost:
        final seg = _segmentAtCoord(data.originalIdx[i0]);
        return _costColor(seg?.costPerKm ?? 0);
    }
  }

  RouteSegment? _segmentAtCoord(int idx) {
    for (final s in segments) {
      if (idx >= s.startCoordIdx && idx <= s.endCoordIdx) return s;
    }
    return segments.isEmpty ? null : segments.last;
  }

  static Color _gradientColor(double pct) {
    // Green downhill, neutral flat, red uphill. Saturate at ±12%.
    final clamped = pct.clamp(-12.0, 12.0);
    if (clamped >= 0) {
      final t = (clamped / 12.0).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFF4fc3f7), const Color(0xFFD32F2F), t)!;
    } else {
      final t = (-clamped / 12.0).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFF4fc3f7), const Color(0xFF2E7D32), t)!;
    }
  }

  static Color _maxSpeedColor(double? kmh) {
    if (kmh == null) return const Color(0xFF9E9E9E);
    if (kmh <= 20) return const Color(0xFF2E7D32);
    if (kmh <= 30) return const Color(0xFF7CB342);
    if (kmh <= 50) return const Color(0xFFFBC02D);
    if (kmh <= 80) return const Color(0xFFF57C00);
    return const Color(0xFFD32F2F);
  }

  static Color _costColor(double cost) {
    if (cost <= 0) return const Color(0xFF9E9E9E);
    if (cost < 3000) return const Color(0xFF2E7D32);
    if (cost < 6000) return const Color(0xFF7CB342);
    if (cost < 10000) return const Color(0xFFFBC02D);
    if (cost < 20000) return const Color(0xFFF57C00);
    return const Color(0xFFD32F2F);
  }

  void _paintWaypoints(Canvas canvas, Rect r, double startKm, double endKm) {
    if (waypointKm.isEmpty) return;
    final paint = Paint()
      ..color = const Color(0xFFffc107)
      ..style = PaintingStyle.fill;
    for (final km in waypointKm) {
      if (km < startKm || km > endKm) continue;
      final x = _kmToX(km, r, startKm, endKm);
      final p = Path();
      p.moveTo(x, r.bottom);
      p.lineTo(x - 4, r.bottom + 6);
      p.lineTo(x + 4, r.bottom + 6);
      p.close();
      canvas.drawPath(p, paint);
    }
  }

  void _paintHover(Canvas canvas, Size size, Rect r, double startKm, double endKm, double minY, double maxY) {
    final idx = hoverIdx!;
    if (idx >= data.originalCumKm.length) return;
    final km = data.originalCumKm[idx];
    if (km < startKm || km > endKm) return;
    final elev = data.originalCoords[idx][2];
    final x = _kmToX(km, r, startKm, endKm);
    final y = _elevToY(elev, r, minY, maxY);

    // Crosshair
    final chPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), chPaint);

    // Dot
    canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(x, y),
      3,
      Paint()..color = const Color(0xFF4fc3f7),
    );

    // Tooltip
    final seg = _segmentAtCoord(idx);
    final gradientPct = _gradientAtIdx(idx);
    final cumAscent = data.cumAscent[idx];
    final lines = <String>[
      '${l.profileTooltipDistance}: ${_fmtKm(km)} km',
      '${l.profileTooltipElevation}: ${elev.round()} m',
      '${l.profileTooltipGradient}: ${gradientPct >= 0 ? '+' : ''}${gradientPct.toStringAsFixed(1)}%',
      '${l.profileTooltipAscent}: ${cumAscent.round()} m',
      if (seg?.highway != null)
        '${l.profileTooltipHighway}: ${seg!.highwayCategory.localizedLabel(l)}',
      if (seg?.surface != null)
        '${l.profileTooltipSurface}: ${seg!.category.localizedLabel(l)}',
      if (seg?.smoothness != null)
        '${l.profileTooltipSmoothness}: ${seg!.smoothnessCategory.localizedLabel(l)}',
      if (seg?.maxSpeedKmh != null)
        '${l.profileTooltipMaxSpeed}: ${seg!.maxSpeedKmh!.round()} km/h',
    ];
    _paintTooltipBox(canvas, size, Offset(x, y), lines);
  }

  double _gradientAtIdx(int idx) {
    // Compute smoothed gradient over ±100m window.
    final targetKm = data.originalCumKm[idx];
    int lo = idx, hi = idx;
    while (lo > 0 && data.originalCumKm[lo] > targetKm - 0.1) {
      lo--;
    }
    while (hi < data.originalCumKm.length - 1 &&
        data.originalCumKm[hi] < targetKm + 0.1) {
      hi++;
    }
    final dEl = data.originalCoords[hi][2] - data.originalCoords[lo][2];
    final dKm = data.originalCumKm[hi] - data.originalCumKm[lo];
    if (dKm <= 0) return 0;
    return (dEl / (dKm * 1000)) * 100;
  }

  void _paintTooltipBox(Canvas canvas, Size size, Offset anchor, List<String> lines) {
    final tp = <TextPainter>[];
    double maxWidth = 0;
    double totalHeight = 0;
    for (final line in lines) {
      final painter = TextPainter(
        text: TextSpan(
          text: line,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 260);
      tp.add(painter);
      if (painter.width > maxWidth) maxWidth = painter.width;
      totalHeight += painter.height + 2;
    }
    const padH = 8.0;
    const padV = 6.0;
    final boxW = maxWidth + padH * 2;
    final boxH = totalHeight + padV * 2;
    double bx = anchor.dx + 12;
    double by = anchor.dy - boxH - 12;
    if (bx + boxW > size.width - 4) bx = anchor.dx - boxW - 12;
    if (bx < 4) bx = 4;
    if (by < 4) by = anchor.dy + 12;
    if (by + boxH > size.height - 4) by = size.height - boxH - 4;
    if (by < 4) by = 4;

    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(bx, by, boxW, boxH),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      box,
      Paint()..color = const Color(0xFF222244).withValues(alpha: 0.95),
    );
    canvas.drawRRect(
      box,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    double y = by + padV;
    for (final painter in tp) {
      painter.paint(canvas, Offset(bx + padH, y));
      y += painter.height + 2;
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    TextAlign align = TextAlign.left,
    required double maxWidth,
    required Color color,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: maxWidth);
    Offset pos = offset;
    if (align == TextAlign.right) {
      pos = Offset(offset.dx - tp.width, offset.dy);
    } else if (align == TextAlign.center) {
      pos = Offset(offset.dx + (maxWidth - tp.width) / 2, offset.dy);
    }
    tp.paint(canvas, pos);
  }

  String _fmtKm(double km) {
    if (km >= 100) return km.toStringAsFixed(0);
    if (km >= 10) return km.toStringAsFixed(1);
    return km.toStringAsFixed(1);
  }

  double _niceInterval(double range, int targetTicks) {
    if (range <= 0) return 1;
    final rough = range / targetTicks;
    final magnitude = pow(10, (log(rough) / ln10).floor()).toDouble();
    final residual = rough / magnitude;
    if (residual <= 1.5) return magnitude;
    if (residual <= 3) return 2 * magnitude;
    if (residual <= 7) return 5 * magnitude;
    return 10 * magnitude;
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter old) {
    return old.mode != mode ||
        old.zoomStart != zoomStart ||
        old.zoomEnd != zoomEnd ||
        old.hoverIdx != hoverIdx ||
        old.data != data ||
        old.segments != segments ||
        old.waypointKm.length != waypointKm.length;
  }
}

/// Downsampled representation of the route used for plotting, plus full
/// resolution cumulative-km + ascent arrays (for hover/tooltip accuracy).
class _ProfileData {
  final List<List<double>> originalCoords; // [lon, lat, elev]
  final List<double> originalCumKm;
  final List<double> cumAscent;
  // Sampled series (for drawing):
  final List<double> cumKm;
  final List<double> elev;
  final List<int> originalIdx;
  final double totalKm;

  const _ProfileData({
    required this.originalCoords,
    required this.originalCumKm,
    required this.cumAscent,
    required this.cumKm,
    required this.elev,
    required this.originalIdx,
    required this.totalKm,
  });

  static _ProfileData compute(List<List<double>> coords) {
    final origCumKm = List<double>.filled(coords.length, 0);
    final cumAsc = List<double>.filled(coords.length, 0);
    for (int i = 1; i < coords.length; i++) {
      origCumKm[i] = origCumKm[i - 1] + _haversine(coords[i - 1], coords[i]);
      final dEl = coords[i][2] - coords[i - 1][2];
      cumAsc[i] = cumAsc[i - 1] + (dEl > 0 ? dEl : 0);
    }
    final total = coords.isEmpty ? 0.0 : origCumKm.last;

    // Douglas-Peucker-lite: keep first, last, and every coord that passes a
    // minimum distance filter (0.05 km). Always keep local extrema.
    final sampledIdx = <int>[];
    if (coords.isNotEmpty) {
      sampledIdx.add(0);
      double lastKm = 0;
      for (int i = 1; i < coords.length - 1; i++) {
        final d = origCumKm[i];
        if (d - lastKm >= 0.05) {
          sampledIdx.add(i);
          lastKm = d;
        }
      }
      if (coords.length > 1) sampledIdx.add(coords.length - 1);
    }
    return _ProfileData(
      originalCoords: coords,
      originalCumKm: origCumKm,
      cumAscent: cumAsc,
      cumKm: [for (final i in sampledIdx) origCumKm[i]],
      elev: [for (final i in sampledIdx) coords[i][2]],
      originalIdx: sampledIdx,
      totalKm: total,
    );
  }

  static double _haversine(List<double> a, List<double> b) {
    const r = 6371.0;
    final dLat = (b[1] - a[1]) * pi / 180;
    final dLon = (b[0] - a[0]) * pi / 180;
    final lat1 = a[1] * pi / 180;
    final lat2 = b[1] * pi / 180;
    final x = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(x), sqrt(1 - x));
  }
}

