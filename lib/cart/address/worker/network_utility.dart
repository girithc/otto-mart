import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class NetworkUtility {
  static Future<String?> fetchUrl(Uri uri,
      {Map<String, String>? headers}) async {
    try {
      //print("Entered NetworkUtility.fetchUrl");
      final response = await http.get(uri, headers: headers);
      //print("Response got");
      if (response.statusCode == 200) {
        //print("response successful $response.body");
        return response.body;
      }
    } catch (err) {
      final Logger logger = Logger();
      logger.e(err.toString());
    }
    return null;
  }
}
