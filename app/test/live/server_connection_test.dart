@Tags(['live'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Render server answers the health check',
        () async {
      final response = await Dio().get<dynamic>('https://common-pantry-api.onrender.com/');

      expect(response.statusCode, 200);
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}