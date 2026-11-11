import 'package:flutter/foundation.dart';

/// Build-time switch for remotely published puzzles (Studio Content Studio).
///
/// Off unless a debug or profile build passes both defines:
///
///     flutter run \
///       --dart-define=NONOGRAM_REMOTE_CONTENT=true \
///       --dart-define=NONOGRAM_CONTENT_BACKEND_URL=http://127.0.0.1:3000
///
/// When off, the game stays offline exactly as before: no guest sign-in, no request, no
/// timer, no file is written.
///
/// Security: the game never takes the backend's shared HMAC secret. Guest sign-in
/// (`POST /v1/auth/guest`) and the content reads (`GET /v1/content/packs[/:id]`) are not
/// HMAC-verified by studio-core-backend, so the reader signs with [contentReaderSigningKey],
/// a public constant that grants nothing. A mobile build must never carry
/// `HMAC_SHARED_SECRET`: anyone can extract it, and it is what protects sync, purchases,
/// ad rewards and leaderboards for every game on that backend.
///
/// Release builds are always off until a release decision allows remote content (D-008).
class RemoteContentConfig {
  final bool enabled;
  final String backendUrl;

  /// Content type the game reads.
  static const String contentType = 'nonogram';

  /// What the SDK signs content-reader requests with. Not a secret: the routes the reader
  /// calls do not verify it, and the backend secret must not be in the app.
  static const String contentReaderSigningKey = 'nonogram-content-reader-public';

  const RemoteContentConfig({required this.enabled, this.backendUrl = ''});

  static const RemoteContentConfig disabled = RemoteContentConfig(enabled: false);

  factory RemoteContentConfig.fromEnvironment() {
    const flag = bool.fromEnvironment('NONOGRAM_REMOTE_CONTENT');
    const url = String.fromEnvironment('NONOGRAM_CONTENT_BACKEND_URL');
    return RemoteContentConfig.of(flag: flag, backendUrl: url, releaseBuild: kReleaseMode);
  }

  /// Enabled only when the flag is on, the backend URL is usable and this is not a release
  /// build.
  factory RemoteContentConfig.of({required bool flag, required String backendUrl, bool releaseBuild = false}) {
    if (releaseBuild) return disabled;
    final url = backendUrl.trim();
    final uri = Uri.tryParse(url);
    final usable = flag && uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    return usable ? RemoteContentConfig(enabled: true, backendUrl: url) : disabled;
  }
}
