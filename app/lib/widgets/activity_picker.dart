import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/activity.dart';

/// "Was machst du heute?" grid picker. Replaces the bare BRouter-
/// profile list as the primary front door — each tile is an everyday
/// activity, not a routing-engine profile name. Power users still
/// reach raw profiles + flags through the tune button.
///
/// Returns the chosen [Activity] via the sheet's pop value, or null
/// if dismissed. The caller is responsible for applying it (profile +
/// prefs) and the "advanced" escape hatch into the raw profile sheet.
Future<Activity?> showActivityPicker(
  BuildContext context, {
  required String currentProfileId,
  required VoidCallback onAdvanced,
}) {
  return showModalBottomSheet<Activity>(
    context: context,
    backgroundColor: const Color(0xFFf5e9d8),
    // Scroll-controlled so the grid can use up to ~85% of the screen
    // and scroll on small devices instead of overflowing / clipping.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final l = AppLocalizations.of(ctx);
      final active = Activity.forProfile(currentProfileId);
      final maxHeight = MediaQuery.of(ctx).size.height * 0.85;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed drag handle + title so they stay put while the
              // grid below scrolls.
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
                  // Cap the grid width so the tiles stay compact on wide
                  // screens (tablet / web) instead of ballooning to a third
                  // of the viewport; centred on those, full-width on phones.
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        // Flatter than square so all 12 activities fit without
                        // scrolling — wide enough for a two-line label.
                        childAspectRatio: 1.35,
                        children: [
                          for (final a in activities)
                            _ActivityTile(
                              activity: a,
                              selected: a.id == active?.id,
                              label: a.localizedName(l),
                              onTap: () => Navigator.of(ctx).pop(a),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onAdvanced();
                  },
                  icon: const Icon(Icons.tune,
                      size: 18, color: Color(0xFF6a4a28)),
                  label: Text(
                    l.activityPickerAdvanced,
                    style: const TextStyle(color: Color(0xFF6a4a28)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class _ActivityTile extends StatelessWidget {
  final Activity activity;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.activity,
    required this.selected,
    required this.label,
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
              Text(activity.icon, style: const TextStyle(fontSize: 24)),
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
