import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class ApiController {
  static const String baseUrl = 'https://bim-backend-api.onrender.com';
  static const String healthEndpoint = '$baseUrl/healthz';
  static const String transcribeEndpoint = '$baseUrl/transcribe';
  static const String translateEndpoint = '$baseUrl/translate';
  
  static const String modelDownloadBaseUrl =
      'https://github.com/EdgyPotato/Yolo-Model/releases/latest/download';
  
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
  
  // Send text for translation
  static Future<String?> translateText(String text, {String targetLang = 'malay'}) async {
    try {
      debugPrint('Sending text to translation API, target language: $targetLang');
      
      // Create request with JSON body
      final response = await http.post(
        Uri.parse(translateEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'target_lang': targetLang,
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
      final client = http.Client();
      final request = await client.send(http.Request('GET', Uri.parse(url)));
      final contentLength = request.contentLength ?? 0;

      final bytes = <int>[];
      int downloadedBytes = 0;

      await for (final chunk in request.stream) {
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          onProgress?.call(progress);
        }
      }

      client.close();

      if (bytes.isNotEmpty) {
        final modelFile = File(destinationPath);
        await modelFile.writeAsBytes(bytes);
        return modelFile.path;
      }
    } catch (e) {
      debugPrint('Failed to download model: $e');
    }

    return null;
  }
}
