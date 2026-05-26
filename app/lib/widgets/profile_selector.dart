import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/profile.dart';
import '../services/hiking_prefs.dart';
import '../services/profile_speed_prefs.dart';
import '../services/routing_prefs.dart';

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

  /// Open the speed + routing-options dialog for a specific profile,
  /// bypassing the profile-picker sheet. Used by the "tune" button next
  /// to the current-profile pill on the map screen.
  ///
  /// Returns `true` when at least one routing-relevant setting was
  /// changed (a routing flag, the hiking preset/waymarked-switch, or
  /// the speed override on a car profile where vmax goes into the
  /// BRouter URL). Callers use this to decide whether to re-run the
  /// route.
  static Future<bool> showOptionsDialog(
      BuildContext context, String profileId) async {
    final p = BikeProfile.byId(profileId);
    if (p == null) return false;
    return await _showSpeedDialogImpl(context, p);
  }

  Future<bool> _showSpeedDialog(BuildContext context, BikeProfile p) =>
      _showSpeedDialogImpl(context, p);

  static Future<bool> _showSpeedDialogImpl(
      BuildContext context, BikeProfile p) async {
    final l = AppLocalizations.of(context);
    int value = ProfileSpeedPrefs.speedFor(p.id);
    final originalSpeed = value;
    final defaultSpeed = ProfileSpeedPrefs.defaultSpeedFor(p.id);
    bool preferHiking = HikingPrefs.preferHikingRoutes;
    HikingPreset preset = HikingPrefs.preset;
    // Tracks whether the user changed anything that affects routing.
    // RoutingFlag toggles, hiking knobs and car-vmax all flip this on.
    bool routingChanged = false;
    final isCar = p.id == 'car' || p.id == 'car-trailer';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        // Fixed dialog width — AlertDialog otherwise shrinks to its
        // content's intrinsic width, which made the hiking sheet (short
        // labels, Wrap of 3 small chips) noticeably narrower than the
        // gravel sheet (long labels in the routing-options accordion).
        final width = (MediaQuery.of(ctx).size.width * 0.85).clamp(280.0, 360.0);
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFFf5e9d8),
            title: Text('${p.icon} ${p.localizedName(l)}',
                style: const TextStyle(color: Colors.black87)),
            content: SizedBox(
              width: width,
              child: Column(
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
                            if (preset != option) routingChanged = true;
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
                      routingChanged = true;
                      setDialogState(() => preferHiking = v);
                      await HikingPrefs.setPreferHikingRoutes(v);
                    },
                  ),
                ],
                _RoutingFlagsSection(
                  profileId: p.id,
                  onChanged: () {
                    routingChanged = true;
                    setDialogState(() {});
                  },
                ),
              ],
              ),
            ),
            actions: [
              if (ProfileSpeedPrefs.hasOverride(p.id))
                TextButton(
                  onPressed: () async {
                    await ProfileSpeedPrefs.clearOverride(p.id);
                    // Speed reset only affects the route on car profiles
                    // (vmax is part of the URL there).
                    if (isCar) routingChanged = true;
                    if (ctx.mounted) Navigator.of(ctx).pop(routingChanged);
                  },
                  child: Text(l.profileSpeedReset,
                      style: const TextStyle(color: Color(0xFFef5350))),
                ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(routingChanged),
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
                  // Car profiles bake speed into the BRouter URL — any
                  // change there warrants a reroute.
                  if (isCar && value != originalSpeed) routingChanged = true;
                  if (ctx.mounted) Navigator.of(ctx).pop(routingChanged);
                },
                child: Text(l.commonSave),
              ),
            ],
          ),
        );
      },
    );
    // Dialog-dismiss-by-barrier returns null; treat as "no change".
    return result ?? false;
  }

  static String _presetLabel(AppLocalizations l, HikingPreset preset) {
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

/// Chips for the 2-4 most useful flags per profile + collapsible
/// accordion with the rest. Renders nothing when the profile exposes
/// no flags (e.g. shortest, mtb-zossebart only has steps/ferries which
/// are surfaced in the accordion).
class _RoutingFlagsSection extends StatefulWidget {
  final String profileId;
  final VoidCallback onChanged;

  const _RoutingFlagsSection({
    required this.profileId,
    required this.onChanged,
  });

  @override
  State<_RoutingFlagsSection> createState() => _RoutingFlagsSectionState();
}

class _RoutingFlagsSectionState extends State<_RoutingFlagsSection> {
  bool _expanded = false;

  // Up to four flags rendered as prominent chips above the accordion.
  // Picked per profile to surface the most-asked-for knobs first.
  static const _quickFlags = <String, List<RoutingFlag>>{
    'car': [RoutingFlag.avoidMotorways, RoutingFlag.avoidToll, RoutingFlag.shortestRoute],
    'car-trailer': [RoutingFlag.avoidMotorways, RoutingFlag.avoidToll, RoutingFlag.avoidUnpaved],
    'fastbike': [RoutingFlag.considerElevation, RoutingFlag.avoidSteepInclines, RoutingFlag.preferQuiet],
    'fastbike-lowtraffic': [RoutingFlag.avoidMainRoads, RoutingFlag.preferCycleRoutes, RoutingFlag.avoidSteepInclines],
    'fastbike-verylowtraffic': [RoutingFlag.avoidPath, RoutingFlag.considerElevation],
    'trekking': [RoutingFlag.avoidMainRoads, RoutingFlag.preferCycleRoutes, RoutingFlag.avoidSteepInclines],
    'safety': [RoutingFlag.avoidMainRoads, RoutingFlag.preferCycleRoutes, RoutingFlag.considerElevation],
    'wegwiesel-ebike': [RoutingFlag.avoidMainRoads, RoutingFlag.preferCycleRoutes, RoutingFlag.avoidSteepInclines],
    'hiking-beta': [RoutingFlag.avoidNaturalPaths, RoutingFlag.avoidFarmTracks],
    'quaelnix-gravel': [RoutingFlag.avoidSteepInclines, RoutingFlag.preferCycleRoutes, RoutingFlag.considerElevation],
    'm11n-gravel': [RoutingFlag.avoidPath, RoutingFlag.considerElevation],
    'cxb-gravel': [RoutingFlag.avoidPath, RoutingFlag.considerElevation],
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = RoutingPrefs.applicableFlagsFor(widget.profileId);
    if (all.isEmpty) return const SizedBox.shrink();

    final quick = (_quickFlags[widget.profileId] ?? const <RoutingFlag>[])
        .where(all.contains)
        .toList();
    final rest = all.where((f) => !quick.contains(f)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, color: Colors.black12),
        Text(l.routingFlagsTitle,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 6),
        if (quick.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in quick)
                _PresetChip(
                  label: _labelFor(l, f),
                  active: RoutingPrefs.flagValue(widget.profileId, f),
                  onTap: () async {
                    final current =
                        RoutingPrefs.flagValue(widget.profileId, f);
                    await RoutingPrefs.setFlag(
                        widget.profileId, f, !current);
                    widget.onChanged();
                    if (mounted) setState(() {});
                  },
                ),
            ],
          ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: const Color(0xFF6a4a28),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _expanded
                        ? l.routingFlagsHideMore
                        : l.routingFlagsShowMore(rest.length),
                    style: const TextStyle(
                      color: Color(0xFF6a4a28),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            for (final f in rest)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(_labelFor(l, f),
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 13)),
                value: RoutingPrefs.flagValue(widget.profileId, f),
                activeThumbColor: const Color(0xFF6a4a28),
                onChanged: (v) async {
                  await RoutingPrefs.setFlag(widget.profileId, f, v);
                  widget.onChanged();
                  if (mounted) setState(() {});
                },
              ),
        ],
      ],
    );
  }

  String _labelFor(AppLocalizations l, RoutingFlag f) {
    switch (f) {
      case RoutingFlag.considerElevation:
        return l.routingFlagLowElevation;
      case RoutingFlag.avoidSteps:
        return l.routingFlagAvoidSteps;
      case RoutingFlag.avoidFerries:
        return l.routingFlagAvoidFerries;
      case RoutingFlag.avoidMainRoads:
        return l.routingFlagAvoidMainRoads;
      case RoutingFlag.preferCycleRoutes:
        return l.routingFlagPreferCycleRoutes;
      case RoutingFlag.preferQuiet:
        return l.routingFlagPreferQuiet;
      case RoutingFlag.preferForest:
        return l.routingFlagPreferForest;
      case RoutingFlag.preferRiver:
        return l.routingFlagPreferRiver;
      case RoutingFlag.avoidTowns:
        return l.routingFlagAvoidTowns;
      case RoutingFlag.considerTraffic:
        return l.routingFlagConsiderTraffic;
      case RoutingFlag.avoidPath:
        return l.routingFlagAvoidPath;
      case RoutingFlag.avoidSteepInclines:
        return l.routingFlagAvoidSteep;
      case RoutingFlag.avoidMotorways:
        return l.routingFlagAvoidMotorways;
      case RoutingFlag.avoidToll:
        return l.routingFlagAvoidToll;
      case RoutingFlag.avoidUnpaved:
        return l.routingFlagAvoidUnpaved;
      case RoutingFlag.shortestRoute:
        return l.routingFlagShortest;
      case RoutingFlag.avoidNaturalPaths:
        return l.routingFlagAvoidNaturalPaths;
      case RoutingFlag.avoidFarmTracks:
        return l.routingFlagAvoidFarmTracks;
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
