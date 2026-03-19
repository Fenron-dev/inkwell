import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Horizontally scrollable Markdown formatting toolbar.
///
/// All operations act on [controller] and restore focus to [focusNode]
/// after each edit so the cursor stays in the editor.
///
/// The widget is stateful so it can track the last valid selection —
/// on Android, the TextField loses its selection when the user taps a
/// toolbar button (focus moves away). Without the saved selection, every
/// operation would silently do nothing because `_sel.isValid` returns false.
class MarkdownToolbar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Called when the user taps the image button. The callback should pick a
  /// file, save it to the vault, and return the vault-relative path. If the
  /// user cancels, it should return null.
  final Future<String?> Function()? onPickImage;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onPickImage,
  });

  @override
  State<MarkdownToolbar> createState() => _MarkdownToolbarState();
}

class _MarkdownToolbarState extends State<MarkdownToolbar> {
  /// The last valid selection seen while the TextField had focus.
  TextSelection _savedSel = const TextSelection.collapsed(offset: 0);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(MarkdownToolbar old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final sel = widget.controller.selection;
    if (sel.isValid && sel.start >= 0) {
      _savedSel = sel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _MdHelper(widget.controller, widget.focusNode, _savedSel);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // ── Inline formatting ──────────────────────────────────────────
            _Btn(Icons.format_bold, 'Bold',          () => h.wrap('**', '**')),
            _Btn(Icons.format_italic, 'Italic',      () => h.wrap('*', '*')),
            _Btn(Icons.format_underlined, 'Underline', () => h.wrap('<u>', '</u>')),
            _Btn(Icons.format_strikethrough, 'Strikethrough', () => h.wrap('~~', '~~')),
            _Btn(Icons.highlight, 'Highlight (==)', () => h.wrap('==', '==')),
            const _Sep(),

            // ── Headings ───────────────────────────────────────────────────
            _TxtBtn('H1', 'Heading 1', () => h.setHeading(1)),
            _TxtBtn('H2', 'Heading 2', () => h.setHeading(2)),
            _TxtBtn('H3', 'Heading 3', () => h.setHeading(3)),
            const _Sep(),

            // ── Lists ──────────────────────────────────────────────────────
            _Btn(Icons.format_list_bulleted, 'Unordered list', () => h.toggleLinePrefix('- ')),
            _Btn(Icons.format_list_numbered, 'Ordered list',   () => h.toggleOrderedList()),
            _Btn(Icons.checklist, 'Checklist',                 () => h.toggleLinePrefix('- [ ] ')),
            _Btn(Icons.format_indent_increase, 'Indent',       () => h.indent()),
            _Btn(Icons.format_indent_decrease, 'Unindent',     () => h.unindent()),
            const _Sep(),

            // ── Blocks ─────────────────────────────────────────────────────
            _Btn(Icons.format_quote, 'Blockquote',     () => h.toggleLinePrefix('> ')),
            _Btn(Icons.horizontal_rule, 'Horizontal rule', () => h.insertHR()),
            _Btn(Icons.code, 'Inline code',            () => h.wrap('`', '`')),
            _TxtBtn('```', 'Code block',               () => h.insertCodeBlock()),
            _Btn(Icons.table_chart_outlined, 'Insert table', () => h.insertTable()),
            _CalloutMenu(helper: h),
            const _Sep(),

            // ── Insert ─────────────────────────────────────────────────────
            _LinkBtn(helper: h),
            if (widget.onPickImage != null)
              _Btn(Icons.image_outlined, 'Insert image', () async {
                final path = await widget.onPickImage!();
                if (path != null) h.insertImage(path);
              }),
            _Btn(Icons.tag, 'Wikilink',   () => h.wrap('[[', ']]')),
            _Btn(Icons.comment_outlined, 'Comment (%% … %%)', () => h.wrap('%% ', ' %%')),
            const _Sep(),

            // ── Colors ─────────────────────────────────────────────────────
            _ColorMenu(helper: h, background: false),
            _ColorMenu(helper: h, background: true),
            const _Sep(),

            // ── Alignment ──────────────────────────────────────────────────
            _Btn(Icons.format_align_left,   'Align left',   () => h.setAlignment('left')),
            _Btn(Icons.format_align_center, 'Align center', () => h.setAlignment('center')),
            _Btn(Icons.format_align_right,  'Align right',  () => h.setAlignment('right')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Text-manipulation helper
// ---------------------------------------------------------------------------

class _MdHelper {
  final TextEditingController _ctrl;
  final FocusNode _focus;

  /// Fallback selection used when the controller's selection is invalid.
  /// On Android, tapping a toolbar button removes focus from the TextField,
  /// which resets the selection to offset -1 (invalid). The saved selection
  /// lets us still act on the text the user had highlighted.
  final TextSelection _savedSel;

  _MdHelper(this._ctrl, this._focus, this._savedSel);

  String get _text => _ctrl.text;

  /// Returns the current controller selection, falling back to [_savedSel]
  /// when the controller's selection is invalid (e.g. after focus loss on Android).
  TextSelection get _sel {
    final s = _ctrl.selection;
    if (s.isValid && s.start >= 0) return s;
    return _savedSel;
  }

  bool get _hasSel => _sel.isValid && !_sel.isCollapsed;
  String get _selected =>
      _hasSel ? _text.substring(_sel.start, _sel.end) : '';

  void _apply(TextEditingValue v) {
    _ctrl.value = v;
    _focus.requestFocus();
  }

  // ── Inline wrap ────────────────────────────────────────────────────────

  /// Wraps selection with [pre]/[suf], toggling off if already wrapped.
  /// Without a selection, inserts the pair and places cursor between them.
  void wrap(String pre, String suf) {
    if (!_sel.isValid) return;

    if (!_hasSel) {
      final p = _sel.start.clamp(0, _text.length);
      final newText = _text.replaceRange(p, p, '$pre$suf');
      _apply(TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: p + pre.length),
      ));
      return;
    }

    final s = _selected;
    if (s.startsWith(pre) && s.endsWith(suf) &&
        s.length > pre.length + suf.length) {
      final inner = s.substring(pre.length, s.length - suf.length);
      _apply(TextEditingValue(
        text: _text.replaceRange(_sel.start, _sel.end, inner),
        selection: TextSelection(
            baseOffset: _sel.start, extentOffset: _sel.start + inner.length),
      ));
    } else {
      final wrapped = '$pre$s$suf';
      _apply(TextEditingValue(
        text: _text.replaceRange(_sel.start, _sel.end, wrapped),
        selection: TextSelection(
            baseOffset: _sel.start, extentOffset: _sel.start + wrapped.length),
      ));
    }
  }

  // ── Line-level helpers ─────────────────────────────────────────────────

  /// Returns the [start, end) character range covering all selected lines.
  (int, int) _lines() {
    if (!_sel.isValid) return (0, 0);
    final t = _text;
    int ls = (_hasSel ? _sel.start : _sel.start).clamp(0, t.length);
    while (ls > 0 && t[ls - 1] != '\n') { ls--; }
    int le = (_hasSel ? _sel.end : _sel.start).clamp(0, t.length);
    while (le < t.length && t[le] != '\n') { le++; }
    return (ls, le);
  }

  int get _cursorEnd =>
      (_hasSel ? _sel.end : _sel.start).clamp(0, _text.length);

  void _replaceLines(String Function(List<String>) transform) {
    if (!_sel.isValid) return;
    final (ls, le) = _lines();
    final section = _text.substring(ls, le);
    final lines = section.split('\n');
    final newSection = transform(lines);
    final delta = newSection.length - section.length;
    _apply(TextEditingValue(
      text: _text.replaceRange(ls, le, newSection),
      selection: TextSelection.collapsed(offset: _cursorEnd + delta),
    ));
  }

  void toggleLinePrefix(String prefix) {
    _replaceLines((lines) {
      final allHave = lines.every((l) => l.startsWith(prefix) || l.isEmpty);
      return (allHave
              ? lines.map((l) => l.startsWith(prefix) ? l.substring(prefix.length) : l)
              : lines.map((l) => l.isEmpty ? l : '$prefix$l'))
          .join('\n');
    });
  }

  void toggleOrderedList() {
    _replaceLines((lines) {
      final re = RegExp(r'^\d+\.\s');
      final allHave = lines.every((l) => re.hasMatch(l) || l.isEmpty);
      if (allHave) {
        return lines.map((l) => l.replaceFirst(re, '')).join('\n');
      }
      int n = 1;
      return lines.map((l) => l.isEmpty ? l : '${n++}. $l').join('\n');
    });
  }

  void setHeading(int level) {
    _replaceLines((lines) {
      final prefix = '${'#' * level} ';
      return lines.map((l) {
        final cleaned = l.replaceFirst(RegExp(r'^#{1,6}\s'), '');
        return l.startsWith(prefix) ? cleaned : '$prefix$cleaned';
      }).join('\n');
    });
  }

  void indent() {
    _replaceLines((lines) =>
        lines.map((l) => l.isEmpty ? l : '  $l').join('\n'));
  }

  void unindent() {
    _replaceLines((lines) => lines.map((l) {
          if (l.startsWith('    ')) return l.substring(4);
          if (l.startsWith('  ')) return l.substring(2);
          if (l.startsWith('\t')) return l.substring(1);
          return l;
        }).join('\n'));
  }

  // ── Block insertions ───────────────────────────────────────────────────

  void insertHR() => _insertAt('\n\n---\n\n', '\n\n---\n\n'.length);

  void insertCodeBlock() {
    if (!_hasSel) {
      _insertAt('```\n\n```', 4);
    } else {
      final s = _selected;
      final block = '```\n$s\n```';
      _apply(TextEditingValue(
        text: _text.replaceRange(_sel.start, _sel.end, block),
        selection: TextSelection.collapsed(offset: _sel.start + block.length),
      ));
    }
  }

  void insertTable() {
    const t = '\n| Column 1 | Column 2 | Column 3 |\n'
        '| --- | --- | --- |\n'
        '| Cell | Cell | Cell |\n'
        '| Cell | Cell | Cell |\n\n';
    _insertAt(t, t.length);
  }

  void insertImage(String vaultRelativePath) {
    final alt = vaultRelativePath.split('/').last.replaceAll(RegExp(r'\.\w+$'), '');
    _insertAt('![$alt]($vaultRelativePath)', '![$alt]($vaultRelativePath)'.length);
  }

  void insertCallout(String type) {
    final t = '\n> [!$type]\n> \n\n';
    _insertAt(t, t.length - 2); // cursor lands after '> '
  }

  void insertLink(String display, String url) {
    if (!_sel.isValid) return;
    final link = display.isNotEmpty ? '[$display]($url)' : url;
    final newText = _text.replaceRange(_sel.start, _sel.end, link);
    _apply(TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: _sel.start + link.length),
    ));
  }

  void wrapWithColor(String hex) =>
      wrap('<span style="color:$hex">', '</span>');

  void wrapWithBgColor(String hex) =>
      wrap('<span style="background-color:$hex">', '</span>');

  void setAlignment(String align) {
    if (!_sel.isValid) return;
    if (!_hasSel) {
      _insertAt('<div align="$align">\n\n</div>',
          '<div align="$align">\n'.length);
    } else {
      final s = _selected;
      final block = '<div align="$align">\n$s\n</div>';
      _apply(TextEditingValue(
        text: _text.replaceRange(_sel.start, _sel.end, block),
        selection: TextSelection.collapsed(offset: _sel.start + block.length),
      ));
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// Inserts [text] at the current cursor, then places cursor at
  /// [cursorOffset] characters from the insertion start.
  void _insertAt(String text, int cursorOffset) {
    if (!_sel.isValid) return;
    final p = _sel.start.clamp(0, _text.length);
    final newText = _text.replaceRange(p, _sel.end.clamp(p, _text.length), text);
    _apply(TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: p + cursorOffset),
    ));
  }
}

// ---------------------------------------------------------------------------
// Small reusable widgets
// ---------------------------------------------------------------------------

class _Btn extends StatelessWidget {
  final IconData icon;
  final String tip;
  final VoidCallback onTap;

  const _Btn(this.icon, this.tip, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(width: 36, height: 36,
            child: Icon(icon, size: 18)),
      ),
    );
  }
}

class _TxtBtn extends StatelessWidget {
  final String label;
  final String tip;
  final VoidCallback onTap;

  const _TxtBtn(this.label, this.tip, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Center(
              child: Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      )),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        child: VerticalDivider(
            width: 1, thickness: 1, color: Theme.of(context).dividerColor),
      );
}

// ---------------------------------------------------------------------------
// Callout popup
// ---------------------------------------------------------------------------

class _CalloutMenu extends StatelessWidget {
  final _MdHelper helper;
  const _CalloutMenu({required this.helper});

  static const _types = [
    ('note',     Icons.info_outline,          'Note'),
    ('tip',      Icons.lightbulb_outline,     'Tip / Hint'),
    ('info',     Icons.info_outlined,         'Info'),
    ('todo',     Icons.check_box_outlined,    'Todo'),
    ('warning',  Icons.warning_amber_outlined,'Warning'),
    ('danger',   Icons.dangerous_outlined,    'Danger'),
    ('success',  Icons.check_circle_outline,  'Success'),
    ('question', Icons.help_outline,          'Question'),
    ('failure',  Icons.cancel_outlined,       'Failure'),
    ('bug',      Icons.bug_report_outlined,   'Bug'),
    ('example',  Icons.list_alt_outlined,     'Example'),
    ('quote',    Icons.format_quote_outlined, 'Quote'),
    ('abstract', Icons.subject_outlined,      'Abstract / TL;DR'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Insert callout',
      icon: const Icon(Icons.add_box_outlined, size: 18),
      itemBuilder: (_) => _types
          .map((t) => PopupMenuItem<String>(
                value: t.$1,
                child: Row(children: [
                  Icon(t.$2, size: 16),
                  const SizedBox(width: 10),
                  Text(t.$3),
                ]),
              ))
          .toList(),
      onSelected: helper.insertCallout,
    );
  }
}

// ---------------------------------------------------------------------------
// Link dialog
// ---------------------------------------------------------------------------

class _LinkBtn extends StatelessWidget {
  final _MdHelper helper;
  const _LinkBtn({required this.helper});

  @override
  Widget build(BuildContext context) {
    return _Btn(Icons.link, 'Insert link', () => _show(context));
  }

  Future<void> _show(BuildContext context) async {
    final displayCtrl =
        TextEditingController(text: helper._hasSel ? helper._selected : '');
    final urlCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert link'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: displayCtrl,
            decoration: const InputDecoration(labelText: 'Display text'),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: urlCtrl,
            decoration: const InputDecoration(
                labelText: 'URL', hintText: 'https://…'),
            keyboardType: TextInputType.url,
            onSubmitted: (_) => Navigator.pop(ctx, true),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Insert')),
        ],
      ),
    );
    if (ok == true) {
      helper.insertLink(displayCtrl.text, urlCtrl.text);
    }
    displayCtrl.dispose();
    urlCtrl.dispose();
  }
}

// ---------------------------------------------------------------------------
// Color palette dialog
// ---------------------------------------------------------------------------

class _ColorMenu extends StatelessWidget {
  final _MdHelper helper;
  final bool background;
  const _ColorMenu({required this.helper, required this.background});

  static const _palette = [
    ('#ef4444', 'Red'),
    ('#f97316', 'Orange'),
    ('#eab308', 'Yellow'),
    ('#22c55e', 'Green'),
    ('#3b82f6', 'Blue'),
    ('#6366f1', 'Indigo'),
    ('#a855f7', 'Purple'),
    ('#ec4899', 'Pink'),
    ('#6b7280', 'Grey'),
    ('#000000', 'Black'),
    ('#ffffff', 'White'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Btn(
      background ? Icons.format_color_fill : Icons.format_color_text,
      background ? 'Background color' : 'Text color',
      () => _show(context),
    );
  }

  Future<void> _show(BuildContext context) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(background ? 'Background color' : 'Text color'),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palette.map((c) {
              final color = Color(
                  int.parse(c.$1.substring(1), radix: 16) + 0xFF000000);
              return Tooltip(
                message: c.$2,
                child: InkWell(
                  onTap: () => Navigator.pop(ctx, c.$1),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                          color: Theme.of(ctx).dividerColor, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
    if (picked != null) {
      if (background) {
        helper.wrapWithBgColor(picked);
      } else {
        helper.wrapWithColor(picked);
      }
    }
  }
}
