import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';

class CertificateService {
  static const String defaultPassword = 'quikappcert';
  static const String _outputDirName = 'QuikAppCert';

  // Get the output directory for certificates
  static Future<String> getOutputDirectory() async {
    String baseDir;

    if (Platform.isMacOS) {
      baseDir = path.join(Platform.environment['HOME'] ?? '', 'Documents');
    } else if (Platform.isWindows) {
      baseDir = path.join(
        Platform.environment['USERPROFILE'] ?? '',
        'Documents',
      );
    } else {
      // Linux and other platforms
      baseDir = path.join(Platform.environment['HOME'] ?? '', 'Documents');
    }

    final outputDir = path.join(baseDir, _outputDirName);

    // Create directory if it doesn't exist
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return outputDir;
  }

  // Generate CSR (Certificate Signing Request)
  static Future<String> generateCSR({
    required String commonName,
    required String organization,
    required String organizationalUnit,
    required String country,
    required String state,
    required String locality,
  }) async {
    final outputDir = await getOutputDirectory();
    final privateKeyPath = path.join(outputDir, 'private.key');
    final csrPath = path.join(outputDir, 'cert.csr');

    try {
      if (Platform.isMacOS) {
        // Use Keychain Access for macOS
        return await _generateCSRMacOS(
          commonName: commonName,
          organization: organization,
          organizationalUnit: organizationalUnit,
          country: country,
          state: state,
          locality: locality,
          privateKeyPath: privateKeyPath,
          csrPath: csrPath,
        );
      } else {
        // Use OpenSSL for Windows/Linux
        return await _generateCSROpenSSL(
          commonName: commonName,
          organization: organization,
          organizationalUnit: organizationalUnit,
          country: country,
          state: state,
          locality: locality,
          privateKeyPath: privateKeyPath,
          csrPath: csrPath,
        );
      }
    } catch (e) {
      throw Exception('Failed to generate CSR: $e');
    }
  }

  // Generate CSR using macOS Keychain Access
  static Future<String> _generateCSRMacOS({
    required String commonName,
    required String organization,
    required String organizationalUnit,
    required String country,
    required String state,
    required String locality,
    required String privateKeyPath,
    required String csrPath,
  }) async {
    // Create a temporary config file for the CSR
    final configPath = path.join(await getOutputDirectory(), 'csr.conf');
    final configContent =
        '''
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C = $country
ST = $state
L = $locality
O = $organization
OU = $organizationalUnit
CN = $commonName
''';

    await File(configPath).writeAsString(configContent);

    // Use system OpenSSL path on macOS
    final opensslPath = '/usr/bin/openssl';
    final commands = [
      '"$opensslPath" genrsa -out "$privateKeyPath" 2048',
      '"$opensslPath" req -new -key "$privateKeyPath" -out "$csrPath" -config "$configPath"',
    ];

    for (final command in commands) {
      final result = await Process.run('bash', ['-c', command]);
      if (result.exitCode != 0) {
        throw Exception('Command failed: ${result.stderr}');
      }
    }

    // Read the CSR content
    final csrFile = File(csrPath);
    if (await csrFile.exists()) {
      return await csrFile.readAsString();
    } else {
      throw Exception('CSR file was not created');
    }
  }

  // Generate CSR using OpenSSL (Windows/Linux)
  static Future<String> _generateCSROpenSSL({
    required String commonName,
    required String organization,
    required String organizationalUnit,
    required String country,
    required String state,
    required String locality,
    required String privateKeyPath,
    required String csrPath,
  }) async {
    // Create a temporary config file for the CSR
    final configPath = path.join(await getOutputDirectory(), 'csr.conf');
    final configContent =
        '''
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C = $country
ST = $state
L = $locality
O = $organization
OU = $organizationalUnit
CN = $commonName
''';

    await File(configPath).writeAsString(configContent);

    // Generate private key and CSR
    final commands = [
      'openssl genrsa -out "$privateKeyPath" 2048',
      'openssl req -new -key "$privateKeyPath" -out "$csrPath" -config "$configPath"',
    ];

    for (final command in commands) {
      final result = await Process.run('bash', ['-c', command]);
      if (result.exitCode != 0) {
        throw Exception('Command failed: ${result.stderr}');
      }
    }

    // Read the CSR content
    final csrFile = File(csrPath);
    if (await csrFile.exists()) {
      return await csrFile.readAsString();
    } else {
      throw Exception('CSR file was not created');
    }
  }

  // Convert certificate to .p12 format
  static Future<String> convertToP12({
    required String certificatePath,
    required String privateKeyPath,
    String password = defaultPassword,
  }) async {
    final outputDir = await getOutputDirectory();
    final p12Path = path.join(outputDir, 'apple_distribution.p12');
    final pemPath = path.join(outputDir, 'certificate.pem');

    try {
      // Convert .cer to .pem
      final convertCommand =
          'openssl x509 -in "$certificatePath" -inform DER -out "$pemPath" -outform PEM';
      final convertResult = await Process.run('bash', ['-c', convertCommand]);

      if (convertResult.exitCode != 0) {
        throw Exception(
          'Failed to convert certificate: ${convertResult.stderr}',
        );
      }

      // Create .p12 file
      final p12Command =
          'openssl pkcs12 -export -inkey "$privateKeyPath" -in "$pemPath" -out "$p12Path" -name "Apple Distribution" -password pass:$password';
      final p12Result = await Process.run('bash', ['-c', p12Command]);

      if (p12Result.exitCode != 0) {
        throw Exception('Failed to create .p12 file: ${p12Result.stderr}');
      }

      return p12Path;
    } catch (e) {
      throw Exception('Failed to convert to .p12: $e');
    }
  }

  // Get certificate information
  static Future<Map<String, String>> getCertificateInfo(
    String certificatePath,
  ) async {
    try {
      final command = 'openssl x509 -in "$certificatePath" -text -noout';
      final result = await Process.run('bash', ['-c', command]);

      if (result.exitCode != 0) {
        throw Exception('Failed to read certificate: ${result.stderr}');
      }

      final output = result.stdout.toString();

      // Parse certificate information
      final info = <String, String>{};

      // Extract common name
      final cnMatch = RegExp(
        r'Subject:.*CN\s*=\s*([^\s,]+)',
      ).firstMatch(output);
      if (cnMatch != null) {
        info['commonName'] = cnMatch.group(1) ?? '';
      }

      // Extract organization
      final orgMatch = RegExp(
        r'Subject:.*O\s*=\s*([^\s,]+)',
      ).firstMatch(output);
      if (orgMatch != null) {
        info['organization'] = orgMatch.group(1) ?? '';
      }

      // Extract expiration date
      final expMatch = RegExp(r'Not After\s*:\s*([^\n]+)').firstMatch(output);
      if (expMatch != null) {
        info['expirationDate'] = expMatch.group(1)?.trim() ?? '';
      }

      // Extract serial number
      final serialMatch = RegExp(
        r'Serial Number:\s*([^\n]+)',
      ).firstMatch(output);
      if (serialMatch != null) {
        info['serialNumber'] = serialMatch.group(1)?.trim() ?? '';
      }

      return info;
    } catch (e) {
      throw Exception('Failed to get certificate info: $e');
    }
  }

  // Validate certificate
  static Future<bool> validateCertificate(String certificatePath) async {
    try {
      final command = 'openssl x509 -in "$certificatePath" -checkend 0 -noout';
      final result = await Process.run('bash', ['-c', command]);

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  // Get OpenSSL version
  static Future<String> getOpenSSLVersion() async {
    try {
      final result = await Process.run('openssl', ['version']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      } else {
        return 'OpenSSL not available';
      }
    } catch (e) {
      return 'OpenSSL not available';
    }
  }

  // Check if OpenSSL is available
  static Future<bool> isOpenSSLAvailable() async {
    try {
      final result = await Process.run('openssl', ['version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
