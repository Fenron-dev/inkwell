import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/search/search_provider.dart';
import '../../core/vault/vault_provider.dart';
import '../../models/journal_entry.dart';

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
            ],
          ),
        ),
        const Divider(height: 1),
        // Editor / Preview area
        Expanded(child: _buildEditorArea(context)),
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
          ),
      onChanged: (_) => _onTextChanged(),
    );
  }

  Widget _buildPreview() {
    return Markdown(
      data: _controller.text,
      selectable: true,
      padding: const EdgeInsets.all(16),
    );
  }
}

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
