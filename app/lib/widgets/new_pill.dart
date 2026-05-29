import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/new_feature_prefs.dart';

/// Tiny "NEU" / "NEW" pill — paint it next to a UI affordance until
/// the user has interacted with the corresponding [NewFeature]. The
/// parent is responsible for calling [NewFeaturePrefs.markSeen] when
/// the affordance is tapped; this widget only renders.
///
/// Renders an empty SizedBox when the feature isn't fresh, so callers
/// can drop it into a Row unconditionally without layout shifting.
class NewPill extends StatelessWidget {
  final NewFeature feature;

  const NewPill({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    if (!NewFeaturePrefs.isFresh(feature)) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFef6c00),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        l.newPill,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
