import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // Default output directory
  static Future<String> getDefaultOutputDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('default_output_dir') ?? '';
  }

  static Future<void> setDefaultOutputDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_output_dir', path);
  }

  // Auto-open files after generation
  static Future<bool> getAutoOpenFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_open_files') ?? true;
  }

  static Future<void> setAutoOpenFiles(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_open_files', value);
  }

  // Show advanced options by default
  static Future<bool> getShowAdvancedByDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('show_advanced_by_default') ?? false;
  }

  static Future<void> setShowAdvancedByDefault(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_advanced_by_default', value);
  }

  // Copy path to clipboard
  static Future<bool> getCopyPathToClipboard() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('copy_path_to_clipboard') ?? true;
  }

  static Future<void> setCopyPathToClipboard(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('copy_path_to_clipboard', value);
  }

  // Show file history
  static Future<bool> getShowFileHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('show_file_history') ?? true;
  }

  static Future<void> setShowFileHistory(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_file_history', value);
  }

  // Get all settings as a map
  static Future<Map<String, dynamic>> getAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'default_output_dir': prefs.getString('default_output_dir') ?? '',
      'auto_open_files': prefs.getBool('auto_open_files') ?? true,
      'show_advanced_by_default':
          prefs.getBool('show_advanced_by_default') ?? false,
      'copy_path_to_clipboard': prefs.getBool('copy_path_to_clipboard') ?? true,
      'show_file_history': prefs.getBool('show_file_history') ?? true,
    };
  }

  // Reset all settings to defaults
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('default_output_dir');
    await prefs.remove('auto_open_files');
    await prefs.remove('show_advanced_by_default');
    await prefs.remove('copy_path_to_clipboard');
    await prefs.remove('show_file_history');
  }
}
