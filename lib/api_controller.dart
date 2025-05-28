import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class ApiController {
  static const String apiUrl = 'https://bim-backend-api.onrender.com/healthz';
  
  // Check if the API is available
  static Future<bool> checkApiStatus() async {
    try {
      final response = await http.head(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API Status check error: $e');
      return false;
    }
  }
}
