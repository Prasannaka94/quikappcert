import 'package:flutter/material.dart';
import '../services/apple_developer_service.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert' as convert;
import 'package:flutter/services.dart';
import '../services/file_history_service.dart';
import '../services/settings_service.dart';

class ProvisioningProfileScreen extends StatefulWidget {
  const ProvisioningProfileScreen({super.key});

  @override
  State<ProvisioningProfileScreen> createState() =>
      _ProvisioningProfileScreenState();
}

class _ProvisioningProfileScreenState extends State<ProvisioningProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bundleIdController = TextEditingController();
  String _profileType = 'App Store';
  bool _isLoading = false;
  String? _result;
  String? _error;
  final _customOutputDirController = TextEditingController();
  bool _showAdvanced = false;
  String? _apiLog;

  @override
  void dispose() {
    _bundleIdController.dispose();
    _customOutputDirController.dispose();
    super.dispose();
  }

  Future<void> _downloadProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
      _apiLog = null;
    });
    try {
      final profiles = await AppleDeveloperService.getProvisioningProfiles();
      final filtered = profiles.where((profile) {
        final attrs = profile['attributes'] ?? {};
        final bundleId = attrs['bundleId'] ?? '';
        final type = attrs['profileType'] ?? '';
        return bundleId == _bundleIdController.text.trim() &&
            type.toLowerCase().contains(_profileType.toLowerCase());
      }).toList();
      if (filtered.isEmpty) {
        throw Exception('No matching provisioning profile found.');
      }
      // Sort by last modified date (descending)
      filtered.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['attributes']?['dateModified'] ?? '') ??
            DateTime(1970);
        final bDate =
            DateTime.tryParse(b['attributes']?['dateModified'] ?? '') ??
            DateTime(1970);
        return bDate.compareTo(aDate);
      });
      final latest = filtered.first;
      final downloadUrl = latest['attributes']?['profileContent'];
      if (downloadUrl == null)
        throw Exception('Profile download URL not found.');
      // The profileContent is base64-encoded
      final bytes = convert.base64Decode(downloadUrl);
      final outputDir = _customOutputDirController.text.trim().isNotEmpty
          ? _customOutputDirController.text.trim()
          : path.join(
              Platform.environment['HOME'] ?? '',
              'Documents',
              'QuikAppCert',
            );
      final filePath = path.join(
        outputDir,
        '${_bundleIdController.text.trim()}_${_profileType.replaceAll(' ', '_')}.mobileprovision',
      );
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);

      // Add to file history
      await FileHistoryService.addFile(
        fileName: path.basename(filePath),
        filePath: filePath,
        fileType: 'profile',
        metadata: {
          'bundleId': _bundleIdController.text.trim(),
          'profileType': _profileType,
          'profileId': latest['id'],
        },
      );

      setState(() {
        _result = 'Profile downloaded to $filePath';
        _apiLog =
            'Found ${filtered.length} matching profiles. Downloaded latest: ${latest['id']}';
      });

      // Apply settings
      final autoOpen = await SettingsService.getAutoOpenFiles();
      final copyPath = await SettingsService.getCopyPathToClipboard();

      if (autoOpen) {
        if (Platform.isMacOS) {
          await Process.run('open', [path.dirname(filePath)]);
        } else if (Platform.isWindows) {
          await Process.run('explorer', [path.dirname(filePath)]);
        } else {
          await Process.run('xdg-open', [path.dirname(filePath)]);
        }
      }

      if (copyPath) {
        Clipboard.setData(ClipboardData(text: filePath));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Path copied to clipboard!')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _apiLog = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Provisioning Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download .mobileprovision',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.apps, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Select your app and profile type:'),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _bundleIdController,
                    decoration: const InputDecoration(
                      labelText: 'Bundle ID',
                      hintText: 'e.g. com.example.app',
                      prefixIcon: Icon(Icons.android),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _profileType,
                    items: const [
                      DropdownMenuItem(
                        value: 'App Store',
                        child: Text('App Store'),
                      ),
                      DropdownMenuItem(value: 'Ad Hoc', child: Text('Ad Hoc')),
                      DropdownMenuItem(
                        value: 'Development',
                        child: Text('Development'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _profileType = v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Profile Type',
                      prefixIcon: Icon(Icons.security),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _showAdvanced,
                        onChanged: (v) =>
                            setState(() => _showAdvanced = v ?? false),
                      ),
                      const Text('Show advanced options'),
                    ],
                  ),
                  if (_showAdvanced) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customOutputDirController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Output Directory',
                        hintText:
                            'Leave empty for default (~/Documents/QuikAppCert)',
                        prefixIcon: Icon(Icons.folder),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      onPressed: _isLoading ? null : _downloadProfile,
                      label: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Download Profile'),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Profile downloaded successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _result!,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () async {
                            final filePath = _result!.replaceAll(
                              'Profile downloaded to ',
                              '',
                            );
                            if (Platform.isMacOS) {
                              await Process.run('open', [
                                path.dirname(filePath),
                              ]);
                            } else if (Platform.isWindows) {
                              await Process.run('explorer', [
                                path.dirname(filePath),
                              ]);
                            } else {
                              await Process.run('xdg-open', [
                                path.dirname(filePath),
                              ]);
                            }
                          },
                          label: const Text('Show in Finder/Explorer'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            final filePath = _result!.replaceAll(
                              'Profile downloaded to ',
                              '',
                            );
                            Clipboard.setData(ClipboardData(text: filePath));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Path copied to clipboard!'),
                              ),
                            );
                          },
                          label: const Text('Copy Path'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (_showAdvanced && _apiLog != null) ...[
              const SizedBox(height: 16),
              Text('API Log:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _apiLog!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
