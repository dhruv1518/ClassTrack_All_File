import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized theme provider for ClassTrack.
/// Manages independent light/dark mode toggles for student and admin panels.
class ThemeProvider extends ChangeNotifier {
  static const String _studentKey = 'isStudentDarkMode';
  static const String _adminKey = 'isAdminDarkMode';

  bool _isStudentDarkMode = false;
  bool _isAdminDarkMode = false;
  String _currentPanel = 'student'; // 'student' or 'admin'

  /// Returns the dark-mode state for the currently active panel.
  bool get isDarkMode =>
      _currentPanel == 'admin' ? _isAdminDarkMode : _isStudentDarkMode;

  ThemeProvider() {
    _loadFromPrefs();
  }

  /// Call this when navigating into a panel so the provider knows
  /// which dark-mode flag to use.
  void setPanel(String panel) {
    if (_currentPanel != panel) {
      _currentPanel = panel;
      notifyListeners();
    }
  }

  void toggleDarkMode() {
    if (_currentPanel == 'admin') {
      _isAdminDarkMode = !_isAdminDarkMode;
    } else {
      _isStudentDarkMode = !_isStudentDarkMode;
    }
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isStudentDarkMode = prefs.getBool(_studentKey) ?? false;
    _isAdminDarkMode = prefs.getBool(_adminKey) ?? false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_studentKey, _isStudentDarkMode);
    await prefs.setBool(_adminKey, _isAdminDarkMode);
  }

  // ────────────────────────────────────────────
  //  LIGHT PALETTE  (current app — unchanged)
  // ────────────────────────────────────────────
  static const _lightScaffold = Color(0xFFFAF5F1);
  static const _lightCard = Color(0xFFF5EFEA);
  static const _lightCardHighlight = Color(0xFFEAE2DC);
  static const _lightPrimary = Color(0xFF1B3C53);
  static const _lightSecondary = Color(0xFF456882);
  static const _lightAppBar = Color(0xFF1B3C53);
  static const _lightTan = Color(0xFFD2C1B6);
  static const _lightCream = Color(0xFFF9F3EF);
  static const _lightIcon = Color(0xFF2E4057);
  static const _lightInactive = Color(0xFF8D99A6);

  // ────────────────────────────────────────────
  //  DARK PALETTE  (new — matches navy aesthetic)
  // ────────────────────────────────────────────
  static const _darkScaffold = Color(0xFF0F1A24);
  static const _darkCard = Color(0xFF1A2D3D);
  static const _darkCardHighlight = Color(0xFF243B4D);
  static const _darkPrimary = Color(0xFFE8E0D8);
  static const _darkSecondary = Color(0xFF8D99A6);
  static const _darkAppBar = Color(0xFF0D1520);
  static const _darkTan = Color(0xFF6B5D52);
  static const _darkCream = Color(0xFF1E2E3E);
  static const _darkIcon = Color(0xFF8FAEC5);
  static const _darkInactive = Color(0xFF5A6A78);

  // ────────────────────────────────────────────
  //  COLOR GETTERS (used by screens)
  // ────────────────────────────────────────────
  Color get scaffoldBg => isDarkMode ? _darkScaffold : _lightScaffold;
  Color get cardBg => isDarkMode ? _darkCard : _lightCard;
  Color get cardHighlight =>
      isDarkMode ? _darkCardHighlight : _lightCardHighlight;
  Color get primaryText => isDarkMode ? _darkPrimary : _lightPrimary;
  Color get secondaryText => isDarkMode ? _darkSecondary : _lightSecondary;
  Color get appBarBg => isDarkMode ? _darkAppBar : _lightAppBar;
  Color get tanColor => isDarkMode ? _darkTan : _lightTan;
  Color get creamColor => isDarkMode ? _darkCream : _lightCream;
  Color get iconColor => isDarkMode ? _darkIcon : _lightIcon;
  Color get inactiveColor => isDarkMode ? _darkInactive : _lightInactive;

  // Convenience colors
  Color get dividerColor =>
      isDarkMode ? const Color(0xFF2A3E50) : const Color(0xFFE0D8D0);
  Color get shadowColor => isDarkMode ? Colors.black54 : Colors.black12;
  Color get white => isDarkMode ? const Color(0xFFE8E0D8) : Colors.white;
  Color get inputFillColor =>
      isDarkMode ? const Color(0xFF1E3044) : Colors.white;
  Color get chipBg =>
      isDarkMode ? const Color(0xFF243B4D) : const Color(0xFFE8F0FE);

  // Accent colors (visible in both themes, slightly adjusted for dark)
  Color get accentTeal =>
      isDarkMode ? const Color(0xFF36B5A0) : const Color(0xFF2A9D8F);
  Color get accentAmber =>
      isDarkMode ? const Color(0xFFF0D080) : const Color(0xFFE9C46A);
  Color get accentCoral =>
      isDarkMode ? const Color(0xFFEB8A72) : const Color(0xFFE76F51);
  Color get accentBlue =>
      isDarkMode ? const Color(0xFF5A8FB0) : const Color(0xFF457B9D);

  // Gradient helpers
  Color get gradientStart =>
      isDarkMode ? const Color(0xFF1A3A50) : const Color(0xFF2C3E50);
  Color get gradientEnd =>
      isDarkMode ? const Color(0xFF3A7A9A) : const Color(0xFF496D91);

  // Splash screen colors (need high contrast for logo/text visibility)
  Color get splashGradientStart =>
      isDarkMode ? const Color(0xFF0D1520) : Colors.white;
  Color get splashGradientEnd =>
      isDarkMode ? const Color(0xFF1A2D3D) : const Color(0xFFF9F3EF);
  Color get splashTextColor =>
      isDarkMode ? const Color(0xFFE8E0D8) : const Color(0xFF1B3C53);
  Color get splashParticleColor =>
      isDarkMode ? const Color(0xFF5A8FB0) : const Color(0xFF1B3C53);

  // Analytics card background (needs sufficient opacity in dark mode)
  Color analyticsCardBg(Color accentColor) =>
      isDarkMode
          ? accentColor.withOpacity(0.15)
          : accentColor.withOpacity(0.2);

  // Bottom nav / containers that need card-like appearance
  Color get bottomNavBg =>
      isDarkMode ? const Color(0xFF1A2D3D) : Colors.white;

  // Shortcut card gradient
  Color get shortcutGradientStart =>
      isDarkMode ? const Color(0xFF243B4D) : const Color(0xFFD2C1B6);
  Color get shortcutGradientEnd =>
      isDarkMode ? const Color(0xFF1E2E3E) : const Color(0xFFF9F3EF);

  // ────────────────────────────────────────────
  //  THEME DATA
  // ────────────────────────────────────────────
  ThemeData get themeData => isDarkMode ? _darkTheme : _lightTheme;

  ThemeData get _lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: _lightPrimary,
    scaffoldBackgroundColor: _lightScaffold,
    colorScheme: const ColorScheme.light(
      primary: _lightPrimary,
      secondary: Color(0xFF1F3C88),
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF444444),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightAppBar,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _lightCard,
      titleTextStyle: const TextStyle(
        color: _lightPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(color: _lightSecondary, fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _lightPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
      ),
    ),
  );

  ThemeData get _darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: _darkPrimary,
    scaffoldBackgroundColor: _darkScaffold,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF5A8FB0),
      secondary: Color(0xFF4A7A9B),
      surface: _darkCard,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkAppBar,
      foregroundColor: Color(0xFFE8E0D8),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _darkCard,
      titleTextStyle: const TextStyle(
        color: _darkPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(color: _darkSecondary, fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF5A8FB0)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5A8FB0),
        foregroundColor: Colors.white,
      ),
    ),
  );
}
