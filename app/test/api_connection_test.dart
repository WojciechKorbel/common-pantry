import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Connection to Render', () async {
    final url = Uri.parse('https://common-pantry-api.onrender.com/admin/');
    final response = await http.get(url);

    expect(response.statusCode, 200);
  }, timeout: const Timeout(Duration(seconds: 90)));
}

// run
// flutter test test/api_connection_test.dart
// to test if the connection to the remote server is working correctly with the application.