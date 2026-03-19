import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Returns true if [text] looks like an http/https URL.
bool looksLikeUrl(String text) {
  final t = text.trim();
  return t.startsWith('http://') || t.startsWith('https://');
}

/// Extracts http/https URLs from [text] (e.g. OCR output).
List<String> extractUrls(String text) {
  final pattern = RegExp(
    r'https?://[^\s\[\](){}<>^|]+',
    caseSensitive: false,
  );
  return pattern
      .allMatches(text)
      .map((m) => m.group(0)!.replaceAll(RegExp(r'[.,;:!?\])]$'), ''))
      .where((u) => u.length > 10)
      .toSet()
      .toList();
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
