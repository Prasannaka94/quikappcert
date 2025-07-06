import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _outputDirController = TextEditingController();
  bool _autoOpenFiles = true;
  bool _showAdvancedByDefault = false;
  bool _copyPathToClipboard = true;
  bool _showFileHistory = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _outputDirController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _outputDirController.text = prefs.getString('default_output_dir') ?? '';
      _autoOpenFiles = prefs.getBool('auto_open_files') ?? true;
      _showAdvancedByDefault =
          prefs.getBool('show_advanced_by_default') ?? false;
      _copyPathToClipboard = prefs.getBool('copy_path_to_clipboard') ?? true;
      _showFileHistory = prefs.getBool('show_file_history') ?? true;
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'default_output_dir',
        _outputDirController.text.trim(),
      );
      await prefs.setBool('auto_open_files', _autoOpenFiles);
      await prefs.setBool('show_advanced_by_default', _showAdvancedByDefault);
      await prefs.setBool('copy_path_to_clipboard', _copyPathToClipboard);
      await prefs.setBool('show_file_history', _showFileHistory);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectOutputDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _outputDirController.text = result;
      });
    }
  }

  Future<void> _resetToDefault() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Reset to default values
      _outputDirController.text = '';
      _autoOpenFiles = true;
      _showAdvancedByDefault = false;
      _copyPathToClipboard = true;
      _showFileHistory = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error resetting settings: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Output Directory
                  Text(
                    'Default Output Directory',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Where generated certificates and profiles will be saved by default.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _outputDirController,
                          decoration: const InputDecoration(
                            labelText: 'Output Directory',
                            hintText:
                                'Leave empty for default (~/Documents/QuikAppCert)',
                            prefixIcon: Icon(Icons.folder),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _selectOutputDirectory,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Browse'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Behavior Settings
                  Text(
                    'Behavior',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Auto-open files after generation'),
                    subtitle: const Text(
                      'Automatically open Finder/Explorer after successful operations',
                    ),
                    value: _autoOpenFiles,
                    onChanged: (value) =>
                        setState(() => _autoOpenFiles = value),
                    secondary: const Icon(Icons.open_in_new),
                  ),

                  SwitchListTile(
                    title: const Text('Copy path to clipboard'),
                    subtitle: const Text(
                      'Automatically copy file paths to clipboard',
                    ),
                    value: _copyPathToClipboard,
                    onChanged: (value) =>
                        setState(() => _copyPathToClipboard = value),
                    secondary: const Icon(Icons.copy),
                  ),

                  SwitchListTile(
                    title: const Text('Show advanced options by default'),
                    subtitle: const Text(
                      'Expand advanced options automatically',
                    ),
                    value: _showAdvancedByDefault,
                    onChanged: (value) =>
                        setState(() => _showAdvancedByDefault = value),
                    secondary: const Icon(Icons.settings),
                  ),

                  SwitchListTile(
                    title: const Text('Show file history'),
                    subtitle: const Text('Display recently generated files'),
                    value: _showFileHistory,
                    onChanged: (value) =>
                        setState(() => _showFileHistory = value),
                    secondary: const Icon(Icons.history),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Settings'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetToDefault,
                          icon: const Icon(Icons.restore),
                          label: const Text('Reset to Defaults'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // App Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Information',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text('Version: 1.0.0'),
                        Text('Platform: ${Platform.operatingSystem}'),
                        Text('Default Password: quikappcert'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
