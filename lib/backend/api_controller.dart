import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'database.dart';

class ApiController {
  static const String baseUrl = 'https://bim-backend-api.onrender.com';
  static const String healthEndpoint = '$baseUrl/healthz';
  static const String transcribeEndpoint = '$baseUrl/transcribe';
  static const String translateEndpoint = '$baseUrl/translate';
  
  static const String modelDownloadBaseUrl = 'https://github.com/EdgyPotato/Yolo-Model/releases/download/v0.0.4';
  
  // Check if the API is available
  static Future<bool> checkApiStatus() async {
    try {
      final response = await http.head(Uri.parse(healthEndpoint))
          .timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API Status check error: $e');
      return false;
    }
  }
  
  // Send audio file for transcription
  static Future<String?> transcribeAudio(File audioFile) async {
    try {
      debugPrint('Sending file to transcription API: ${audioFile.path}');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(transcribeEndpoint));
      
      // Get file extension to determine content type
      final fileExtension = path.extension(audioFile.path).toLowerCase();
      final contentType = _getContentTypeFromExtension(fileExtension);
      
      debugPrint('Using content type: $contentType for file extension: $fileExtension');
      
      // Add file to request with proper content type
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioFile.path,
          contentType: contentType,
        ),
      );
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        debugPrint('Transcription successful: ${jsonResponse['text']}');
        return jsonResponse['text'];
      } else {
        debugPrint('API Error: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Transcription error: $e');
      return null;
    }
  }
  
  // Get user's preferred translation language
  static Future<String> getUserTranslationLanguage() async {
    try {
      final settings = await TranslationDatabase.instance.getSettings();
      return settings.translationLanguage;
    } catch (e) {
      debugPrint('Error getting translation language: $e');
      return 'malay'; // Default fallback
    }
  }

  // Send text for translation (updated to use user's preferred language by default)
  static Future<String?> translateText(String text, {String? targetLang}) async {
    try {
      // Use provided language or get user's preferred language
      final language = targetLang ?? await getUserTranslationLanguage();
      debugPrint('Sending text to translation API, target language: $language');
      
      // Create request with JSON body
      final response = await http.post(
        Uri.parse(translateEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'target_lang': language,
          'temperature': 0.2,
          'max_tokens': 100,
          'top_p': 0.7
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final translatedText = jsonResponse['translated_text'];
        debugPrint('Translation successful');
        return translatedText;
      } else {
        debugPrint('API Error: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      return null;
    }
  }
  
  // Send text for reconstruction
  static Future<String?> reconstructText(String text) async {
    try {
      debugPrint('Sending text to reconstruction API');
      
      // Create request with JSON body
      final response = await http.post(
        Uri.parse('$baseUrl/reconstruct'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'temperature': 0.2,
          'max_tokens': 100,
          'top_p': 0.8
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final reconstructedText = jsonResponse['reconstructed_text'];
        debugPrint('Reconstruction successful');
        return reconstructedText;
      } else {
        debugPrint('API Error: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Reconstruction error: $e');
      return null;
    }
  }
  
  // Helper method to determine content type from file extension
  static MediaType _getContentTypeFromExtension(String extension) {
    switch (extension) {
      case '.wav':
        // Use audio/wav which is explicitly listed in the supported types
        return MediaType('audio', 'wav');
      case '.mp3':
        // Use audio/mpeg which is explicitly listed in the supported types
        return MediaType('audio', 'mpeg');
      case '.flac':
        // Use audio/flac which is explicitly listed in the supported types
        return MediaType('audio', 'flac');
      case '.ogg':
        // Use audio/ogg which is explicitly listed in the supported types
        return MediaType('audio', 'ogg');
      case '.m4a':
        // For aacLc, aacEld, aacHe encoders (all use m4a extension)
        return MediaType('audio', 'x-m4a'); // Using x-m4a as it's in the supported list
      case '.opus':
        // For opus encoder
        return MediaType('audio', 'webm', {'codecs': 'opus'});
      case '.3gp':
        // For amrNb and amrWb encoders
        return MediaType('audio', 'AMR'); // Using AMR as it's in the supported list
      case '.pcm':
        // For pcm16bits encoder
        return MediaType('audio', 'x-wav'); // Closest match in supported types
      default:
        debugPrint('Unknown file extension: $extension, using audio/wav as default');
        return MediaType('audio', 'wav');
    }
  }

  static Future<String?> downloadModel(
    String modelName,
    String destinationPath,
    {void Function(double progress)? onProgress}
  ) async {
    final url = '$modelDownloadBaseUrl/$modelName.tflite';
    
    try {
      debugPrint('Starting model download from: $url');
      debugPrint('Destination path: $destinationPath');
      
      final client = http.Client();
      
      // Add timeout and better error handling
      final request = http.Request('GET', Uri.parse(url));
      final streamedResponse = await client.send(request)
          .timeout(const Duration(minutes: 10));
      
      // Check if the response is successful
      if (streamedResponse.statusCode != 200) {
        debugPrint('Download failed with status code: ${streamedResponse.statusCode}');
        debugPrint('Response reason: ${streamedResponse.reasonPhrase}');
        client.close();
        return null;
      }
      
      final contentLength = streamedResponse.contentLength ?? 0;
      debugPrint('Content length: $contentLength bytes');
      
      if (contentLength == 0) {
        debugPrint('Warning: Content length is 0 or unknown');
      }
      
      final bytes = <int>[];
      int downloadedBytes = 0;
      
      await for (final chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;
        
        if (contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          debugPrint('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
          onProgress?.call(progress);
        }
      }
      
      client.close();
      
      if (bytes.isEmpty) {
        debugPrint('Error: No data received from server');
        return null;
      }
      
      debugPrint('Download completed. Total bytes: ${bytes.length}');
      
      // Ensure the destination directory exists
      final modelFile = File(destinationPath);
      final directory = modelFile.parent;
      if (!await directory.exists()) {
        debugPrint('Creating directory: ${directory.path}');
        await directory.create(recursive: true);
      }
      
      // Write the file
      await modelFile.writeAsBytes(bytes);
      debugPrint('Model saved successfully to: ${modelFile.path}');
      
      // Verify the file was written correctly
      if (await modelFile.exists()) {
        final fileSize = await modelFile.length();
        debugPrint('File verification: Size = $fileSize bytes');
        return modelFile.path;
      } else {
        debugPrint('Error: File was not saved properly');
        return null;
      }
      
    } catch (e) {
      debugPrint('Failed to download model: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return null;
    }
  }
}
