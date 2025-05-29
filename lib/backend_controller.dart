import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/widgets.dart';

class SpeechRecognitionController {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isInitialized = false;
  String _transcription = '';
  bool _isListening = false;
  
  // Callback functions
  final Function(String) onTranscriptionUpdated;
  final Function(bool) onListeningStatusChanged;
  final Function(bool) onProcessingStatusChanged;

  SpeechRecognitionController({
    required this.onTranscriptionUpdated,
    required this.onListeningStatusChanged,
    required this.onProcessingStatusChanged,
  });

  Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' && _isListening) {
            _isListening = false;
            onListeningStatusChanged(false);
            onProcessingStatusChanged(true);
            
            // Simulate processing delay
            Future.delayed(const Duration(milliseconds: 500), () {
              onProcessingStatusChanged(false);
            });
          }
        },
        onError: (error) => debugPrint('Speech recognition error: $error'),
      );
    }
  }

  Future<void> startListening() async {
    await initialize();
    
    if (_isInitialized && !_isListening) {
      _isListening = true;
      onListeningStatusChanged(true);
      
      _transcription = '';
      onTranscriptionUpdated(_transcription);
      
      await _speechToText.listen(
        onResult: (result) {
          _transcription = result.recognizedWords;
          onTranscriptionUpdated(_transcription);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      onListeningStatusChanged(false);
      onProcessingStatusChanged(true);
      
      // Simulate processing delay
      Future.delayed(const Duration(milliseconds: 500), () {
        onProcessingStatusChanged(false);
      });
    }
  }

  bool get isListening => _isListening;
  String get transcription => _transcription;
}
