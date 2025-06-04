import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class BackendController {
  final _audioRecorder = AudioRecorder(); // Using AudioRecorder class
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _silenceTimer;
  DateTime? _lastAudioActivity;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  
  // Initialize recorder and check permissions
  Future<void> initRecorder() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        debugPrint("Recorder initialized with permissions");
      } else {
        debugPrint("Microphone permission denied");
      }
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
    }
  }

  // Start recording audio
  Future<void> startRecording() async {
    if (_isRecording) return;
    
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      _recordingPath = '${directory.path}/speech_recording.m4a';
      
      // Configure recording - ensure path is non-nullable
      if (_recordingPath != null) {
        // Use RecordConfig for configuration
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 160000,
            sampleRate: 44100,
          ),
          path: _recordingPath!,
        );
        
        _isRecording = true;
        _lastAudioActivity = DateTime.now();
        
        // Start silence detection
        _startSilenceDetection();
        
        debugPrint('Recording started at: $_recordingPath');
      } else {
        debugPrint('Error: Recording path is null');
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  // Monitor for silence
  void _startSilenceDetection() {
    _silenceTimer?.cancel();
    _amplitudeSubscription?.cancel();
    
    // Set up amplitude monitoring using stream
    _amplitudeSubscription = _audioRecorder.onAmplitudeChanged(
      const Duration(milliseconds: 300)
    ).listen((amplitude) {
      if (!_isRecording) return;
      
      final now = DateTime.now();
      
      // If sound detected, update last activity timestamp
      if (amplitude.current > -50) { // Adjust threshold as needed
        _lastAudioActivity = now;
      }
    });
    
    // Check for silence periodically
    _silenceTimer = Timer.periodic(
      const Duration(milliseconds: 500), 
      (timer) async {
        if (!_isRecording) {
          timer.cancel();
          return;
        }
        
        try {
          final now = DateTime.now();
          
          if (_lastAudioActivity != null) {
            // Check if silence has persisted for 5 seconds
            final silenceDuration = now.difference(_lastAudioActivity!);
            if (silenceDuration.inSeconds >= 5) {
              debugPrint('Silence detected for 5 seconds, stopping recording');
              await stopRecording();
            }
          }
        } catch (e) {
          debugPrint('Error in silence detection: $e');
        }
      }
    );
  }

  // Stop recording and return file path
  Future<String?> stopRecording() async {
    _silenceTimer?.cancel();
    _amplitudeSubscription?.cancel();
    
    if (_isRecording) {
      try {
        final path = await _audioRecorder.stop();
        _isRecording = false;
        return path;
      } catch (e) {
        debugPrint('Error stopping recording: $e');
      }
    }
    return null;
  }

  // Clean up resources
  Future<void> dispose() async {
    _silenceTimer?.cancel();
    _amplitudeSubscription?.cancel();
    await _audioRecorder.dispose();
  }

  bool get isRecording => _isRecording;
}
