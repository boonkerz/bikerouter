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
    // Not used directly as widget anymore, only via showSheet()
    return const SizedBox.shrink();
  }

  void showSheet(BuildContext context) {
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
