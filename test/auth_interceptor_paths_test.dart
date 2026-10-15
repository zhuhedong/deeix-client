import 'package:deeix_client/core/network/auth_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public auth paths skip refresh, protected /auth/* do not', () {
    expect(AuthInterceptor.isPublicAuthPath('/auth/login'), isTrue);
    expect(AuthInterceptor.isPublicAuthPath('/auth/refresh'), isTrue);
    expect(AuthInterceptor.isPublicAuthPath('/auth/2fa/verify'), isTrue);
    expect(AuthInterceptor.isPublicAuthPath('/auth/sessions'), isFalse);
    expect(AuthInterceptor.isPublicAuthPath('/auth/logout-all'), isFalse);
    expect(
      AuthInterceptor.isPublicAuthPath('/auth/password/change/start'),
      isFalse,
    );
    expect(AuthInterceptor.isPublicAuthPath('/conversations'), isFalse);
  });
}
