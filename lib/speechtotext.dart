import 'package:flutter/material.dart';
import 'dart:io';
import 'detector.dart';
import 'translator.dart';
import 'settings.dart';
import 'backend/stt_controller.dart';
import 'backend/api_controller.dart';
import 'backend/database.dart';
import 'stt_history.dart';

class SpeechToText extends StatefulWidget {
  const SpeechToText({super.key});

  @override
  State<SpeechToText> createState() => _SpeechToTextState();
}

class _SpeechToTextState extends State<SpeechToText> {
  final BackendController _backendController = BackendController();
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isHolding = false; // New state for tracking hold gesture
  String _statusText = 'Hold the microphone button to start transcribing your speech to text.';
  bool _isTranscriptionResult = false; // Flag to track if statusText contains transcription

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _cleanupOldFiles(); // Clean up old audio files on startup
  }

  Future<void> _initializeRecorder() async {
    await _backendController.initRecorder();
  }

  // Clean up old audio files periodically
  Future<void> _cleanupOldFiles() async {
    try {
      await BackendController.cleanupOldAudioFiles();
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_isProcessing) return;

    setState(() {
      _isRecording = true;
      _isHolding = true;
      _statusText = 'Recording...';
      _isTranscriptionResult = false;
    });
    await _backendController.startRecording();
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
      _isHolding = false;
      _isProcessing = true;
      _statusText = 'Processing...';
      _isTranscriptionResult = false;
    });

    final audioFilePath = await _backendController.stopRecording();

    if (audioFilePath != null && await BackendController.audioFileExists(audioFilePath)) {
      // Send to API for transcription
      final transcription = await ApiController.transcribeAudio(File(audioFilePath));

      setState(() {
        _isProcessing = false;
        if (transcription != null && transcription.isNotEmpty) {
          _statusText = transcription.trim();
          _isTranscriptionResult = true;
          
          // Save to database with file path
          _saveSpeechHistory(audioFilePath, transcription.trim());
        } else {
          _statusText = 'Transcription failed. Please try again.';
          _isTranscriptionResult = true;
          
          // Delete failed recording file
          _deleteAudioFile(audioFilePath);
        }
      });
    } else {
      setState(() {
        _isProcessing = false;
        _statusText = 'Recording failed. Please try again.';
        _isTranscriptionResult = false;
      });
    }
  }

  // Save speech-to-text history to database
  Future<void> _saveSpeechHistory(String audioPath, String transcription) async {
    try {
      await TranslationDatabase.instance.insertSpeechHistory(audioPath, transcription);
      debugPrint('Saved speech history with audio file: $audioPath');
    } catch (e) {
      debugPrint('Error saving speech history: $e');
    }
  }

  // Delete audio file if transcription failed
  Future<void> _deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted failed audio file: $filePath');
      }
    } catch (e) {
      debugPrint('Error deleting audio file: $e');
    }
  }

  void _clearText() {
    setState(() {
      _statusText = 'Hold the microphone button to start transcribing your speech to text.';
      _isTranscriptionResult = false;
    });
  }

  // Method to handle translate button press
  void _handleTranslate() {
    // Only navigate if we have transcription text
    if (_isTranscriptionResult && _statusText.isNotEmpty) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              TextTranslator(initialText: _statusText),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return child; // Instant transition
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _backendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        drawer: Drawer(
          backgroundColor: Colors.black,
          width: 0.8 * MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40.0,
                  horizontal: 20.0,
                ),
                width: double.infinity,
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Sign Language',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Translation App',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, thickness: 1, height: 1),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Detector',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const SignTranslator(),
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
                    Container(
                      color: Colors.white10,
                      child: ListTile(
                        leading: const Icon(Icons.mic, color: Colors.blue),
                        title: const Text(
                          'Speech To Text',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.translate, color: Colors.white),
                      title: const Text(
                        'Translator',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const TextTranslator(),
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
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.white),
                      title: const Text(
                        'Settings',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const Settings(),
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
                    // Add History option
                    ListTile(
                      leading: const Icon(Icons.history, color: Colors.white),
                      title: const Text(
                        'Speech History',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const SpeechHistoryPage(),
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
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 20.0,
                ),
                child: Column(
                  children: [
                    const Divider(
                      color: Colors.white24,
                      thickness: 1,
                      height: 1,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.white70,
                          ),
                          label: const Text(
                            'About',
                            style: TextStyle(color: Colors.white70),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(
                            Icons.help_outline,
                            color: Colors.white70,
                          ),
                          label: const Text(
                            'Help',
                            style: TextStyle(color: Colors.white70),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        drawerEnableOpenDragGesture: true,
        drawerEdgeDragWidth: MediaQuery.of(context).size.width,
        body: Builder(
          builder: (BuildContext scaffoldContext) {
            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                Scaffold.of(scaffoldContext).openDrawer();
              },
              behavior: HitTestBehavior.translucent,
              child: Column(
                children: [
                  // App bar with menu button and history icon
                  Container(
                    color: Colors.black,
                    height: 35.0,
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(top: 40.0, bottom: 10.0),
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 35,
                            ),
                            onPressed: () {
                              Scaffold.of(scaffoldContext).openDrawer();
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.history,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const SpeechHistoryPage(),
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
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.fromLTRB(
                        20.0,
                        20.0,
                        20.0,
                        10.0,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _statusText,
                          style: TextStyle(
                            color: _isTranscriptionResult 
                                ? Colors.white  // White text for transcription results
                                : const Color(0x809E9E9E),  // Gray text for instructions
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 30.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 20,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                            ),
                            splashFactory: NoSplash.splashFactory,
                          ),
                          // Update onPressed to use the new method
                          onPressed: _isTranscriptionResult ? _handleTranslate : null,
                          child: const Text(
                            'Translate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTapDown: (_) => _startRecording(),
                          onTapUp: (_) => _stopRecording(),
                          onTapCancel: () => _stopRecording(),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: _isHolding ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: _isHolding ? Colors.white : Colors.transparent,
                                width: 3.0,
                              ),
                            ),
                            child: Center(
                              child: _isProcessing
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    )
                                  : Icon(
                                      Icons.mic,
                                      size: 35.0,
                                      color: _isHolding ? Colors.white : Colors.black,
                                    ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 20,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          onPressed: _clearText,
                          child: const Text(
                            'Clear text',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
