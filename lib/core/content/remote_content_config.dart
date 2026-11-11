/// Build-time switch for remotely published puzzles (Studio Content Studio).
///
/// Off unless the build passes all three defines:
///
///     flutter run \
///       --dart-define=NONOGRAM_REMOTE_CONTENT=true \
///       --dart-define=NONOGRAM_CONTENT_BACKEND_URL=http://127.0.0.1:3000 \
///       --dart-define=NONOGRAM_CONTENT_HMAC_KEY=<the backend's HMAC_SHARED_SECRET>
///
/// When off, the game stays offline exactly as before: no guest sign-in, no request, no
/// timer, no file is written.
class RemoteContentConfig {
  final bool enabled;
  final String backendUrl;
  final String hmacKey;

  /// Content type the game reads.
  static const String contentType = 'nonogram';

  const RemoteContentConfig({required this.enabled, this.backendUrl = '', this.hmacKey = ''});

  static const RemoteContentConfig disabled = RemoteContentConfig(enabled: false);

  factory RemoteContentConfig.fromEnvironment() {
    const flag = bool.fromEnvironment('NONOGRAM_REMOTE_CONTENT');
    const url = String.fromEnvironment('NONOGRAM_CONTENT_BACKEND_URL');
    const key = String.fromEnvironment('NONOGRAM_CONTENT_HMAC_KEY');
    return RemoteContentConfig.of(flag: flag, backendUrl: url, hmacKey: key);
  }

  /// Enabled only when the flag is on and both the backend URL and the key are present.
  factory RemoteContentConfig.of({required bool flag, required String backendUrl, required String hmacKey}) {
    final url = backendUrl.trim();
    final uri = Uri.tryParse(url);
    final usable = flag && hmacKey.isNotEmpty && uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    return usable ? RemoteContentConfig(enabled: true, backendUrl: url, hmacKey: hmacKey) : disabled;
  }
}
