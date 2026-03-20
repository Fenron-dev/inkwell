import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkwell/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../core/utils/url_utils.dart';
import '../../core/vault/entry_refresh_provider.dart';
import '../../core/vault/vault_provider.dart';
import '../ocr_scanner/ocr_scanner_screen.dart';

/// Modal bottom sheet for quickly appending a note to today's entry.
///
/// When [initialUrl] is provided the dialog starts in bookmark mode:
/// it fetches the page title in the background and formats the entry
/// as `🔖 [title](url) — d. MMM`.
///
/// Open with [QuickCaptureDialog.show].
class QuickCaptureDialog extends ConsumerStatefulWidget {
  const QuickCaptureDialog({super.key, this.initialUrl});

  final String? initialUrl;

  static Future<void> show(BuildContext context, {String? initialUrl}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuickCaptureDialog(initialUrl: initialUrl),
    );
  }

  @override
  ConsumerState<QuickCaptureDialog> createState() =>
      _QuickCaptureDialogState();
}

class _QuickCaptureDialogState extends ConsumerState<QuickCaptureDialog> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  // Bookmark mode state
  String? _url;
  String? _pageTitle;
  bool _fetchingTitle = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      _setUrl(widget.initialUrl!);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setUrl(String url) {
    setState(() {
      _url = url;
      _pageTitle = null;
      _fetchingTitle = true;
    });
    fetchPageTitle(url).then((title) {
      if (mounted) {
        setState(() {
          _pageTitle = title;
          _fetchingTitle = false;
        });
      }
    });
  }

  Future<void> _scanUrl() async {
    final url = await OcrScannerScreen.scan(context);
    if (url != null && mounted) _setUrl(url);
  }

  String _buildBookmarkLine() {
    final title = (_pageTitle?.isNotEmpty ?? false) ? _pageTitle! : _url!;
    return formatBookmark(_url!, title, DateTime.now());
  }

  Future<void> _save() async {
    String text;
    if (_url != null) {
      text = _buildBookmarkLine();
    } else {
      text = _ctrl.text.trim();
    }
    if (text.isEmpty) return;

    final vault = ref.read(vaultProvider).valueOrNull;
    if (vault == null) return;

    setState(() => _saving = true);

    try {
      final service = ref.read(vaultServiceProvider);
      final today = DateTime.now();
      var entry = await service.readEntry(vault, today);
      entry ??= await service.createEntryFromTemplate(vault, today);

      final timestamp = DateFormat('HH:mm').format(today);
      final appended = _url != null
          ? '${entry.body.trimRight()}\n\n$text\n'
          : '${entry.body.trimRight()}\n\n**$timestamp** $text\n';
      await service.writeEntry(vault, entry.copyWith(body: appended));
      // Signal the daily-notes editor to reload so the captured text is
      // visible immediately without navigating away first.
      ref.read(entryRefreshProvider.notifier).state++;

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.quickCaptureSaved)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            l10n.quickCaptureTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // ── Bookmark mode ──────────────────────────────────────────────
          if (_url != null) ...[
            _BookmarkCard(
              url: _url!,
              title: _pageTitle,
              fetchingTitle: _fetchingTitle,
              onClear: () => setState(() {
                _url = null;
                _pageTitle = null;
              }),
            ),
            const SizedBox(height: 12),
          ] else ...[
            // ── Text mode ────────────────────────────────────────────────
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 5,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: l10n.quickCaptureHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // OCR scan button (mobile only)
            if (isMobile)
              OutlinedButton.icon(
                onPressed: _scanUrl,
                icon: const Icon(Icons.document_scanner_outlined, size: 18),
                label: Text(l10n.quickCaptureScanUrl),
              ),
            const SizedBox(height: 4),
          ],

          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_url != null
                    ? l10n.bookmarkSave
                    : l10n.quickCaptureSave),
          ),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final String url;
  final String? title;
  final bool fetchingTitle;
  final VoidCallback onClear;

  const _BookmarkCard({
    required this.url,
    required this.title,
    required this.fetchingTitle,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔖', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fetchingTitle)
                  Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.bookmarkTitleFetching,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                else if (title != null)
                  Text(
                    title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  url,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
