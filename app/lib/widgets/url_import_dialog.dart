import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Prompts for a tour URL and returns the trimmed URL the user typed/pasted,
/// or null if they cancelled. Network fetch is the caller's responsibility.
Future<String?> showUrlImportDialog(BuildContext context) async {
  final controller = TextEditingController();
  final clip = await Clipboard.getData('text/plain');
  final pasted = clip?.text?.trim() ?? '';
  if (pasted.startsWith('http') && pasted.length < 400) {
    controller.text = pasted;
  }
  if (!context.mounted) return null;

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      final l = AppLocalizations.of(ctx);
      return AlertDialog(
        title: Text(l.urlImportTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.urlImportHint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.urlImportCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l.urlImportFetch),
          ),
        ],
      );
    },
  );
}
