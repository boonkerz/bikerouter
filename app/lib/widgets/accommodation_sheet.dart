import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/accommodation_service.dart';

Future<Accommodation?> showAccommodationSheet(
  BuildContext context, {
  required double lat,
  required double lon,
  required String anchorLabel,
}) {
  return showModalBottomSheet<Accommodation>(
    context: context,
    backgroundColor: const Color(0xFF1a1a2e),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _Sheet(lat: lat, lon: lon, anchorLabel: anchorLabel),
  );
}

class _Sheet extends StatefulWidget {
  final double lat;
  final double lon;
  final String anchorLabel;

  const _Sheet({required this.lat, required this.lon, required this.anchorLabel});

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  List<Accommodation>? _items;
  bool _loading = false;
  String? _error;
  double _radiusKm = 5;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await AccommodationService.findNear(
        widget.lat,
        widget.lon,
        radiusMeters: _radiusKm * 1000,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(l.accommodationTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.anchorLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _radiusKm,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '${_radiusKm.round()} km',
                    activeColor: const Color(0xFF4fc3f7),
                    onChanged: (v) => setState(() => _radiusKm = v),
                    onChangeEnd: (_) => _fetch(),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('${_radiusKm.round()} km',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),
            Expanded(child: _buildList(sc, l)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ScrollController sc, AppLocalizations l) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4fc3f7)));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)));
    }
    final items = _items;
    if (items == null || items.isEmpty) {
      return Center(
        child: Text(l.accommodationNoResults,
            style: const TextStyle(color: Colors.white54)),
      );
    }
    return ListView.separated(
      controller: sc,
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
      itemBuilder: (ctx, i) {
        final a = items[i];
        final typeLabel = a.localizedType(l);
        return ListTile(
          dense: true,
          leading: Text(a.emoji, style: const TextStyle(fontSize: 20)),
          title: Text(
            a.name ?? typeLabel,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '$typeLabel · ${a.distanceKm.toStringAsFixed(1)} km'
            '${a.stars != null ? ' · ${a.stars}★' : ''}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: a.website != null
              ? IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF4fc3f7)),
                  onPressed: () => _openUrl(a.website!),
                )
              : null,
          onTap: () => Navigator.pop(context, a),
        );
      },
    );
  }
}
