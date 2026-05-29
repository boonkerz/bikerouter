import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/bikepacking_prefs.dart';
import '../services/body_weight_prefs.dart';
import '../services/ebike_prefs.dart';
import '../widgets/battery_budget_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _weightKg = BodyWeightPrefs.defaultKg;
  bool _bikepacking = BikepackingPrefs.active;
  int _ebikeCapacityWh = EbikePrefs.capacityWh;

  @override
  void initState() {
    super.initState();
    BodyWeightPrefs.get().then((kg) {
      if (mounted) setState(() => _weightKg = kg);
    });
  }

  Future<void> _editEbikeCapacity() async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: _ebikeCapacityWh.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsEbikeCapacityEdit),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffix: Text('Wh')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.urlImportCancel),
          ),
          FilledButton(
            onPressed: () {
              // 100..2000 Wh is the realistic pedelec range (small
              // city bike up to a long-travel e-MTB with a dual battery).
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v >= 100 && v <= 2000) Navigator.of(ctx).pop(v);
            },
            child: Text(l.recordingSave),
          ),
        ],
      ),
    );
    if (result != null) {
      await EbikePrefs.setCapacityWh(result);
      if (mounted) setState(() => _ebikeCapacityWh = result);
    }
  }

  Future<void> _editWeight() async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: _weightKg.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsBodyWeightEdit),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffix: Text('kg')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.urlImportCancel),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v >= 30 && v <= 200) Navigator.of(ctx).pop(v);
            },
            child: Text(l.recordingSave),
          ),
        ],
      ),
    );
    if (result != null) {
      await BodyWeightPrefs.set(result);
      if (mounted) setState(() => _weightKg = result);
    }
  }

  static const _baseUrl = 'https://wegwiesel.app';
  static const _impressumUrl = '$_baseUrl/legal/impressum.html';
  static const _datenschutzUrl = '$_baseUrl/legal/datenschutz.html';
  static const _feedbackUrl = '$_baseUrl/feedback/';
  static const _supportEmail = 'support@thomas-peterson.de';

  Future<void> _showWildCampDisclaimer() async {
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFf5e9d8),
        title: Text(l.wildCampDisclaimerTitle,
            style: const TextStyle(color: Colors.black87)),
        content: Text(l.wildCampDisclaimerBody,
            style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6a4a28),
              foregroundColor: const Color(0xFFf5e9d8),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.commonOk),
          ),
        ],
      ),
    );
  }

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
      backgroundColor: const Color(0xFFebd9bd),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf5e9d8),
        foregroundColor: Colors.black87,
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
          _sectionHeader(l.settingsSectionPersonal),
          _tile(
            icon: Icons.monitor_weight_outlined,
            title: l.settingsBodyWeight,
            subtitle: '$_weightKg kg',
            onTap: _editWeight,
          ),
          _tile(
            icon: Icons.battery_charging_full,
            title: l.settingsBatteryBudget,
            subtitle: l.settingsBatteryBudgetSub,
            onTap: () => showBatteryBudgetDialog(context),
          ),
          _tile(
            icon: Icons.electric_bike,
            title: l.settingsEbikeCapacity,
            subtitle: '$_ebikeCapacityWh Wh',
            onTap: _editEbikeCapacity,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.local_florist_outlined, color: Color(0xFF6a4a28)),
            title: Text(l.settingsBikepackingMode,
                style: const TextStyle(color: Colors.black87)),
            subtitle: Text(l.settingsBikepackingModeSub,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
            value: _bikepacking,
            activeThumbColor: const Color(0xFF6a4a28),
            onChanged: (v) async {
              setState(() => _bikepacking = v);
              await BikepackingPrefs.setActive(v);
              if (v && !BikepackingPrefs.wildCampDisclaimerSeen && mounted) {
                await _showWildCampDisclaimer();
                await BikepackingPrefs.markWildCampDisclaimerSeen();
              }
            },
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
                color: const Color(0xFFf5e9d8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6a4a28).withValues(alpha: 0.3)),
              ),
              child: Text(
                l.settingsAbout,
                style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
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
          color: Color(0xFF6a4a28),
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
      leading: Icon(icon, color: const Color(0xFF6a4a28)),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12))
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: Colors.black38)
          : null,
      onTap: onTap,
    );
  }
}
