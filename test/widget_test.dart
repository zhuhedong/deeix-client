import 'package:flutter_test/flutter_test.dart';

import 'package:deeix_client/core/constants/app_config.dart';

void main() {
  test('AppConfig smoke', () {
    expect(AppConfig.appName, isNotEmpty);
    expect(AppConfig.apiPrefix, '/api/v1');
  });
}
