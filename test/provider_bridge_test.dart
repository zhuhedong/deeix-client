import 'package:deeix_client/core/auth/pkce.dart';
import 'package:deeix_client/core/network/api_endpoints.dart';
import 'package:deeix_client/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provider auth bridge endpoints (DEEIX-Chat 0.4.4)', () {
    expect(
      ApiEndpoints.providerAuthorize('dd'),
      '/auth/providers/dd/authorize',
    );
    expect(ApiEndpoints.providerExchange('dd'), '/auth/providers/dd/exchange');
  });

  test('native client id / redirect match server contract', () {
    expect(AuthRepository.providerBridgeClientId, 'com.deeix.chat.native');
    expect(
      AuthRepository.providerBridgeRedirectUri,
      'com.deeix.chat:/oauth/callback',
    );
    expect(
      AuthRepository.providerBridgeRedirectUri.startsWith(
        '${AuthRepository.providerBridgeCallbackScheme}:',
      ),
      isTrue,
    );
  });

  test('PKCE verifier/challenge and client state satisfy length rules', () {
    final pkce = PkcePair.generate();
    final state = PkcePair.randomToken();
    for (final v in [pkce.verifier, pkce.challenge, state]) {
      expect(v.length, inInclusiveRange(43, 128));
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(v), isTrue);
    }
  });
}
