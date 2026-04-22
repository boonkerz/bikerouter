import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/geocoding_service.dart';

class AddressSearchResult {
  final String displayName;
  final double lat;
  final double lon;

  AddressSearchResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });
}

Future<AddressSearchResult?> showAddressSearch(BuildContext context) {
  return showModalBottomSheet<AddressSearchResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1a1a2e),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => const _AddressSearchSheet(),
  );
}

class _AddressSearchSheet extends StatefulWidget {
  const _AddressSearchSheet();

  @override
  State<_AddressSearchSheet> createState() => _AddressSearchSheetState();
}

class _AddressSearchSheetState extends State<_AddressSearchSheet> {
  final _controller = TextEditingController();
  List<GeocodingResult> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await GeocodingService.search(query);
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 400,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4fc3f7)),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4fc3f7),
                            ),
                          ),
                        )
                      : _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white54),
                              onPressed: () {
                                _controller.clear();
                                setState(() => _results = []);
                              },
                            )
                          : null,
                  filled: true,
                  fillColor: const Color(0xFF222244),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onChanged,
                onSubmitted: _search,
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _controller.text.isEmpty
                            ? l.searchPrompt
                            : l.searchNoResults,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemBuilder: (ctx, i) {
                        final r = _results[i];
                        return ListTile(
                          leading: const Icon(Icons.place, color: Color(0xFF4fc3f7)),
                          title: Text(
                            r.displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.pop(
                              ctx,
                              AddressSearchResult(
                                displayName: r.displayName,
                                lat: r.lat,
                                lon: r.lon,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
