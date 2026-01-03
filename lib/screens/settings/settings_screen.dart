import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(l10n.theme),
          const SizedBox(height: 8),
          _AccentColorTile(settings: settings, l10n: l10n),
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.preferences),
          const SizedBox(height: 8),
          _LanguageTile(settings: settings, l10n: l10n),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A73E8),
        ),
      ),
    );
  }
}

class _AccentColorTile extends ConsumerWidget {
  final SettingsState settings;
  final AppLocalizations l10n;

  const _AccentColorTile({required this.settings, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: settings.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.palette_outlined, color: settings.accentColor),
        ),
        title: Text(l10n.accentColor),
        subtitle: Text(
          l10n.accentColorDescription,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showColorPicker(context, ref),
      ),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ColorPickerSheet(l10n: l10n),
    );
  }
}

class _ColorPickerSheet extends ConsumerWidget {
  final AppLocalizations l10n;

  const _ColorPickerSheet({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.selectAccentColor,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: AccentColors.colors.length,
            itemBuilder: (context, index) {
              final isSelected = settings.accentColorIndex == index;
              return GestureDetector(
                onTap: () {
                  ref.read(settingsProvider.notifier).setAccentColor(index);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: AccentColors.colors[index],
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AccentColors.colors[index].withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Color names row
          if (settings.accentColorIndex < AccentColors.names.length)
            Center(
              child: Text(
                AccentColors.names[settings.accentColorIndex],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: settings.accentColor,
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  final SettingsState settings;
  final AppLocalizations l10n;

  const _LanguageTile({required this.settings, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: settings.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.language, color: settings.accentColor),
        ),
        title: Text(l10n.language),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: settings.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            settings.language.nativeName,
            style: TextStyle(
              color: settings.accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () => _showLanguagePicker(context, ref),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LanguagePickerSheet(l10n: l10n),
    );
  }
}

class _LanguagePickerSheet extends ConsumerWidget {
  final AppLocalizations l10n;

  const _LanguagePickerSheet({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.selectLanguage,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...AppLanguage.supported.map((language) {
            final isSelected = settings.languageCode == language.code;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? settings.accentColor.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _getLanguageFlag(language.code),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              title: Text(
                language.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: language.code != 'system'
                  ? Text(
                      language.nativeName,
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: settings.accentColor)
                  : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setLanguage(language.code);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getLanguageFlag(String code) {
    switch (code) {
      case 'system':
        return '🌐';
      case 'en':
        return '🇺🇸';
      case 'km':
        return '🇰🇭';
      default:
        return '🌐';
    }
  }
}
