import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deeix_client/features/update/data/update_service.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);
  int status;
  String body;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _release({
  String tag = 'v1.2.0',
  bool draft = false,
  bool prerelease = false,
}) => {
  'tag_name': tag,
  'name': 'Deeix $tag',
  'body': '- 新功能',
  'html_url': 'https://github.com/zhuhedong/deeix-client/releases/tag/$tag',
  'draft': draft,
  'prerelease': prerelease,
  'assets': [
    for (final n in [
      'deeix-client-$tag-arm64-v8a.apk',
      'deeix-client-$tag-armeabi-v7a.apk',
      'deeix-client-$tag-x86_64.apk',
      'deeix-client-$tag-universal.apk',
      'SHA256SUMS.txt',
    ])
      {
        'name': n,
        'size': 100,
        'browser_download_url': 'https://example.com/$n',
      },
  ],
};

void main() {
  group('AppVersion', () {
    test('parses with v prefix and build metadata', () {
      final v = AppVersion.tryParse('v1.2.3+45')!;
      expect('$v', '1.2.3');
      expect(AppVersion.tryParse('1.2')!.patch, 0);
      expect(AppVersion.tryParse('abc'), isNull);
      expect(AppVersion.tryParse('1.x.0'), isNull);
    });

    test('orders numerically and prerelease < release', () {
      AppVersion v(String s) => AppVersion.tryParse(s)!;
      expect(v('1.10.0') > v('1.9.9'), isTrue);
      expect(v('2.0.0') > v('1.99.99'), isTrue);
      expect(v('1.2.0') > v('1.2.0-beta.2'), isTrue);
      expect(v('1.2.0-beta.10') > v('1.2.0-beta.2'), isTrue);
      expect(v('1.2.0-rc.1') > v('1.2.0-beta.9'), isTrue);
      expect(v('1.2.0+9') == v('1.2.0+1'), isTrue);
    });
  });

  group('release parsing / picking', () {
    test('parses GitHub release JSON', () {
      final r = ReleaseInfo.fromGitHub(_release());
      expect(r.version.toString(), '1.2.0');
      expect(r.assets, hasLength(5));
      expect(r.checksumAsset!.name, 'SHA256SUMS.txt');
      expect(r.isStable, isTrue);
    });

    test('only newer stable releases are offered', () {
      expect(
        pickUpdate(ReleaseInfo.fromGitHub(_release()), '1.1.0'),
        isNotNull,
      );
      expect(pickUpdate(ReleaseInfo.fromGitHub(_release()), '1.2.0'), isNull);
      expect(pickUpdate(ReleaseInfo.fromGitHub(_release()), '1.3.0'), isNull);
      expect(
        pickUpdate(ReleaseInfo.fromGitHub(_release(draft: true)), '1.0.0'),
        isNull,
      );
      expect(
        pickUpdate(ReleaseInfo.fromGitHub(_release(prerelease: true)), '1.0.0'),
        isNull,
      );
      expect(
        pickUpdate(ReleaseInfo.fromGitHub(_release(tag: 'v2.0.0-beta.1')), '1'),
        isNull,
      );
    });
  });

  group('selectApkAsset', () {
    final assets = ReleaseInfo.fromGitHub(_release()).assets;
    test('matches device ABI', () {
      expect(selectApkAsset(assets, 'arm64-v8a')!.name, contains('arm64-v8a'));
      expect(selectApkAsset(assets, 'armeabi-v7a')!.name, contains('v7a'));
    });
    test('falls back to universal', () {
      expect(selectApkAsset(assets, 'x86')!.name, contains('universal'));
      expect(selectApkAsset(assets, null)!.name, contains('universal'));
    });
    test('single APK without ABI suffix counts as universal', () {
      const only = [
        ReleaseAsset(name: 'app-release.apk', downloadUrl: 'u'),
        ReleaseAsset(name: 'notes.txt', downloadUrl: 'u'),
      ];
      expect(selectApkAsset(only, 'arm64-v8a')!.name, 'app-release.apk');
      expect(selectApkAsset(const [], 'arm64-v8a'), isNull);
    });
  });

  test('parseSha256Sums', () {
    final h = 'a' * 64;
    final m = parseSha256Sums('$h  deeix.apk\n${'B' * 64} *other.apk\nbad\n');
    expect(m['deeix.apk'], h);
    expect(m['other.apk'], 'b' * 64);
    expect(m, hasLength(2));
  });

  group('throttle / ignore', () {
    final now = DateTime(2026, 10, 13, 12);
    test('auto check at most once per 24h', () {
      expect(shouldAutoCheck(now: now), isTrue);
      expect(
        shouldAutoCheck(
          now: now,
          lastCheck: now.subtract(const Duration(hours: 23)),
        ),
        isFalse,
      );
      expect(
        shouldAutoCheck(
          now: now,
          lastCheck: now.subtract(const Duration(hours: 24)),
        ),
        isTrue,
      );
      expect(
        shouldAutoCheck(now: now, lastCheck: now.add(const Duration(days: 1))),
        isTrue,
      );
    });

    test('ignored version suppressed only for auto checks', () {
      final r = ReleaseInfo.fromGitHub(_release());
      expect(shouldPrompt(update: r, ignoredVersion: '1.2.0'), isFalse);
      expect(shouldPrompt(update: r, ignoredVersion: '1.1.0'), isTrue);
      expect(
        shouldPrompt(update: r, ignoredVersion: '1.2.0', manual: true),
        isTrue,
      );
    });
  });

  group('UpdateService.check (mocked GitHub)', () {
    late SharedPreferences prefs;
    late _Adapter adapter;
    late UpdateService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      adapter = _Adapter(200, jsonEncode(_release()));
      final dio = Dio()..httpClientAdapter = adapter;
      service = UpdateService(prefs, dio: dio, version: () async => '1.1.0');
    });

    test('finds update, then throttles the next auto check', () async {
      final now = DateTime(2026, 10, 13);
      final first = await service.check(now: now);
      expect(first!.update!.version.toString(), '1.2.0');
      final second = await service.check(
        now: now.add(const Duration(hours: 1)),
      );
      expect(second, isNull);
      expect(adapter.calls, 1);
      final manual = await service.check(
        manual: true,
        now: now.add(const Duration(hours: 1)),
      );
      expect(manual!.update, isNotNull);
    });

    test('ignored version hidden on auto check, shown on manual', () async {
      await service.ignore(ReleaseInfo.fromGitHub(_release()));
      final auto = await service.check(now: DateTime(2026, 10, 13));
      expect(auto!.update, isNull);
      final manual = await service.check(manual: true);
      expect(manual!.update, isNotNull);
    });

    test('404 (no release yet) is not an error', () async {
      adapter
        ..status = 404
        ..body = '{"message":"Not Found"}';
      final r = await service.check(manual: true);
      expect(r!.update, isNull);
      expect(r.error, isNull);
    });

    test('network failure reports an error', () async {
      adapter
        ..status = 500
        ..body = '{}';
      final r = await service.check(manual: true);
      expect(r!.error, contains('检查更新失败'));
    });
  });
}
