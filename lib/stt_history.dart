import 'package:flutter/material.dart';
import 'dart:io';
import 'backend/database.dart';

class SpeechHistoryPage extends StatefulWidget {
  const SpeechHistoryPage({super.key});

  @override
  State<SpeechHistoryPage> createState() => _SpeechHistoryPageState();
}

class _SpeechHistoryPageState extends State<SpeechHistoryPage> {
  List<SpeechHistory> _speechHistory = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<int> _selectedItems = <int>{};

  @override
  void initState() {
    super.initState();
    _loadSpeechHistory();
  }

  Future<void> _loadSpeechHistory() async {
    try {
      final speechHistory = await TranslationDatabase.instance.getAllSpeechHistory();
      setState(() {
        _speechHistory = speechHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Get file information
  Future<Map<String, dynamic>> _getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        final fileName = filePath.split('/').last;
        return {
          'exists': true,
          'size': size,
          'fileName': fileName,
          'fullPath': filePath,
        };
      }
    } catch (e) {
      debugPrint('Error getting file info: $e');
    }
    
    return {
      'exists': false,
      'size': 0,
      'fileName': 'File not found',
      'fullPath': filePath,
    };
  }

  Future<void> _deleteSpeechHistory(int id) async {
    // Get the speech record first to access audio file path
    final speechRecord = _speechHistory.firstWhere((s) => s.id == id);
    
    // Delete from database
    await TranslationDatabase.instance.deleteSpeechHistory(id);
    
    // Delete associated audio file
    try {
      final file = File(speechRecord.originalAudio);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted audio file: ${speechRecord.originalAudio}');
      }
    } catch (e) {
      debugPrint('Error deleting audio file: $e');
    }
    
    _loadSpeechHistory();
  }

  Future<void> _clearAllHistory() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Clear All History',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete all speech-to-text history and associated audio files?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Delete all audio files
                for (final speech in _speechHistory) {
                  try {
                    final file = File(speech.originalAudio);
                    if (await file.exists()) {
                      await file.delete();
                    }
                  } catch (e) {
                    debugPrint('Error deleting audio file: $e');
                  }
                }
                
                // Clear database
                await TranslationDatabase.instance.clearAllSpeechHistory();
                _loadSpeechHistory();
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _enterSelectionMode(int id) {
    setState(() {
      _isSelectionMode = true;
      _selectedItems.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItems.add(id);
      }
    });
  }

  Future<void> _deleteSelectedItems() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Delete ${_selectedItems.length} item${_selectedItems.length > 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete the selected speech record${_selectedItems.length > 1 ? 's' : ''} and associated audio files?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Delete both database records and audio files for selected items
                for (int id in _selectedItems) {
                  // Find the speech record to get audio file path
                  final speechRecord = _speechHistory.firstWhere((s) => s.id == id);
                  
                  // Delete from database
                  await TranslationDatabase.instance.deleteSpeechHistory(id);
                  
                  // Delete associated audio file
                  try {
                    final file = File(speechRecord.originalAudio);
                    if (await file.exists()) {
                      await file.delete();
                      debugPrint('Deleted audio file: ${speechRecord.originalAudio}');
                    }
                  } catch (e) {
                    debugPrint('Error deleting audio file: $e');
                  }
                }
                
                _exitSelectionMode();
                _loadSpeechHistory();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _exitSelectionMode,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        title: _isSelectionMode
            ? Text(
                '${_selectedItems.length} selected',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              )
            : const Text(
                'Speech-to-Text History',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (_selectedItems.length == _speechHistory.length) {
                    _selectedItems.clear();
                  } else {
                    _selectedItems = _speechHistory.map((s) => s.id!).toSet();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _selectedItems.isNotEmpty ? _deleteSelectedItems : null,
            ),
          ] else if (_speechHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: _clearAllHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : _speechHistory.isEmpty
              ? const Center(
                  child: Text(
                    'No speech-to-text history yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _speechHistory.length,
                  itemBuilder: (context, index) {
                    final speech = _speechHistory[index];
                    final isSelected = _selectedItems.contains(speech.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _enterSelectionMode(speech.id!);
                          }
                        },
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(speech.id!);
                          }
                        },
                        child: Row(
                          children: [
                            if (_isSelectionMode)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isSelected ? Colors.blue : Colors.white70,
                                  size: 24,
                                ),
                              ),
                            Expanded(
                              child: Card(
                                color: isSelected ? Colors.blue.withValues(alpha: 0.3) : Colors.grey[900],
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDateTime(speech.timestamp),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (!_isSelectionMode)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                  onPressed: () => _deleteSpeechHistory(speech.id!),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Audio File:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<Map<String, dynamic>>(
                                        future: _getFileInfo(speech.originalAudio),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const Text(
                                              'Loading file info...',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            );
                                          }
                                          
                                          final fileInfo = snapshot.data!;
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fileInfo['fileName'],
                                                style: TextStyle(
                                                  color: fileInfo['exists'] ? Colors.white70 : Colors.red,
                                                  fontSize: 14,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                              if (fileInfo['exists']) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Size: ${_formatFileSize(fileInfo['size'])}',
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ] else
                                                const Text(
                                                  'File not found',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Transcription:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        speech.transcribedText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
