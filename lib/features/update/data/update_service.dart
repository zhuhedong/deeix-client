import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/app_preferences.dart';
import 'update_models.dart';

export 'update_models.dart';

/// Where releases are published. Change if the repository moves.
class UpdateConfig {
  UpdateConfig._();

  static const String owner = 'zhuhedong';
  static const String repo = 'deeix-client';
  static const String latestReleaseApi =
      'https://api.github.com/repos/$owner/$repo/releases/latest';
  static const String releasesPage =
      'https://github.com/$owner/$repo/releases/latest';
  static const Duration autoCheckInterval = Duration(hours: 24);
}

/// Result of a check.
class UpdateCheck {
  const UpdateCheck({required this.currentVersion, this.update, this.error});

  final String currentVersion;
  final ReleaseInfo? update;
  final String? error;
}

enum InstallOutcome { started, needsPermission, failed }

/// GitHub-release based self update.
///
/// Uses its own [Dio] without the API interceptors so the DEEIX access token
/// is never sent to GitHub.
class UpdateService {
  UpdateService(this._prefs, {Dio? dio, Future<String> Function()? version})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(minutes: 10),
              headers: {'User-Agent': 'deeix-client-updater'},
            ),
          ),
      _version =
          version ?? (() async => (await PackageInfo.fromPlatform()).version);

  static const _kLastCheck = 'update.lastCheckMs';
  static const _kIgnored = 'update.ignoredVersion';

  final SharedPreferences _prefs;
  final Dio _dio;
  final Future<String> Function() _version;

  String? get ignoredVersion => _prefs.getString(_kIgnored);

  Future<void> ignore(ReleaseInfo r) =>
      _prefs.setString(_kIgnored, r.version.toString());

  DateTime? get lastCheck {
    final ms = _prefs.getInt(_kLastCheck);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<ReleaseInfo> fetchLatest() async {
    final res = await _dio.get<dynamic>(
      UpdateConfig.latestReleaseApi,
      options: Options(
        headers: {'Accept': 'application/vnd.github+json'},
        responseType: ResponseType.json,
      ),
    );
    final data = res.data;
    if (data is! Map) throw const FormatException('unexpected release JSON');
    return ReleaseInfo.fromGitHub(Map<String, dynamic>.from(data));
  }

  /// [manual] bypasses throttling and the ignored version.
  /// Returns null when an automatic check is skipped.
  Future<UpdateCheck?> check({bool manual = false, DateTime? now}) async {
    final t = now ?? DateTime.now();
    if (!manual &&
        !shouldAutoCheck(
          now: t,
          lastCheck: lastCheck,
          interval: UpdateConfig.autoCheckInterval,
        )) {
      return null;
    }
    final current = await _version();
    try {
      final latest = await fetchLatest();
      await _prefs.setInt(_kLastCheck, t.millisecondsSinceEpoch);
      final update = pickUpdate(latest, current);
      if (update == null) return UpdateCheck(currentVersion: current);
      if (!shouldPrompt(
        update: update,
        ignoredVersion: ignoredVersion,
        manual: manual,
      )) {
        return UpdateCheck(currentVersion: current);
      }
      return UpdateCheck(currentVersion: current, update: update);
    } on DioException catch (e) {
      // 404 = no published release yet.
      if (e.response?.statusCode == 404) {
        await _prefs.setInt(_kLastCheck, t.millisecondsSinceEpoch);
        return UpdateCheck(currentVersion: current);
      }
      return UpdateCheck(
        currentVersion: current,
        error: '检查更新失败：${e.message ?? e.type.name}',
      );
    } catch (e) {
      return UpdateCheck(currentVersion: current, error: '检查更新失败：$e');
    }
  }

  /// ABI of the running process, in Android naming.
  static String? currentAndroidAbi() {
    final abi = Abi.current();
    if (abi == Abi.androidArm64) return 'arm64-v8a';
    if (abi == Abi.androidArm) return 'armeabi-v7a';
    if (abi == Abi.androidX64) return 'x86_64';
    if (abi == Abi.androidIA32) return 'x86';
    return null;
  }

  /// Downloads the matching APK into the app cache and verifies it.
  Future<File> downloadApk(
    ReleaseInfo release, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final asset = selectApkAsset(release.assets, currentAndroidAbi());
    if (asset == null) throw Exception('该版本没有可用的安装包');

    String? expectedSha;
    final sums = release.checksumAsset;
    if (sums != null) {
      final res = await _dio.get<String>(
        sums.downloadUrl,
        options: Options(responseType: ResponseType.plain),
        cancelToken: cancelToken,
      );
      expectedSha = parseSha256Sums(res.data ?? '')[asset.name];
    }

    final dir = Directory('${(await getTemporaryDirectory()).path}/updates');
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    final file = File('${dir.path}/${asset.name}');

    await _dio.download(
      asset.downloadUrl,
      file.path,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    );

    final length = await file.length();
    if (asset.size > 0 && length != asset.size) {
      await file.delete();
      throw Exception('安装包大小不符（$length ≠ ${asset.size}），已删除');
    }
    if (expectedSha != null) {
      final digest = await sha256.bind(file.openRead()).first;
      if (digest.toString() != expectedSha) {
        await file.delete();
        throw Exception('安装包校验失败（SHA-256 不一致），已删除');
      }
    }
    return file;
  }

  /// Hands the APK to the system installer.
  Future<InstallOutcome> install(File apk) async {
    final status = await Permission.requestInstallPackages.status;
    if (!status.isGranted) {
      final asked = await Permission.requestInstallPackages.request();
      if (!asked.isGranted) return InstallOutcome.needsPermission;
    }
    final r = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );
    return switch (r.type) {
      ResultType.done => InstallOutcome.started,
      ResultType.permissionDenied => InstallOutcome.needsPermission,
      _ => InstallOutcome.failed,
    };
  }
}

final updateServiceProvider = FutureProvider<UpdateService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return UpdateService(prefs);
});
