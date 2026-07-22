import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PKCE pair for OAuth / OIDC native login.
class PkcePair {
  const PkcePair({required this.verifier, required this.challenge});

  final String verifier;
  final String challenge;

  static PkcePair generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final verifier = base64UrlEncode(bytes).replaceAll('=', '');
    final digest = sha256.convert(utf8.encode(verifier));
    final challenge = base64UrlEncode(digest.bytes).replaceAll('=', '');
    return PkcePair(verifier: verifier, challenge: challenge);
  }
}
