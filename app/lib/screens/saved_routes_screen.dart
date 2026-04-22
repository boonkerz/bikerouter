import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/profile.dart';
import '../models/saved_route.dart';
import '../services/route_storage.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  List<SavedRoute> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final routes = await RouteStorage.loadAll();
    if (!mounted) return;
    setState(() {
      _routes = routes;
      _loading = false;
    });
  }

  Future<void> _delete(SavedRoute r) async {
    await RouteStorage.delete(r.id);
    await _load();
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        title: Text(l.savedRoutesTitle),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4fc3f7)))
          : _routes.isEmpty
              ? _emptyState(l)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _routes.length,
                  itemBuilder: (ctx, i) => _routeTile(_routes[i], l),
                ),
    );
  }

  Widget _emptyState(AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border, color: Colors.white30, size: 64),
            const SizedBox(height: 16),
            Text(
              l.savedRoutesEmpty,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeTile(SavedRoute r, AppLocalizations l) {
    final profile = BikeProfile.byId(r.profile);
    final profileName = profile != null ? profile.localizedName(l) : r.profile;
    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade800,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1a1a2e),
            title: Text(l.savedRoutesDeleteConfirm, style: const TextStyle(color: Colors.white)),
            content: Text('„${r.name}"',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.commonDelete, style: const TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _delete(r),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Icon(
            r.isRoundtrip ? Icons.loop : Icons.timeline,
            color: const Color(0xFF4fc3f7),
          ),
          title: Text(r.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.distanceKm.toStringAsFixed(1)} km · ${_formatDuration(r.durationSeconds)} · ${r.ascent} hm',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '$profileName · ${_formatDate(r.createdAt)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white30),
          onTap: () => Navigator.pop(context, r),
        ),
      ),
    );
  }
}
