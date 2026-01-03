import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Predefined accent colors for the app
class AccentColors {
  static const List<Color> colors = [
    Color(0xFF6B7FD7), // Purple (default)
    Color(0xFF2196F3), // Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFF44336), // Red
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Deep Purple
    Color(0xFF3F51B5), // Indigo
  ];

  static const List<String> names = [
    'Purple',
    'Blue',
    'Cyan',
    'Teal',
    'Green',
    'Orange',
    'Red',
    'Pink',
    'Deep Purple',
    'Indigo',
  ];
}

/// Supported languages
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  static const system = AppLanguage(
    code: 'system',
    name: 'System',
    nativeName: 'System',
  );

  static const english = AppLanguage(
    code: 'en',
    name: 'English',
    nativeName: 'English',
  );

  static const khmer = AppLanguage(
    code: 'km',
    name: 'Khmer',
    nativeName: 'ភាសាខ្មែរ',
  );

  static const List<AppLanguage> supported = [system, english, khmer];

  Locale? get locale => code == 'system' ? null : Locale(code);
}

/// Settings state
@immutable
class SettingsState {
  final int accentColorIndex;
  final String languageCode;
  final bool isLoading;

  const SettingsState({
    this.accentColorIndex = 0,
    this.languageCode = 'system',
    this.isLoading = true,
  });

  Color get accentColor => AccentColors.colors[accentColorIndex];

  AppLanguage get language => AppLanguage.supported.firstWhere(
    (lang) => lang.code == languageCode,
    orElse: () => AppLanguage.system,
  );

  Locale? get locale => language.locale;

  SettingsState copyWith({
    int? accentColorIndex,
    String? languageCode,
    bool? isLoading,
  }) {
    return SettingsState(
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      languageCode: languageCode ?? this.languageCode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Settings provider
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _accentColorKey = 'accent_color_index';
  static const _languageKey = 'language_code';

  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorIndex = prefs.getInt(_accentColorKey) ?? 0;
      final langCode = prefs.getString(_languageKey) ?? 'system';

      state = state.copyWith(
        accentColorIndex: colorIndex.clamp(0, AccentColors.colors.length - 1),
        languageCode: langCode,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setAccentColor(int index) async {
    if (index < 0 || index >= AccentColors.colors.length) return;

    state = state.copyWith(accentColorIndex: index);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, index);
  }

  Future<void> setLanguage(String code) async {
    final isValid = AppLanguage.supported.any((lang) => lang.code == code);
    if (!isValid) return;

    state = state.copyWith(languageCode: code);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }
}

/// Provider instance
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);
