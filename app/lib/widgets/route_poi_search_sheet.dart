import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/route_poi.dart';
import '../services/poi_image_resolver.dart';
import '../services/route_poi_search_service.dart';

const List<PoiCategory> _availableCategories = [
  PoiCategory.fuel,
  PoiCategory.charging,
  PoiCategory.shop,
  PoiCategory.sights,
  PoiCategory.food,
  PoiCategory.water,
  PoiCategory.scenic,
  PoiCategory.shelter,
  PoiCategory.picnic,
  PoiCategory.camping,
  PoiCategory.station,
];

Future<List<RoutePoiHit>?> showRoutePoiSearchSheet(
  BuildContext context, {
  required List<List<double>> coordinates,
}) {
  return showModalBottomSheet<List<RoutePoiHit>>(
    context: context,
    backgroundColor: const Color(0xFFf5e9d8),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _Sheet(coordinates: coordinates),
  );
}

class _Sheet extends StatefulWidget {
  final List<List<double>> coordinates;

  const _Sheet({required this.coordinates});

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  // Default to all searchable categories — easier UX than guessing the
  // "right" subset per profile. Users uncheck what they don't want; the
  // per-category Overpass calls are batched into one query so the cost
  // of "everything on" is small.
  late final Set<PoiCategory> _selected = _availableCategories.toSet();
  List<RoutePoiHit>? _hits;
  bool _loading = false;
  String? _error;
  final Set<String> _picked = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  String _hitKey(RoutePoiHit h) => '${h.osmType}/${h.osmId}';

  Future<void> _fetch() async {
    if (_selected.isEmpty) {
      setState(() {
        _hits = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hits = await RoutePoiSearchService.searchAlongRoute(
        coordinates: widget.coordinates,
        categories: _selected,
      );
      if (!mounted) return;
      setState(() {
        _hits = hits;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).commonError;
        _loading = false;
      });
    }
  }

  void _toggleCategory(PoiCategory cat) {
    setState(() {
      if (_selected.contains(cat)) {
        _selected.remove(cat);
      } else {
        _selected.add(cat);
      }
    });
    _fetch();
  }

  void _close() {
    if (_picked.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final selected = (_hits ?? const <RoutePoiHit>[])
        .where((h) => _picked.contains(_hitKey(h)))
        .toList();
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            children: [
              _header(l),
              _categoryChips(),
              const Divider(height: 1, color: Colors.black12),
              Expanded(child: _body(l)),
              _footer(l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.routePoiSearchTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2a2014),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF6a4a28)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

  Widget _categoryChips() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _availableCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _availableCategories[i];
          final active = _selected.contains(cat);
          return Center(
            child: FilterChip(
              avatar: Icon(cat.icon,
                  size: 18,
                  color: active
                      ? const Color(0xFFf5e9d8)
                      : const Color(0xFF6a4a28)),
              label: Text(cat.localizedLabel(AppLocalizations.of(context))),
              selected: active,
              onSelected: (_) => _toggleCategory(cat),
              selectedColor: const Color(0xFF6a4a28),
              backgroundColor: const Color(0xFFe8d5b8),
              labelStyle: TextStyle(
                color: active
                    ? const Color(0xFFf5e9d8)
                    : const Color(0xFF2a2014),
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: active
                      ? const Color(0xFF6a4a28)
                      : Colors.black26,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _body(AppLocalizations l) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6a4a28)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              style: const TextStyle(color: Colors.black54)),
        ),
      );
    }
    final hits = _hits ?? const <RoutePoiHit>[];
    if (hits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _selected.isEmpty
                ? l.routePoiSearchPickCategories
                : l.routePoiSearchEmpty,
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: hits.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Colors.black12, indent: 60),
      itemBuilder: (ctx, i) {
        final h = hits[i];
        final key = _hitKey(h);
        final picked = _picked.contains(key);
        final kmText = h.routeKm < 10
            ? h.routeKm.toStringAsFixed(1)
            : h.routeKm.toStringAsFixed(0);
        // Prefer the service-resolved URL (covers image=, wikimedia_commons=
        // and the Wikipedia PageImages fallback). Falls back to a fresh
        // sync-resolve for hits constructed outside the service.
        final imageUrl = h.imageUrl ?? PoiImageResolver.resolve(h.tags);
        return ListTile(
          leading: imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      // Falls Wikimedia 404 / Redirect-Loop bringt, fallen
                      // wir auf das normale Category-Icon zurück.
                      errorBuilder: (_, __, ___) => CircleAvatar(
                        backgroundColor:
                            h.category.color.withValues(alpha: 0.2),
                        child: Icon(h.category.icon,
                            color: h.category.color, size: 20),
                      ),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return CircleAvatar(
                          backgroundColor:
                              h.category.color.withValues(alpha: 0.2),
                          child: Icon(h.category.icon,
                              color: h.category.color, size: 20),
                        );
                      },
                    ),
                  ),
                )
              : CircleAvatar(
                  backgroundColor: h.category.color.withValues(alpha: 0.2),
                  child: Icon(h.category.icon, color: h.category.color, size: 20),
                ),
          title: Text(
            h.name ?? h.category.localizedLabel(l),
            style: const TextStyle(
              color: Color(0xFF2a2014),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${l.routePoiSearchAt(kmText)} · ${l.routePoiSearchSide(h.sideMeters.round())}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          trailing: IconButton(
            icon: Icon(
              picked ? Icons.check_circle : Icons.add_circle_outline,
              color: const Color(0xFF6a4a28),
            ),
            onPressed: () {
              setState(() {
                if (picked) {
                  _picked.remove(key);
                } else {
                  _picked.add(key);
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _footer(AppLocalizations l) {
    if (_picked.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: FilledButton.icon(
          icon: const Icon(Icons.add_location_alt),
          label: Text('${l.routePoiSearchAdd} (${_picked.length})'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6a4a28),
            foregroundColor: const Color(0xFFf5e9d8),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _close,
        ),
      ),
    );
  }
}
