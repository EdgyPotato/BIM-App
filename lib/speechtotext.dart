import 'package:flutter/material.dart';
import 'detector.dart';
import 'translator.dart';
import 'settings.dart';
import 'backend_controller.dart'; // Import the backend controller

class SpeechToText extends StatefulWidget {
  const SpeechToText({super.key});

  @override
  State<SpeechToText> createState() => _SpeechToTextState();
}

class _SpeechToTextState extends State<SpeechToText> {
  bool _isRecording = false;
  bool _isProcessing = false;
  String _transcription = '';
  late SpeechRecognitionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SpeechRecognitionController(
      onTranscriptionUpdated: (text) {
        setState(() {
          _transcription = text;
        });
      },
      onListeningStatusChanged: (isListening) {
        setState(() {
          _isRecording = isListening;
        });
      },
      onProcessingStatusChanged: (isProcessing) {
        setState(() {
          _isProcessing = isProcessing;
        });
      },
    );
    _controller.initialize();
  }

  void _toggleRecordingState() {
    if (_isRecording) {
      _controller.stopListening();
    } else {
      _controller.startListening();
    }
  }

  // Helper method to convert text to sentence case
  String _toSentenceCase(String text) {
    if (text.isEmpty) return text;
    
    // Split by sentences (period followed by space)
    final sentences = text.split('. ');
    
    // Convert each sentence to sentence case
    final sentenceCased = sentences.map((sentence) {
      if (sentence.isEmpty) return sentence;
      // Capitalize first letter, keep rest as is
      return sentence[0].toUpperCase() + sentence.substring(1).toLowerCase();
    }).toList();
    
    // Join back with period and space
    return sentenceCased.join('. ');
  }

  String _getStatusText() {
    if (_isRecording) {
      return 'Recording...';
    } else if (_isProcessing) {
      return 'Processing...';
    } else if (_transcription.isNotEmpty) {
      return _toSentenceCase(_transcription);
    } else {
      return 'Press the microphone button to start transcribing your speech to text.';
    }
  }

  Color _getStatusTextColor() {
    if (_transcription.isNotEmpty && !_isRecording && !_isProcessing) {
      return Colors.white; // White for transcription result
    } else {
      return const Color(0x809E9E9E); // Barely visible grey for instructions
    }
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
                  Container(
                    color: Colors.black,
                    height: 35.0,
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(top: 40.0, bottom: 10.0),
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Builder(
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
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusTextColor(),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
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
                          child: const Text(
                            'Translate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isProcessing ? null : _toggleRecordingState,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.black : Colors.white,
                            foregroundColor: _isRecording ? Colors.white : Colors.black,
                            disabledBackgroundColor: Colors.grey[700],
                            disabledForegroundColor: Colors.grey[300],
                            elevation: 0.0,
                            padding: const EdgeInsets.all(16),
                            minimumSize: const Size(60, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              side: BorderSide(
                                color: _isRecording ? Colors.white : Colors.transparent,
                                width: 3.0,
                              ),
                            ),
                            splashFactory: NoSplash.splashFactory,
                          ),
                          child: const Icon(Icons.mic, size: 35.0),
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
                          onPressed: () {
                            setState(() {
                              _transcription = '';
                            });
                          },
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
