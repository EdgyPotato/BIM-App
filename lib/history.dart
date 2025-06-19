import 'package:flutter/material.dart';
import 'backend/database.dart';
import 'translator.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<TranslationHistory> _translations = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<int> _selectedItems = <int>{};

  @override
  void initState() {
    super.initState();
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    try {
      final translations = await TranslationDatabase.instance.getAllTranslations();
      setState(() {
        _translations = translations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTranslation(int id) async {
    await TranslationDatabase.instance.deleteTranslation(id);
    _loadTranslations();
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
            'Are you sure you want to delete all translation history?',
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
                await TranslationDatabase.instance.clearAllTranslations();
                _loadTranslations();
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
            'Are you sure you want to delete the selected translation${_selectedItems.length > 1 ? 's' : ''}?',
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
                for (int id in _selectedItems) {
                  await TranslationDatabase.instance.deleteTranslation(id);
                }
                _exitSelectionMode();
                _loadTranslations();
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
                'Translation History',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (_selectedItems.length == _translations.length) {
                    _selectedItems.clear();
                  } else {
                    _selectedItems = _translations.map((t) => t.id!).toSet();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _selectedItems.isNotEmpty ? _deleteSelectedItems : null,
            ),
          ] else if (_translations.isNotEmpty)
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
          : _translations.isEmpty
              ? const Center(
                  child: Text(
                    'No translation history yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _translations.length,
                  itemBuilder: (context, index) {
                    final translation = _translations[index];
                    final isSelected = _selectedItems.contains(translation.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _enterSelectionMode(translation.id!);
                          }
                        },
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(translation.id!);
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
                                margin: EdgeInsets.zero, // Remove card's default margin
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDateTime(translation.timestamp),
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
                                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                  onPressed: () {
                                                    Navigator.pushReplacement(
                                                      context,
                                                      PageRouteBuilder(
                                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                                            TextTranslator(initialText: translation.originalText),
                                                        transitionsBuilder: (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                          child,
                                                        ) {
                                                          return child;
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                  onPressed: () => _deleteTranslation(translation.id!),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Original:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        translation.originalText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Translation:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        translation.translatedText,
                                        style: const TextStyle(
                                          color: Colors.white70,
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
