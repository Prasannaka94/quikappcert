import 'package:flutter/material.dart';
import '../widgets/apple_login_widget.dart';
import '../services/apple_developer_service.dart';
import '../services/file_history_service.dart';
import '../services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggedIn = false;
  String? _appleId;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final appleId = await AppleDeveloperService.getStoredAppleId();
    setState(() {
      _isLoggedIn = AppleDeveloperService.isLoggedIn;
      _appleId = appleId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuikAppCert'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Login Status
            if (!_isLoggedIn)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Apple Developer Account Required',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please sign in to your Apple Developer account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange),
                    ),
                    const SizedBox(height: 12),
                    AppleLoginWidget(
                      onLoginSuccess: (appleId) {
                        _checkLoginStatus();
                      },
                    ),
                  ],
                ),
              ),

            // Welcome Message
            if (_isLoggedIn)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Signed in as: $_appleId',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),

            // Main Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Simple action buttons
            _buildActionButton(
              'Manage Certificates',
              Icons.security,
              Colors.blue,
              () => Navigator.pushNamed(context, '/certificates'),
            ),

            const SizedBox(height: 12),

            _buildActionButton(
              'Provisioning Profiles',
              Icons.app_registration,
              Colors.green,
              () => Navigator.pushNamed(context, '/provisioning-profiles'),
            ),

            const SizedBox(height: 12),

            _buildActionButton(
              'Settings',
              Icons.settings,
              Colors.orange,
              () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
