import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../l10n/app_localizations.dart';
import '../models/profile.dart';
import '../models/route_result.dart';
import '../services/gpx_import.dart';
import '../services/library_service.dart';

enum _DistFilter { all, short, medium, long }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _loading = true;
  String? _error;
  List<LibraryItem> _items = const [];
  _DistFilter _distFilter = _DistFilter.all;
  String? _profileFilter;
  bool _nearMe = false;
  String _search = '';
  Position? _myPos;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    double? minKm, maxKm;
    switch (_distFilter) {
      case _DistFilter.short:
        maxKm = 30;
        break;
      case _DistFilter.medium:
        minKm = 30;
        maxKm = 80;
        break;
      case _DistFilter.long:
        minKm = 80;
        break;
      case _DistFilter.all:
        break;
    }

    List<double>? bbox;
    if (_nearMe) {
      try {
        _myPos ??= await Geolocator.getCurrentPosition();
        const dLatLon = 0.9; // ≈ 100 km box
        bbox = [
          _myPos!.latitude - dLatLon,
          _myPos!.longitude - dLatLon,
          _myPos!.latitude + dLatLon,
          _myPos!.longitude + dLatLon,
        ];
      } catch (_) {
        // ignore, fall back to no bbox
      }
    }

    try {
      final items = await LibraryService.list(
        profile: _profileFilter,
        minKm: minKm,
        maxKm: maxKm,
        bbox: bbox,
        search: _search.isEmpty ? null : _search,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).libraryLoadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _open(LibraryItem it) async {
    final l = AppLocalizations.of(context);
    final bytes = await LibraryService.fetchGpx(it.code);
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.libraryOpenFailed)),
        );
      }
      return;
    }
    try {
      final result = GpxImport.parse(Uint8List.fromList(bytes));
      if (!mounted) return;
      Navigator.of(context).pop<RouteResult>(result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.libraryOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFebd9bd),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf5e9d8),
        foregroundColor: Colors.black87,
        title: Text(l.libraryTitle),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (v) {
                _search = v.trim();
                _load();
              },
              decoration: InputDecoration(
                hintText: l.librarySearchHint,
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6a4a28)),
                filled: true,
                fillColor: const Color(0xFFf5e9d8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(l.libraryFilterAll, _distFilter == _DistFilter.all,
                    () => _setDist(_DistFilter.all)),
                const SizedBox(width: 6),
                _chip(l.libraryFilterShort, _distFilter == _DistFilter.short,
                    () => _setDist(_DistFilter.short)),
                const SizedBox(width: 6),
                _chip(l.libraryFilterMedium, _distFilter == _DistFilter.medium,
                    () => _setDist(_DistFilter.medium)),
                const SizedBox(width: 6),
                _chip(l.libraryFilterLong, _distFilter == _DistFilter.long,
                    () => _setDist(_DistFilter.long)),
                const SizedBox(width: 12),
                _chip(l.libraryFilterNear, _nearMe, () {
                  setState(() => _nearMe = !_nearMe);
                  _load();
                }),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
          Expanded(child: _body(l)),
        ],
      ),
    );
  }

  Widget _body(AppLocalizations l) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6a4a28)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: Colors.black54)),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l.libraryEmpty,
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.center),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Colors.black12, indent: 64),
        itemBuilder: (ctx, i) {
          final it = _items[i];
          final profileLabel = BikeProfile.byId(it.profile)?.localizedName(l) ??
              it.profile;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6a4a28),
              child: Text(
                BikeProfile.byId(it.profile)?.icon ?? '📍',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            title: Text(
              it.title.isEmpty ? '(no title)' : it.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${it.distanceKm.toStringAsFixed(1)} km · ↑${it.ascent} m · $profileLabel',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF6a4a28)),
            onTap: () => _open(it),
          );
        },
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6a4a28) : const Color(0xFFf5e9d8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF6a4a28) : Colors.black26,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFf5e9d8) : Colors.black87,
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _setDist(_DistFilter f) {
    setState(() => _distFilter = f);
    _load();
  }
}
