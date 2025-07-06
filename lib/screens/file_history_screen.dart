import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/file_history_service.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class FileHistoryScreen extends StatefulWidget {
  const FileHistoryScreen({super.key});

  @override
  State<FileHistoryScreen> createState() => _FileHistoryScreenState();
}

class _FileHistoryScreenState extends State<FileHistoryScreen> {
  List<FileHistoryEntry> _history = [];
  String _filterType = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await FileHistoryService.getFileHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<FileHistoryEntry> get _filteredHistory {
    if (_filterType == 'all') return _history;
    return _history.where((entry) => entry.fileType == _filterType).toList();
  }

  Future<void> _openFile(FileHistoryEntry entry) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [path.dirname(entry.filePath)]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [path.dirname(entry.filePath)]);
      } else {
        await Process.run('xdg-open', [path.dirname(entry.filePath)]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
      }
    }
  }

  Future<void> _copyPath(FileHistoryEntry entry) async {
    await Clipboard.setData(ClipboardData(text: entry.filePath));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Path copied to clipboard!')),
      );
    }
  }

  Future<void> _removeFromHistory(FileHistoryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from History'),
        content: Text(
          'Remove "${entry.fileName}" from history? This won\'t delete the actual file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FileHistoryService.removeFile(entry.id);
      await _loadHistory();
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Remove all files from history? This won\'t delete the actual files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FileHistoryService.clearHistory();
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File History'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              onPressed: _clearHistory,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter
                if (_history.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text('Filter: '),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _filterType,
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Files'),
                            ),
                            DropdownMenuItem(
                              value: 'certificate',
                              child: Text('Certificates'),
                            ),
                            DropdownMenuItem(
                              value: 'profile',
                              child: Text('Profiles'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _filterType = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                // History List
                Expanded(
                  child: _filteredHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _history.isEmpty
                                    ? 'No files in history'
                                    : 'No files match the filter',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredHistory.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredHistory[index];
                            final fileExists = FileHistoryService.fileExists(
                              entry.filePath,
                            );
                            final fileSize = FileHistoryService.getFileSize(
                              entry.filePath,
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: Text(
                                  FileHistoryService.getFileTypeIcon(
                                    entry.fileType,
                                    entry.metadata,
                                  ),
                                  style: const TextStyle(fontSize: 24),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.fileName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: fileExists
                                              ? null
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    if (entry.fileType == 'certificate') ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          FileHistoryService.getFileTypeDescription(
                                            entry.fileType,
                                            entry.metadata,
                                          ),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue[900],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.filePath,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        color: fileExists ? null : Colors.grey,
                                      ),
                                    ),
                                    if (entry.fileType == 'certificate' &&
                                        FileHistoryService.getCertificateTypeBadge(
                                              entry.metadata,
                                            ) !=
                                            null) ...[
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Type: ${FileHistoryService.getCertificateTypeBadge(entry.metadata)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green[900],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (FileHistoryService.getFileCountText(
                                          entry.metadata,
                                        ) !=
                                        null) ...[
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          FileHistoryService.getFileCountText(
                                            entry.metadata,
                                          )!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange[900],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          FileHistoryService.getFormattedDate(
                                            entry.createdAt,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          fileSize,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                        if (!fileExists) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[100],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Missing',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange[800],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'open':
                                        _openFile(entry);
                                        break;
                                      case 'copy':
                                        _copyPath(entry);
                                        break;
                                      case 'remove':
                                        _removeFromHistory(entry);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'open',
                                      child: Row(
                                        children: [
                                          Icon(Icons.open_in_new),
                                          SizedBox(width: 8),
                                          Text('Show in Finder/Explorer'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'copy',
                                      child: Row(
                                        children: [
                                          Icon(Icons.copy),
                                          SizedBox(width: 8),
                                          Text('Copy Path'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete),
                                          SizedBox(width: 8),
                                          Text('Remove from History'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
