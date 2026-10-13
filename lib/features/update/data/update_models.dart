/// Pure update logic (no Flutter / IO) so it is unit-testable.
library;

/// Minimal semantic version: `major.minor.patch[-pre][+build]`, optional `v`.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch, [this.preRelease = '']);

  final int major;
  final int minor;
  final int patch;

  /// Empty for a normal release; any pre-release sorts before the release.
  final String preRelease;

  bool get isPreRelease => preRelease.isNotEmpty;

  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    s = s.split('+').first; // build metadata never affects precedence
    final dash = s.indexOf('-');
    final pre = dash >= 0 ? s.substring(dash + 1) : '';
    final core = dash >= 0 ? s.substring(0, dash) : s;
    final parts = core.split('.');
    if (parts.isEmpty || parts.length > 3) return null;
    final nums = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0) return null;
      nums.add(n);
    }
    while (nums.length < 3) {
      nums.add(0);
    }
    return AppVersion(nums[0], nums[1], nums[2], pre);
  }

  @override
  int compareTo(AppVersion o) {
    for (final d in [major - o.major, minor - o.minor, patch - o.patch]) {
      if (d != 0) return d.sign;
    }
    if (preRelease == o.preRelease) return 0;
    if (preRelease.isEmpty) return 1;
    if (o.preRelease.isEmpty) return -1;
    return _comparePre(preRelease, o.preRelease);
  }

  static int _comparePre(String a, String b) {
    final pa = a.split('.');
    final pb = b.split('.');
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      final na = int.tryParse(pa[i]);
      final nb = int.tryParse(pb[i]);
      final c = (na != null && nb != null)
          ? na.compareTo(nb)
          : (na != null)
          ? -1
          : (nb != null)
          ? 1
          : pa[i].compareTo(pb[i]);
      if (c != 0) return c.sign;
    }
    return pa.length.compareTo(pb.length).sign;
  }

  bool operator >(AppVersion o) => compareTo(o) > 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);

  @override
  String toString() =>
      '$major.$minor.$patch${preRelease.isEmpty ? '' : '-$preRelease'}';
}

class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    this.size = 0,
  });

  final String name;
  final String downloadUrl;
  final int size;

  factory ReleaseAsset.fromGitHub(Map<String, dynamic> j) => ReleaseAsset(
    name: '${j['name'] ?? ''}',
    downloadUrl: '${j['browser_download_url'] ?? ''}',
    size: j['size'] is int ? j['size'] as int : 0,
  );
}

class ReleaseInfo {
  const ReleaseInfo({
    required this.tag,
    required this.version,
    this.name = '',
    this.notes = '',
    this.htmlUrl = '',
    this.draft = false,
    this.preRelease = false,
    this.assets = const [],
  });

  final String tag;
  final AppVersion? version;
  final String name;
  final String notes;
  final String htmlUrl;
  final bool draft;
  final bool preRelease;
  final List<ReleaseAsset> assets;

  /// Drafts, GitHub pre-releases and `-beta`-style tags are never offered.
  bool get isStable =>
      !draft && !preRelease && version != null && !version!.isPreRelease;

  factory ReleaseInfo.fromGitHub(Map<String, dynamic> j) {
    final tag = '${j['tag_name'] ?? ''}';
    return ReleaseInfo(
      tag: tag,
      version: AppVersion.tryParse(tag),
      name: '${j['name'] ?? ''}',
      notes: '${j['body'] ?? ''}',
      htmlUrl: '${j['html_url'] ?? ''}',
      draft: j['draft'] == true,
      preRelease: j['prerelease'] == true,
      assets: (j['assets'] is List ? j['assets'] as List : const [])
          .whereType<Map>()
          .map((e) => ReleaseAsset.fromGitHub(Map<String, dynamic>.from(e)))
          .where((a) => a.name.isNotEmpty && a.downloadUrl.isNotEmpty)
          .toList(),
    );
  }

  /// Checksum file published by the release workflow.
  ReleaseAsset? get checksumAsset {
    for (final a in assets) {
      if (a.name.toUpperCase() == 'SHA256SUMS.TXT') return a;
    }
    return null;
  }
}

/// Returns the newer stable release, or null when up to date / not offerable.
ReleaseInfo? pickUpdate(ReleaseInfo release, String currentVersion) {
  final current = AppVersion.tryParse(currentVersion);
  if (!release.isStable || current == null) return null;
  return release.version! > current ? release : null;
}

/// Picks the APK for [abi] (e.g. `arm64-v8a`), else the universal APK.
///
/// Asset names follow the release workflow:
/// `deeix-client-v1.2.0-arm64-v8a.apk`, `deeix-client-v1.2.0-universal.apk`.
ReleaseAsset? selectApkAsset(List<ReleaseAsset> assets, String? abi) {
  final apks = assets
      .where((a) => a.name.toLowerCase().endsWith('.apk'))
      .toList();
  if (apks.isEmpty) return null;
  if (abi != null && abi.isNotEmpty) {
    // Match the ABI as a whole token (`x86` must not match `x86_64`).
    final token = RegExp('(^|[-_.])${RegExp.escape(abi.toLowerCase())}[-.]');
    for (final a in apks) {
      if (token.hasMatch(a.name.toLowerCase())) return a;
    }
  }
  for (final a in apks) {
    final n = a.name.toLowerCase();
    if (n.contains('universal')) return a;
  }
  // A single APK without an ABI suffix (e.g. `app-release.apk`) is universal.
  const abis = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'];
  for (final a in apks) {
    final n = a.name.toLowerCase();
    if (!abis.any((x) => RegExp('[-_.]$x[-.]').hasMatch(n))) return a;
  }
  return null;
}

/// Parses `sha256sum` output: `<hex>  <file name>` per line.
Map<String, String> parseSha256Sums(String text) {
  final out = <String, String>{};
  for (final line in text.split('\n')) {
    final m = RegExp(r'^([0-9a-fA-F]{64})\s+\*?(.+)$').firstMatch(line.trim());
    if (m != null) out[m.group(2)!.trim()] = m.group(1)!.toLowerCase();
  }
  return out;
}

/// Startup-check policy: at most once per [interval]; manual checks bypass it.
bool shouldAutoCheck({
  required DateTime now,
  DateTime? lastCheck,
  Duration interval = const Duration(hours: 24),
}) {
  if (lastCheck == null) return true;
  if (lastCheck.isAfter(now)) return true; // clock moved back
  return now.difference(lastCheck) >= interval;
}

/// Whether an available update should be shown. Ignored versions are only
/// suppressed for automatic checks; a manual check always shows it.
bool shouldPrompt({
  required ReleaseInfo update,
  String? ignoredVersion,
  bool manual = false,
}) {
  if (manual) return true;
  final ignored = AppVersion.tryParse(ignoredVersion);
  return ignored == null || update.version! > ignored;
}
