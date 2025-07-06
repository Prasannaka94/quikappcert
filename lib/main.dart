import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'screens/home_screen.dart';
import 'screens/certificate_screen.dart';
import 'screens/provisioning_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/file_history_screen.dart';
import 'services/apple_developer_service.dart';
import 'services/certificate_service.dart';
import 'dart:io' show Platform;

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  if (!(Platform.isMacOS || Platform.isWindows)) {
    runApp(const UnsupportedPlatformApp());
    return;
  }

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log the error but don't crash the app
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true; // Prevent the error from being re-thrown
  };

  runApp(const QuikAppCert());
}

class UnsupportedPlatformApp extends StatelessWidget {
  const UnsupportedPlatformApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'This app only runs on Windows and macOS.',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}

class QuikAppCert extends StatelessWidget {
  const QuikAppCert({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuikAppCert',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Set up error widget builder
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please restart the app',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        };
        return child!;
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const HomeScreen(),
      routes: {
        '/generate-certificate': (context) => const CertificateScreen(),
        '/download-profile': (context) => const ProvisioningProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/file-history': (context) => const FileHistoryScreen(),
      },
    );
  }
}
