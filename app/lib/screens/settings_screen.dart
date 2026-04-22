import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _baseUrl = 'https://wegwiesel.app';
  static const _impressumUrl = '$_baseUrl/legal/impressum.html';
  static const _datenschutzUrl = '$_baseUrl/legal/datenschutz.html';
  static const _feedbackUrl = '$_baseUrl/feedback/';
  static const _supportEmail = 'support@thomas-peterson.de';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMail() async {
    final uri = Uri(scheme: 'mailto', path: _supportEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        title: Text(l.settingsTitle),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _sectionHeader(l.settingsSectionLegal),
          _tile(
            icon: Icons.info_outline,
            title: l.settingsImpressum,
            onTap: () => _openUrl(_impressumUrl),
          ),
          _tile(
            icon: Icons.privacy_tip_outlined,
            title: l.settingsPrivacy,
            onTap: () => _openUrl(_datenschutzUrl),
          ),
          _sectionHeader(l.settingsSectionFeedback),
          _tile(
            icon: Icons.lightbulb_outline,
            title: l.settingsFeedbackForm,
            subtitle: l.settingsFeedbackFormSub,
            onTap: () => _openUrl(_feedbackUrl),
          ),
          _tile(
            icon: Icons.mail_outline,
            title: l.settingsContactMail,
            subtitle: _supportEmail,
            onTap: _openMail,
          ),
          _sectionHeader(l.settingsSectionAbout),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData
                  ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                  : '…';
              return _tile(
                icon: Icons.tag,
                title: l.settingsVersion,
                subtitle: version,
              );
            },
          ),
          _tile(
            icon: Icons.description_outlined,
            title: l.settingsLicenses,
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Wegwiesel',
              applicationLegalese: l.settingsLegalese,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4fc3f7).withValues(alpha: 0.3)),
              ),
              child: Text(
                l.settingsAbout,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4fc3f7),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4fc3f7)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: Colors.white30)
          : null,
      onTap: onTap,
    );
  }
}
