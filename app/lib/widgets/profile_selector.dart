import 'package:flutter/material.dart';
import '../models/profile.dart';

class ProfileSelector extends StatelessWidget {
  final String selectedProfile;
  final ValueChanged<String> onChanged;

  const ProfileSelector({
    super.key,
    required this.selectedProfile,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick buttons
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: quickProfiles.map((id) {
              final p = profiles.firstWhere((pr) => pr.id == id);
              final selected = selectedProfile == id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(p.name),
                  selected: selected,
                  onSelected: (_) => onChanged(id),
                  selectedColor: const Color(0xFF4fc3f7),
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white70,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  backgroundColor: const Color(0xFF222244),
                  side: BorderSide(
                    color: selected ? const Color(0xFF4fc3f7) : Colors.white24,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              );
            }).toList(),
          ),
        ),
        // "More" button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showProfileSheet(context),
              icon: const Icon(Icons.tune, size: 16, color: Colors.white54),
              label: Text(
                _currentLabel(),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _currentLabel() {
    final p = profiles.where((pr) => pr.id == selectedProfile).firstOrNull;
    if (p == null) return selectedProfile;
    if (quickProfiles.contains(selectedProfile)) return 'Mehr Profile...';
    return '${p.category}: ${p.name}';
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final grouped = <String, List<BikeProfile>>{};
        for (final p in profiles) {
          grouped.putIfAbsent(p.category, () => []).add(p);
        }

        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Center(
              child: Text(
                'Routing-Profil',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            ...grouped.entries.expand((entry) => [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...entry.value.map((p) => ListTile(
                dense: true,
                leading: Text(p.icon, style: const TextStyle(fontSize: 18)),
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                selected: p.id == selectedProfile,
                selectedTileColor: const Color(0xFF4fc3f7).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  onChanged(p.id);
                  Navigator.pop(ctx);
                },
              )),
            ]),
          ],
        );
      },
    );
  }
}
