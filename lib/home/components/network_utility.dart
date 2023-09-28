import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class NetworkUtility {
  static Future<String?> fetchUrl(Uri uri,
      {Map<String, String>? headers}) async {
    final Logger logger = Logger();
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (err) {
      logger.e(err.toString());
    }
    return null;
  }
}
