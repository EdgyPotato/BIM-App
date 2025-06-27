import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class BackendController {
  final _audioRecorder = AudioRecorder();
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
        // Create audio directory if it doesn't exist
        await _createAudioDirectory();
      } else {
        debugPrint("Microphone permission denied");
      }
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
    }
  }

  // Create permanent audio directory
  Future<void> _createAudioDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio_recordings');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
        debugPrint('Created audio directory: ${audioDir.path}');
      }
    } catch (e) {
      debugPrint('Error creating audio directory: $e');
    }
  }

  // Generate unique filename for audio recording
  String _generateAudioFileName() {
    final timestamp = DateTime.now();
    return 'speech_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}.m4a';
  }

  // Start recording audio
  Future<void> startRecording() async {
    if (_isRecording) return;
    
    try {
      // Get documents directory for permanent storage
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio_recordings');
      
      // Ensure directory exists
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      // Generate unique filename
      final fileName = _generateAudioFileName();
      _recordingPath = '${audioDir.path}/$fileName';
      
      // Configure recording
      if (_recordingPath != null) {
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

  // Get audio recordings directory path
  static Future<String> getAudioDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/audio_recordings';
  }

  // Check if audio file exists
  static Future<bool> audioFileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get audio file size
  static Future<int> getAudioFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
    return 0;
  }

  // Clean up old audio files (older than 30 days)
  static Future<void> cleanupOldAudioFiles() async {
    try {
      final audioDir = Directory(await getAudioDirectoryPath());
      if (await audioDir.exists()) {
        final files = audioDir.listSync();
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            if (stat.modified.isBefore(thirtyDaysAgo)) {
              await file.delete();
              debugPrint('Deleted old audio file: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old audio files: $e');
    }
  }
}
