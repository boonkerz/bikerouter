import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class PublishRouteDraft {
  final String title;
  final String description;
  const PublishRouteDraft({required this.title, required this.description});
}

Future<PublishRouteDraft?> showPublishRouteDialog(
  BuildContext context, {
  required String suggestedTitle,
}) async {
  final titleCtrl = TextEditingController(text: suggestedTitle);
  final descCtrl = TextEditingController();
  return showDialog<PublishRouteDraft>(
    context: context,
    builder: (ctx) {
      final l = AppLocalizations.of(ctx);
      return AlertDialog(
        title: Text(l.publishTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.publishExplain,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: l.publishNameLabel,
                  hintText: l.publishNameHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                maxLength: 2000,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l.publishDescriptionLabel,
                  hintText: l.publishDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.urlImportCancel),
          ),
          FilledButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.of(ctx).pop(PublishRouteDraft(
                title: title,
                description: descCtrl.text.trim(),
              ));
            },
            child: Text(l.publishConfirm),
          ),
        ],
      );
    },
  );
}
