import 'dart:async';
import 'package:http/http.dart' as http;

class Onlinecheck {
  // Returns true if may internet
  static Future<bool> isOnline() async {
    try {
      final resp = await http
          .get(Uri.parse('http://www.google.com'))
          .timeout(const Duration(seconds: 5));

      return resp.statusCode >= 200 && resp.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
}
