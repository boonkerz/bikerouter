import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/profile.dart';
import '../services/profile_speed_prefs.dart';

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
    return const SizedBox.shrink();
  }

  void showSheet(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final grouped = <ProfileCategory, List<BikeProfile>>{};
            for (final p in profiles) {
              grouped.putIfAbsent(p.category, () => []).add(p);
            }

            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Text(
                    l.profileTitle,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ...grouped.entries.expand((entry) => [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          entry.value.first.localizedCategory(l),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...entry.value.map((p) {
                        final speed = ProfileSpeedPrefs.speedFor(p.id);
                        final override = ProfileSpeedPrefs.hasOverride(p.id);
                        return ListTile(
                          dense: true,
                          leading: Text(p.icon, style: const TextStyle(fontSize: 18)),
                          title: Text(p.localizedName(l),
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Row(
                            children: [
                              Icon(
                                Icons.speed,
                                size: 12,
                                color: override
                                    ? const Color(0xFFffc107)
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$speed km/h',
                                style: TextStyle(
                                  color: override
                                      ? const Color(0xFFffc107)
                                      : Colors.white.withValues(alpha: 0.45),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.tune, size: 18),
                            color: Colors.white.withValues(alpha: 0.6),
                            tooltip: l.profileSpeedEdit,
                            onPressed: () async {
                              await _showSpeedDialog(ctx, p);
                              setSheetState(() {});
                            },
                          ),
                          selected: p.id == selectedProfile,
                          selectedTileColor: const Color(0xFF4fc3f7).withValues(alpha: 0.1),
                          shape:
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onTap: () {
                            onChanged(p.id);
                            Navigator.pop(ctx);
                          },
                        );
                      }),
                    ]),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSpeedDialog(BuildContext context, BikeProfile p) async {
    final l = AppLocalizations.of(context);
    int value = ProfileSpeedPrefs.speedFor(p.id);
    final defaultSpeed = ProfileSpeedPrefs.defaultSpeedFor(p.id);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF1a1a2e),
            title: Text('${p.icon} ${p.localizedName(l)}',
                style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value km/h',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                Text(
                  l.profileSpeedDefault(defaultSpeed),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                ),
                Slider(
                  value: value.toDouble(),
                  min: 5,
                  max: 40,
                  divisions: 35,
                  activeColor: const Color(0xFF4fc3f7),
                  inactiveColor: Colors.white24,
                  onChanged: (v) => setDialogState(() => value = v.round()),
                ),
              ],
            ),
            actions: [
              if (ProfileSpeedPrefs.hasOverride(p.id))
                TextButton(
                  onPressed: () async {
                    await ProfileSpeedPrefs.clearOverride(p.id);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(l.profileSpeedReset,
                      style: const TextStyle(color: Color(0xFFef5350))),
                ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l.commonCancel,
                    style: const TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4fc3f7),
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  if (value == defaultSpeed) {
                    await ProfileSpeedPrefs.clearOverride(p.id);
                  } else {
                    await ProfileSpeedPrefs.setOverride(p.id, value);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: Text(l.commonSave),
              ),
            ],
          ),
        );
      },
    );
  }
}
