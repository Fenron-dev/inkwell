import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/search/search_provider.dart';
import '../../core/settings/settings_provider.dart';
import '../../core/vault/vault_provider.dart';
import '../../models/frontmatter.dart';
import '../../models/journal_entry.dart';
import 'markdown_toolbar.dart';
import 'properties_panel.dart';

/// The main markdown editor with auto-save and switchable preview modes.
class EditorScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const EditorScreen({super.key, required this.date});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

enum EditorMode { edit, preview, split }

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _saveTimer;
  JournalEntry? _entry;
  bool _loading = true;
  EditorMode _mode = EditorMode.edit;
  bool _showProperties = false;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveNow();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    final vault = ref.read(vaultProvider).valueOrNull;
    if (vault == null) return;

    final service = ref.read(vaultServiceProvider);
    var entry = await service.readEntry(vault, widget.date);
    entry ??= await service.createEntryFromTemplate(vault, widget.date);

    if (mounted) {
      setState(() {
        _entry = entry;
        _controller.text = entry!.body;
        _loading = false;
      });
    }
  }

  void _onTextChanged() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveNow);
  }

  Future<void> _saveNow() async {
    final entry = _entry;
    final vault = ref.read(vaultProvider).valueOrNull;
    if (entry == null || vault == null) return;

    final updated = entry.copyWith(
      body: _controller.text,
      lastModified: DateTime.now(),
    );
    _entry = updated;

    final service = ref.read(vaultServiceProvider);
    await service.writeEntry(vault, updated);

    // Keep search index in sync (fire-and-forget — non-blocking).
    ref.read(searchIndexProvider)?.indexEntry(updated.filePath, updated.date);
  }

  void _onFrontmatterChanged(Frontmatter frontmatter) {
    if (_entry == null) return;
    setState(() {
      _entry = _entry!.copyWith(frontmatter: frontmatter);
    });
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveNow);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // On wide screens default to split view
    if (isWide && _mode == EditorMode.edit) {
      _mode = EditorMode.split;
    }

    return Column(
      children: [
        // Mode toggle toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _ModeButton(
                label: l10n.editorEdit,
                icon: Icons.edit,
                selected: _mode == EditorMode.edit,
                onPressed: () => setState(() => _mode = EditorMode.edit),
              ),
              const SizedBox(width: 4),
              _ModeButton(
                label: l10n.editorPreview,
                icon: Icons.visibility,
                selected: _mode == EditorMode.preview,
                onPressed: () => setState(() => _mode = EditorMode.preview),
              ),
              if (isWide) ...[
                const SizedBox(width: 4),
                _ModeButton(
                  label: l10n.editorSplitView,
                  icon: Icons.vertical_split,
                  selected: _mode == EditorMode.split,
                  onPressed: () => setState(() => _mode = EditorMode.split),
                ),
              ],
              const Spacer(),
              // Properties toggle
              IconButton(
                icon: Icon(
                  _showProperties
                      ? Icons.tune
                      : Icons.tune_outlined,
                  size: 20,
                ),
                color: _showProperties
                    ? Theme.of(context).colorScheme.primary
                    : null,
                tooltip: l10n.propertiesToggle,
                onPressed: () =>
                    setState(() => _showProperties = !_showProperties),
              ),
            ],
          ),
        ),
        // Collapsible properties panel
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _showProperties && _entry != null
              ? PropertiesPanel(
                  frontmatter: _entry!.frontmatter,
                  onChanged: _onFrontmatterChanged,
                )
              : const SizedBox.shrink(),
        ),
        // Markdown toolbar — only in edit / split mode
        if (_mode != EditorMode.preview)
          MarkdownToolbar(controller: _controller, focusNode: _focusNode),
        // Editor / Preview area
        Expanded(child: _buildEditorArea(context)),
        // Word / char count footer
        _WordCountBar(controller: _controller),
      ],
    );
  }

  Widget _buildEditorArea(BuildContext context) {
    return switch (_mode) {
      EditorMode.edit => _buildEditor(context),
      EditorMode.preview => _buildPreview(),
      EditorMode.split => Row(
          children: [
            Expanded(child: _buildEditor(context)),
            const VerticalDivider(width: 1),
            Expanded(child: _buildPreview()),
          ],
        ),
    };
  }

  Widget _buildEditor(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editorColor = ref
        .watch(settingsProvider)
        .valueOrNull
        ?.editorTextColor
        .toColor();
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: l10n.editorPlaceholder,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
        filled: false,
      ),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'monospace',
            height: 1.6,
            color: editorColor, // null = theme default
          ),
      onChanged: (_) => _onTextChanged(),
    );
  }

  Widget _buildPreview() {
    return Markdown(
      data: _preprocessForPreview(_controller.text),
      selectable: true,
      padding: const EdgeInsets.all(16),
      // gitHubWeb adds task-list checkboxes on top of gitHubFlavored
      extensionSet: md.ExtensionSet.gitHubWeb,
      // _CalloutSyntax must come first so it wins over BlockquoteSyntax
      blockSyntaxes: const [_CalloutSyntax()],
      inlineSyntaxes: [
        _HighlightSyntax(),
        _UnderlineSyntax(),
        _SpanSyntax(),
      ],
      builders: {
        'mark':    _HighlightBuilder(),
        'u':       _UnderlineBuilder(),
        'span':    _SpanBuilder(),
        'callout': _CalloutBuilder(),
      },
      onTapLink: (text, href, title) {
        if (href == null || href.isEmpty) return;
        final uri = Uri.tryParse(href);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  /// Strips `<div align="...">` wrappers (flutter_markdown can't align blocks).
  static String _preprocessForPreview(String text) {
    return text.replaceAllMapped(
      RegExp(r'<div[^>]*>([\s\S]*?)</div>', caseSensitive: false),
      (m) => m[1]!.trim(),
    );
  }
}

// ---------------------------------------------------------------------------
// Callout block syntax  ▸  renders > [!type][+-]? title  as a styled card
// ---------------------------------------------------------------------------

class _CalloutSyntax extends md.BlockSyntax {
  const _CalloutSyntax();

  static final _headerRe = RegExp(r'^> \[!(\w+)([+-]?)\][ \t]*(.*)$');

  @override
  RegExp get pattern => _headerRe;

  @override
  bool canParse(md.BlockParser parser) =>
      _headerRe.hasMatch(parser.current.content);

  @override
  md.Node? parse(md.BlockParser parser) {
    final m = _headerRe.firstMatch(parser.current.content);
    if (m == null) return null;

    final type  = m[1]!.toLowerCase();
    final fold  = m[2]!;          // '+' expanded, '-' collapsed, '' not foldable
    final title = m[3]!.trim();
    parser.advance();

    final buf = StringBuffer();
    while (!parser.isDone) {
      final line = parser.current.content;
      if (line.startsWith('> ')) {
        buf.writeln(line.substring(2));
        parser.advance();
      } else if (line == '>') {
        buf.writeln();
        parser.advance();
      } else {
        break;
      }
    }

    final el = md.Element('callout', [md.Text(buf.toString().trimRight())]);
    el.attributes['data-type']  = type;
    el.attributes['data-fold']  = fold;
    el.attributes['data-title'] = title.isNotEmpty ? title : type.toUpperCase();
    return el;
  }
}

class _CalloutBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final type    = element.attributes['data-type']  ?? 'note';
    final fold    = element.attributes['data-fold']  ?? '';
    final title   = element.attributes['data-title'] ?? type.toUpperCase();
    final content = element.textContent;
    final (color, icon) = _style(type);
    return _CalloutCard(
        title: title, content: content, fold: fold, color: color, icon: icon);
  }

  static (Color, IconData) _style(String t) => switch (t) {
        'tip' || 'hint'          => (const Color(0xFF47B882), Icons.lightbulb_outline),
        'success' || 'check'     => (const Color(0xFF47B882), Icons.check_circle_outline),
        'warning'                => (const Color(0xFFF5A623), Icons.warning_amber_outlined),
        'danger' || 'error'      => (const Color(0xFFE5534B), Icons.dangerous_outlined),
        'failure' || 'fail'      => (const Color(0xFFE5534B), Icons.cancel_outlined),
        'bug'                    => (const Color(0xFFE5534B), Icons.bug_report_outlined),
        'question'               => (const Color(0xFF9B59B6), Icons.help_outline),
        'quote'                  => (const Color(0xFF6B7280), Icons.format_quote_outlined),
        'todo'                   => (const Color(0xFF4E9BF5), Icons.check_box_outlined),
        'example'                => (const Color(0xFF9B59B6), Icons.list_alt_outlined),
        'abstract' || 'summary'  => (const Color(0xFF47B882), Icons.subject_outlined),
        _                        => (const Color(0xFF4E9BF5), Icons.info_outline),
      };
}

class _CalloutCard extends StatefulWidget {
  final String title, content, fold;
  final Color color;
  final IconData icon;

  const _CalloutCard({
    required this.title,
    required this.content,
    required this.fold,
    required this.color,
    required this.icon,
  });

  @override
  State<_CalloutCard> createState() => _CalloutCardState();
}

class _CalloutCardState extends State<_CalloutCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.fold != '-'; // '-' → collapsed; '+' or '' → expanded
  }

  @override
  Widget build(BuildContext context) {
    final isFoldable = widget.fold.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: widget.color.withAlpha(25),
        border: Border(left: BorderSide(color: widget.color, width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: isFoldable ? () => setState(() => _expanded = !_expanded) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(children: [
                Icon(widget.icon, color: widget.color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isFoldable)
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.color,
                    size: 16,
                  ),
              ]),
            ),
          ),
          if (_expanded && widget.content.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: MarkdownBody(data: widget.content, shrinkWrap: true),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ==highlight==
// ---------------------------------------------------------------------------

class _HighlightSyntax extends md.InlineSyntax {
  _HighlightSyntax() : super(r'==([^=\n]+)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match[1]!));
    return true;
  }
}

class _HighlightBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      color: const Color(0x55F5C518),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(element.textContent, style: preferredStyle),
    );
  }
}

// ---------------------------------------------------------------------------
// <u>underline</u>
// ---------------------------------------------------------------------------

class _UnderlineSyntax extends md.InlineSyntax {
  _UnderlineSyntax() : super(r'<u>([\s\S]*?)</u>');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('u', match[1]!));
    return true;
  }
}

class _UnderlineBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Text(
      element.textContent,
      style: (preferredStyle ?? const TextStyle())
          .copyWith(decoration: TextDecoration.underline),
    );
  }
}

// ---------------------------------------------------------------------------
// <span style="color:#hex">text</span>
// ---------------------------------------------------------------------------

class _SpanSyntax extends md.InlineSyntax {
  _SpanSyntax() : super(r'<span\s+style="([^"]*)">([\s\S]*?)</span>');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final el = md.Element.text('span', match[2]!);
    el.attributes['style'] = match[1]!;
    parser.addNode(el);
    return true;
  }
}

class _SpanBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final style = element.attributes['style'] ?? '';
    final hexMatch =
        RegExp(r'color:\s*(#[0-9a-fA-F]{6})').firstMatch(style);
    if (hexMatch == null) return null;
    final color =
        Color(int.parse(hexMatch[1]!.substring(1), radix: 16) | 0xFF000000);
    return Text(
      element.textContent,
      style: (preferredStyle ?? const TextStyle()).copyWith(color: color),
    );
  }
}

// ---------------------------------------------------------------------------
// Word / character count footer
// ---------------------------------------------------------------------------

class _WordCountBar extends StatefulWidget {
  final TextEditingController controller;
  const _WordCountBar({required this.controller});

  @override
  State<_WordCountBar> createState() => _WordCountBarState();
}

class _WordCountBarState extends State<_WordCountBar> {
  int _words = 0;
  int _chars = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
    _update();
  }

  @override
  void didUpdateWidget(_WordCountBar old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_update);
      widget.controller.addListener(_update);
      _update();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    final text = widget.controller.text;
    final words = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
    final chars = text.length;
    if (words != _words || chars != _chars) {
      setState(() {
        _words = words;
        _chars = chars;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$_words words · $_chars chars', style: style),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: selected,
      onSelected: (_) => onPressed(),
      showCheckmark: false,
    );
  }
}
