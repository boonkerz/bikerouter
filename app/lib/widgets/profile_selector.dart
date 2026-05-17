import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/profile.dart';
import '../services/hiking_prefs.dart';
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
      backgroundColor: const Color(0xFFf5e9d8),
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
                        color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ...grouped.entries.expand((entry) => [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          entry.value.first.localizedCategory(l),
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.5),
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
                              style: const TextStyle(color: Colors.black87)),
                          subtitle: Row(
                            children: [
                              Icon(
                                Icons.speed,
                                size: 12,
                                color: override
                                    ? const Color(0xFFffc107)
                                    : Colors.black.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$speed km/h',
                                style: TextStyle(
                                  color: override
                                      ? const Color(0xFFffc107)
                                      : Colors.black.withValues(alpha: 0.45),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.tune, size: 18),
                            color: Colors.black.withValues(alpha: 0.6),
                            tooltip: l.profileSpeedEdit,
                            onPressed: () async {
                              await _showSpeedDialog(ctx, p);
                              setSheetState(() {});
                            },
                          ),
                          selected: p.id == selectedProfile,
                          selectedTileColor: const Color(0xFF6a4a28).withValues(alpha: 0.1),
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
    bool preferHiking = HikingPrefs.preferHikingRoutes;
    HikingPreset preset = HikingPrefs.preset;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFFf5e9d8),
            title: Text('${p.icon} ${p.localizedName(l)}',
                style: const TextStyle(color: Colors.black87)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value km/h',
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
                Text(
                  l.profileSpeedDefault(defaultSpeed),
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.5), fontSize: 11),
                ),
                Slider(
                  value: value.toDouble(),
                  min: 5,
                  max: 40,
                  divisions: 35,
                  activeColor: const Color(0xFF6a4a28),
                  inactiveColor: Colors.black26,
                  onChanged: (v) => setDialogState(() => value = v.round()),
                ),
                if (p.id == 'hiking-beta') ...[
                  const Divider(height: 24, color: Colors.black12),
                  Text(l.hikingPresetTitle,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final option in HikingPreset.values)
                        _PresetChip(
                          label: _presetLabel(l, option),
                          active: preset == option,
                          onTap: () async {
                            setDialogState(() => preset = option);
                            await HikingPrefs.setPreset(option);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.preferHikingRoutesLabel,
                        style: const TextStyle(color: Colors.black87, fontSize: 14)),
                    value: preferHiking,
                    activeThumbColor: const Color(0xFF6a4a28),
                    onChanged: (v) async {
                      setDialogState(() => preferHiking = v);
                      await HikingPrefs.setPreferHikingRoutes(v);
                    },
                  ),
                ],
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
                    style: const TextStyle(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6a4a28),
                  foregroundColor: const Color(0xFFf5e9d8),
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

  String _presetLabel(AppLocalizations l, HikingPreset preset) {
    switch (preset) {
      case HikingPreset.comfortable:
        return l.hikingPresetComfortable;
      case HikingPreset.sporty:
        return l.hikingPresetSporty;
      case HikingPreset.mountain:
        return l.hikingPresetMountain;
    }
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}
