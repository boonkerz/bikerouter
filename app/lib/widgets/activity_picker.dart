import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/activity.dart';
import '../models/profile.dart';
import '../services/ev_prefs.dart';

/// "Was machst du heute?" grid picker. Two sections in one overlay: the
/// friendly activity presets up top (each configures profile + flags + POI
/// bias in one tap), and every raw BRouter profile below — so power users
/// reach any profile without a separate "advanced" sheet. Per-profile flag
/// tweaking still lives on the map's tune button.
///
/// Returns the chosen [Activity] via the sheet's pop value (null if
/// dismissed); a raw profile pick is delivered through [onProfile] and the
/// sheet closes itself.
Future<Activity?> showActivityPicker(
  BuildContext context, {
  required String currentProfileId,
  required ValueChanged<String> onProfile,
}) {
  return showModalBottomSheet<Activity>(
    context: context,
    backgroundColor: const Color(0xFFf5e9d8),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final l = AppLocalizations.of(ctx);
      final active = Activity.forProfile(currentProfileId);
      final maxHeight = MediaQuery.of(ctx).size.height * 0.85;

      bool activitySelected(Activity a) {
        // Car shares one profile across Auto + E-Auto — tell them apart by the
        // EV pref so the right one highlights.
        if (a.profileId == 'car') {
          return currentProfileId == 'car' && a.ev == EvPrefs.enabled;
        }
        return a.id == active?.id;
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.activityPickerTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2a2014),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.35,
                            children: [
                              for (final a in activities)
                                _Tile(
                                  icon: a.icon,
                                  label: a.localizedName(l),
                                  selected: activitySelected(a),
                                  onTap: () => Navigator.of(ctx).pop(a),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _SectionDivider(label: l.activityPickerAllProfiles),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.35,
                            children: [
                              for (final p in profiles)
                                _Tile(
                                  icon: p.icon,
                                  label: p.localizedName(l),
                                  selected: p.id == currentProfileId,
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    onProfile(p.id);
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.black26)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6a4a28),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.black26)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF6a4a28)
          : const Color(0xFF6a4a28).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFf5e9d8)
                      : const Color(0xFF6a4a28),
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
