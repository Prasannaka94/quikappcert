import 'package:flutter/material.dart';
import '../services/certificate_service.dart';
import '../services/apple_developer_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;
import '../services/file_history_service.dart';
import '../services/settings_service.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commonNameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _orgUnitController = TextEditingController();
  final _countryController = TextEditingController(text: 'US');
  final _stateController = TextEditingController();
  final _localityController = TextEditingController();
  final _p12PasswordController = TextEditingController(
    text: CertificateService.defaultPassword,
  );
  String _certType = 'Distribution';
  List<String> _availableCertTypes = [];
  bool _isLoading = false;
  String? _csrContent;
  String? _error;
  String? _cerPath;
  String? _p12Path;
  String? _privateKeyPath;
  String? _csrPath;
  bool _showAdvanced = false;
  String? _opensslLog;
  String? _apiLog;
  bool _autoDownloadCer = true;
  bool _showExportAll = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableCertTypes();
    _loadSettings();
  }

  Future<void> _loadAvailableCertTypes() async {
    setState(() {
      _availableCertTypes =
          AppleDeveloperService.getAvailableCertificateTypes();
    });
  }

  Future<void> _loadSettings() async {
    final showAdvanced = await SettingsService.getShowAdvancedByDefault();
    setState(() {
      _showAdvanced = showAdvanced;
    });
  }

  @override
  void dispose() {
    _commonNameController.dispose();
    _organizationController.dispose();
    _orgUnitController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _localityController.dispose();
    _p12PasswordController.dispose();
    super.dispose();
  }

  Future<void> _generateCSR() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _csrContent = null;
      _error = null;
      _opensslLog = null;
      _apiLog = null;
      _cerPath = null;
      _p12Path = null;
      _showExportAll = false;
    });

    try {
      final outputDir = await CertificateService.getOutputDirectory();
      _privateKeyPath = path.join(outputDir, 'private.key');
      _csrPath = path.join(outputDir, 'cert.csr');

      final csrContent = await CertificateService.generateCSR(
        commonName: _commonNameController.text.trim(),
        organization: _organizationController.text.trim(),
        organizationalUnit: _orgUnitController.text.trim(),
        country: _countryController.text.trim(),
        state: _stateController.text.trim(),
        locality: _localityController.text.trim(),
      );

      setState(() {
        _csrContent = csrContent;
        _opensslLog =
            'CSR generated successfully. Files created:\n- Private Key: $_privateKeyPath\n- CSR: $_csrPath';
      });

      // Add private key to file history
      await FileHistoryService.addFile(
        fileName: path.basename(_privateKeyPath!),
        filePath: _privateKeyPath!,
        fileType: 'certificate',
        metadata: {
          'commonName': _commonNameController.text.trim(),
          'organization': _organizationController.text.trim(),
          'certType': _certType,
          'fileType': 'private_key',
        },
      );

      // Add CSR to file history
      await FileHistoryService.addFile(
        fileName: path.basename(_csrPath!),
        filePath: _csrPath!,
        fileType: 'certificate',
        metadata: {
          'commonName': _commonNameController.text.trim(),
          'organization': _organizationController.text.trim(),
          'certType': _certType,
          'fileType': 'csr',
        },
      );

      // Automatically download .cer if enabled
      if (_autoDownloadCer) {
        await _downloadCerFromCSR();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _opensslLog = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadCerFromCSR() async {
    if (_csrContent == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _apiLog = null;
    });

    try {
      // Upload CSR to Apple Developer Portal
      final apiCertType = AppleDeveloperService.getCertificateTypeString(
        _certType,
      );
      final certificateData = await AppleDeveloperService.uploadCSR(
        csrContent: _csrContent!,
        certificateType: apiCertType,
      );

      final certificateId = certificateData['id'];
      final certificateContent =
          await AppleDeveloperService.downloadCertificate(certificateId);

      // Save .cer file
      final outputDir = await CertificateService.getOutputDirectory();
      final cerFileName =
          '${_commonNameController.text.trim()}_${_certType.toLowerCase()}.cer';
      _cerPath = path.join(outputDir, cerFileName);

      final cerFile = File(_cerPath!);
      await cerFile.writeAsString(certificateContent);

      // Add .cer to file history
      await FileHistoryService.addFile(
        fileName: path.basename(_cerPath!),
        filePath: _cerPath!,
        fileType: 'certificate',
        metadata: {
          'commonName': _commonNameController.text.trim(),
          'organization': _organizationController.text.trim(),
          'certType': _certType,
          'fileType': 'cer',
          'certificateId': certificateId,
        },
      );

      setState(() {
        _apiLog =
            'Certificate downloaded successfully!\nCertificate ID: $certificateId\nFile: $_cerPath';
        _showExportAll = true;
      });

      // Apply settings
      final autoOpen = await SettingsService.getAutoOpenFiles();
      final copyPath = await SettingsService.getCopyPathToClipboard();

      if (autoOpen) {
        if (Platform.isMacOS) {
          await Process.run('open', [path.dirname(_cerPath!)]);
        } else if (Platform.isWindows) {
          await Process.run('explorer', [path.dirname(_cerPath!)]);
        } else {
          await Process.run('xdg-open', [path.dirname(_cerPath!)]);
        }
      }

      if (copyPath) {
        Clipboard.setData(ClipboardData(text: _cerPath!));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificate path copied to clipboard!'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to download certificate: $e';
        _apiLog = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportP12() async {
    if (_cerPath == null) return;
    setState(() {
      _isLoading = true;
      _p12Path = null;
      _error = null;
      _opensslLog = null;
    });
    try {
      final outputDir = await CertificateService.getOutputDirectory();
      final p12Path = await CertificateService.convertToP12(
        certificatePath: _cerPath!,
        privateKeyPath: _privateKeyPath!,
        password: _p12PasswordController.text.trim(),
      );

      // Add to file history
      await FileHistoryService.addFile(
        fileName: path.basename(p12Path),
        filePath: p12Path,
        fileType: 'certificate',
        metadata: {
          'commonName': _commonNameController.text.trim(),
          'organization': _organizationController.text.trim(),
          'password': _p12PasswordController.text.trim(),
          'certType': _certType,
          'fileType': 'p12',
        },
      );

      setState(() {
        _p12Path = p12Path;
        _opensslLog = 'Exported using OpenSSL. File: $p12Path';
        _showExportAll = true;
      });

      // Apply settings
      final autoOpen = await SettingsService.getAutoOpenFiles();
      final copyPath = await SettingsService.getCopyPathToClipboard();

      if (autoOpen) {
        if (Platform.isMacOS) {
          await Process.run('open', [path.dirname(p12Path)]);
        } else if (Platform.isWindows) {
          await Process.run('explorer', [path.dirname(p12Path)]);
        } else {
          await Process.run('xdg-open', [path.dirname(p12Path)]);
        }
      }

      if (copyPath) {
        Clipboard.setData(ClipboardData(text: p12Path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Path copied to clipboard!')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _opensslLog = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportAllFiles() async {
    if (_privateKeyPath == null || _csrPath == null || _cerPath == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final outputDir = await CertificateService.getOutputDirectory();
      final exportDir = path.join(
        outputDir,
        '${_commonNameController.text.trim()}_${_certType.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Create export directory
      final exportDirectory = Directory(exportDir);
      await exportDirectory.create(recursive: true);

      // Copy all files to export directory
      final files = [
        {
          'source': _privateKeyPath!,
          'dest': path.join(exportDir, 'private.key'),
        },
        {'source': _csrPath!, 'dest': path.join(exportDir, 'cert.csr')},
        {'source': _cerPath!, 'dest': path.join(exportDir, 'certificate.cer')},
      ];

      if (_p12Path != null) {
        files.add({
          'source': _p12Path!,
          'dest': path.join(exportDir, 'certificate.p12'),
        });
      }

      for (final file in files) {
        final sourceFile = File(file['source']!);
        final destFile = File(file['dest']!);
        await sourceFile.copy(destFile.path);
      }

      // Create info file
      final infoFile = File(path.join(exportDir, 'certificate_info.txt'));
      final infoContent =
          '''
Certificate Information
======================

Common Name: ${_commonNameController.text.trim()}
Organization: ${_organizationController.text.trim()}
Organizational Unit: ${_orgUnitController.text.trim()}
Country: ${_countryController.text.trim()}
State: ${_stateController.text.trim()}
Locality: ${_localityController.text.trim()}
Certificate Type: $_certType
Generated: ${DateTime.now().toString()}

Files Included:
- private.key (Private Key)
- cert.csr (Certificate Signing Request)
- certificate.cer (Apple Certificate)
${_p12Path != null ? '- certificate.p12 (PKCS#12 Bundle)' : ''}

P12 Password: ${_p12PasswordController.text.trim()}
''';
      await infoFile.writeAsString(infoContent);

      // Add export directory to file history
      await FileHistoryService.addFile(
        fileName: path.basename(exportDir),
        filePath: exportDir,
        fileType: 'certificate',
        metadata: {
          'commonName': _commonNameController.text.trim(),
          'organization': _organizationController.text.trim(),
          'certType': _certType,
          'fileType': 'export_package',
          'containsFiles': files.length,
        },
      );

      setState(() {
        _opensslLog = 'All files exported to: $exportDir';
      });

      // Apply settings
      final autoOpen = await SettingsService.getAutoOpenFiles();
      if (autoOpen) {
        if (Platform.isMacOS) {
          await Process.run('open', [exportDir]);
        } else if (Platform.isWindows) {
          await Process.run('explorer', [exportDir]);
        } else {
          await Process.run('xdg-open', [exportDir]);
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to export all files: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCerFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['cer'],
    );

    if (result != null) {
      setState(() {
        _cerPath = result.files.first.path;
        _showExportAll = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Certificate'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
            icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
            tooltip: 'Toggle Advanced Options',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Certificate Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Certificate Type',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _certType,
                        decoration: const InputDecoration(
                          labelText: 'Certificate Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableCertTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _certType = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // CSR Generation Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Certificate Details',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _commonNameController,
                              decoration: const InputDecoration(
                                labelText: 'Common Name (CN)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Common Name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _organizationController,
                              decoration: const InputDecoration(
                                labelText: 'Organization (O)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Organization is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _orgUnitController,
                              decoration: const InputDecoration(
                                labelText: 'Organizational Unit (OU)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _countryController,
                              decoration: const InputDecoration(
                                labelText: 'Country (C)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Country is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(
                                labelText: 'State (ST)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _localityController,
                              decoration: const InputDecoration(
                                labelText: 'Locality (L)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _generateCSR,
                              icon: const Icon(Icons.key),
                              label: const Text('Generate CSR'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: double.infinity,
                            child: SwitchListTile(
                              title: const Text('Auto-download .cer'),
                              subtitle: const Text(
                                'Automatically download certificate after CSR generation',
                              ),
                              value: _autoDownloadCer,
                              onChanged: (value) =>
                                  setState(() => _autoDownloadCer = value),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (_csrContent != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generated CSR',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SelectableText(
                            _csrContent!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _csrContent!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('CSR copied to clipboard!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy CSR'),
                            ),
                            const SizedBox(width: 8),
                            if (!_autoDownloadCer) ...[
                              ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : _downloadCerFromCSR,
                                icon: const Icon(Icons.download),
                                label: const Text('Download .cer'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_cerPath != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Certificate Downloaded',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
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
                              Text('Certificate: ${path.basename(_cerPath!)}'),
                              Text('Path: $_cerPath'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                if (Platform.isMacOS) {
                                  Process.run('open', [
                                    path.dirname(_cerPath!),
                                  ]);
                                } else if (Platform.isWindows) {
                                  Process.run('explorer', [
                                    path.dirname(_cerPath!),
                                  ]);
                                } else {
                                  Process.run('xdg-open', [
                                    path.dirname(_cerPath!),
                                  ]);
                                }
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Show in Finder/Explorer'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _cerPath!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Path copied to clipboard!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy Path'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_showAdvanced) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Advanced Options',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _p12PasswordController,
                          decoration: const InputDecoration(
                            labelText: 'P12 Password',
                            border: OutlineInputBorder(),
                            helperText: 'Password for the .p12 file',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _cerPath == null
                                    ? null
                                    : (_isLoading ? null : _exportP12),
                                icon: const Icon(Icons.file_download),
                                label: const Text('Export P12'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _selectCerFile,
                                icon: const Icon(Icons.file_upload),
                                label: const Text('Select .cer File'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_p12Path != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'P12 Exported',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('P12 File: ${path.basename(_p12Path!)}'),
                              Text('Path: $_p12Path'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                if (Platform.isMacOS) {
                                  Process.run('open', [
                                    path.dirname(_p12Path!),
                                  ]);
                                } else if (Platform.isWindows) {
                                  Process.run('explorer', [
                                    path.dirname(_p12Path!),
                                  ]);
                                } else {
                                  Process.run('xdg-open', [
                                    path.dirname(_p12Path!),
                                  ]);
                                }
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Show in Finder/Explorer'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _p12Path!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Path copied to clipboard!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy Path'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_showExportAll) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export All Files',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Export all generated files (.key, .csr, .cer, .p12) to a single directory with certificate information.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _exportAllFiles,
                            icon: const Icon(Icons.folder_zip),
                            label: const Text('Export All Files'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.red[800],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: Colors.red[800])),
                    ],
                  ),
                ),
              ],

              if (_showAdvanced && _opensslLog != null) ...[
                const SizedBox(height: 16),
                Text(
                  'OpenSSL Log:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _opensslLog!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
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
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
