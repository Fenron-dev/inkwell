import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Returns true if [text] looks like an http/https URL.
bool looksLikeUrl(String text) {
  final t = text.trim();
  return t.startsWith('http://') || t.startsWith('https://');
}

/// Normalizes common OCR mis-reads around the `://` separator so that
/// `https:l/github.com`, `https:llgithub.com`, `http :// …` etc. are
/// recovered before URL extraction.
String _fixOcrScheme(String text) {
  // Collapse whitespace inside a likely scheme prefix
  var out = text.replaceAllMapped(
    RegExp(r'(https?)\s*:?\s*[:/l]{1,3}\s*/', caseSensitive: false),
    (m) => '${m[1]}://',
  );
  // ":ll" or ":l/" are frequent OCR reads of "://"
  out = out
      .replaceAll(':ll', '://')
      .replaceAll(':l/', '://')
      .replaceAll(':///', '://');
  return out;
}

/// Extracts http/https URLs from [text] (e.g. OCR output).
///
/// Also promotes bare `www.` and well-known domain-like tokens
/// (e.g. `github.com/foo`) that lack a scheme.
List<String> extractUrls(String text) {
  final fixed = _fixOcrScheme(text);

  final results = <String>{};

  // Primary: proper https?:// URLs
  final schemePattern = RegExp(
    r'https?://[^\s\[\](){}<>^|]+',
    caseSensitive: false,
  );
  for (final m in schemePattern.allMatches(fixed)) {
    final url = m.group(0)!.replaceAll(RegExp(r'[.,;:!?\])]$'), '');
    if (url.length > 10) results.add(url);
  }

  // Fallback: bare www. links
  if (results.isEmpty) {
    final wwwPattern = RegExp(
      r'www\.[a-z0-9\-]+\.[a-z]{2,}[^\s\[\](){}<>^|]*',
      caseSensitive: false,
    );
    for (final m in wwwPattern.allMatches(fixed)) {
      final url = 'https://${m.group(0)!.replaceAll(RegExp(r'[.,;:!?]$'), '')}';
      if (url.length > 12) results.add(url);
    }
  }

  return results.toList();
}

/// Fetches the `<title>` of a web page. Returns null on any error.
Future<String?> fetchPageTitle(String url) async {
  try {
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Inkwell/1.0)',
          'Accept': 'text/html',
        })
        .timeout(const Duration(seconds: 6));

    if (response.statusCode < 200 || response.statusCode >= 400) return null;

    final match = RegExp(
      r'<title[^>]*>(.*?)</title>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(response.body);

    final raw = match?[1];
    if (raw == null || raw.trim().isEmpty) return null;

    return raw
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  } catch (_) {
    return null;
  }
}

/// Formats a bookmark line as stored in the journal.
///
/// Example: `🔖 [YouTube — My Video](https://…) — 15. Jan`
String formatBookmark(String url, String? title, DateTime date) {
  final label = title ?? url;
  final dateStr = DateFormat('d. MMM').format(date);
  return '🔖 [$label]($url) — $dateStr';
}
