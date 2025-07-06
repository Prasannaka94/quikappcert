import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class FileHistoryEntry {
  final String id;
  final String fileName;
  final String filePath;
  final String fileType; // 'certificate' or 'profile'
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  FileHistoryEntry({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.createdAt,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory FileHistoryEntry.fromJson(Map<String, dynamic> json) {
    return FileHistoryEntry(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      fileType: json['fileType'],
      createdAt: DateTime.parse(json['createdAt']),
      metadata: json['metadata'] ?? {},
    );
  }
}

class FileHistoryService {
  static const String _storageKey = 'file_history';
  static const int _maxEntries = 50;

  // Add a new file to history
  static Future<void> addFile({
    required String fileName,
    required String filePath,
    required String fileType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_storageKey);
      List<FileHistoryEntry> history = [];

      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        history = historyList.map((e) => FileHistoryEntry.fromJson(e)).toList();
      }

      // Add new entry
      final newEntry = FileHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        filePath: filePath,
        fileType: fileType,
        createdAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      history.insert(0, newEntry); // Add to beginning

      // Keep only the latest entries
      if (history.length > _maxEntries) {
        history = history.take(_maxEntries).toList();
      }

      // Save back to storage
      final updatedHistoryJson = json.encode(
        history.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_storageKey, updatedHistoryJson);
    } catch (e) {
      print('Error adding file to history: $e');
    }
  }

  // Get all file history entries
  static Future<List<FileHistoryEntry>> getFileHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_storageKey);

      if (historyJson == null) return [];

      final List<dynamic> historyList = json.decode(historyJson);
      return historyList.map((e) => FileHistoryEntry.fromJson(e)).toList();
    } catch (e) {
      print('Error getting file history: $e');
      return [];
    }
  }

  // Get file history filtered by type
  static Future<List<FileHistoryEntry>> getFileHistoryByType(
    String fileType,
  ) async {
    final history = await getFileHistory();
    return history.where((entry) => entry.fileType == fileType).toList();
  }

  // Remove a file from history
  static Future<void> removeFile(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_storageKey);

      if (historyJson == null) return;

      final List<dynamic> historyList = json.decode(historyJson);
      List<FileHistoryEntry> history = historyList
          .map((e) => FileHistoryEntry.fromJson(e))
          .toList();

      history.removeWhere((entry) => entry.id == id);

      final updatedHistoryJson = json.encode(
        history.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_storageKey, updatedHistoryJson);
    } catch (e) {
      print('Error removing file from history: $e');
    }
  }

  // Clear all file history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing file history: $e');
    }
  }

  // Check if file still exists
  static bool fileExists(String filePath) {
    return File(filePath).existsSync();
  }

  // Get file size
  static String getFileSize(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024)
          return '${(bytes / 1024).toStringAsFixed(1)} KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      print('Error getting file size: $e');
    }
    return 'Unknown';
  }

  // Get file extension icon
  static String getFileIcon(String fileType) {
    switch (fileType) {
      case 'certificate':
        return '🔐';
      case 'profile':
        return '📱';
      default:
        return '📄';
    }
  }

  // Get formatted date
  static String getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Get file type description
  static String getFileTypeDescription(
    String fileType,
    Map<String, dynamic> metadata,
  ) {
    if (fileType == 'certificate') {
      final specificType = metadata['fileType'] as String?;
      switch (specificType) {
        case 'private_key':
          return 'Private Key';
        case 'csr':
          return 'Certificate Signing Request';
        case 'cer':
          return 'Apple Certificate';
        case 'p12':
          return 'PKCS#12 Bundle';
        case 'export_package':
          return 'Certificate Package';
        default:
          return 'Certificate';
      }
    } else if (fileType == 'profile') {
      return 'Provisioning Profile';
    }
    return 'File';
  }

  // Get file type icon with specific type
  static String getFileTypeIcon(
    String fileType,
    Map<String, dynamic> metadata,
  ) {
    if (fileType == 'certificate') {
      final specificType = metadata['fileType'] as String?;
      switch (specificType) {
        case 'private_key':
          return '🔑';
        case 'csr':
          return '📝';
        case 'cer':
          return '📜';
        case 'p12':
          return '🔐';
        case 'export_package':
          return '📦';
        default:
          return '🔐';
      }
    } else if (fileType == 'profile') {
      return '📱';
    }
    return '📄';
  }

  // Get certificate type badge text
  static String? getCertificateTypeBadge(Map<String, dynamic> metadata) {
    final certType = metadata['certType'] as String?;
    if (certType != null) {
      return certType;
    }
    return null;
  }

  // Get file count for export packages
  static String? getFileCountText(Map<String, dynamic> metadata) {
    final fileType = metadata['fileType'] as String?;
    if (fileType == 'export_package') {
      final count = metadata['containsFiles'] as int?;
      if (count != null) {
        return '$count files';
      }
    }
    return null;
  }
}
