import 'api_client.dart';

/// Normalizes media URLs coming from the backend.
///
/// Handles cases where the backend returns:
/// - Relative paths like `/uploads/...`
/// - Absolute URLs with an unexpected host/port (e.g. stale `:8081`)
///
/// The app's API base is [ApiClient.baseUrl] (e.g. `http://10.0.2.2:8081/api`).
/// Static files are served from the same host root (e.g. `http://10.0.2.2:8081/uploads/...`).
String normalizePublicUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return trimmed;

  final api = Uri.tryParse(ApiClient.baseUrl);
  if (api == null) return trimmed;

  final publicRoot = api.replace(path: '', query: null, fragment: null);

  // Relative -> prefix with our public root.
  if (trimmed.startsWith('/')) {
    return publicRoot.toString().replaceAll(RegExp(r'/$'), '') + trimmed;
  }

  final parsed = Uri.tryParse(trimmed);
  if (parsed == null || !parsed.hasScheme) {
    final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return publicRoot.toString().replaceAll(RegExp(r'/$'), '') + normalized;
  }

  // Absolute -> if it is an uploads path, force it onto our public root.
  // This fixes stale URLs like `http://10.0.2.2:8081/uploads/...`.
  if (parsed.path.startsWith('/uploads/')) {
    return publicRoot.replace(path: parsed.path).toString();
  }

  return trimmed;
}
