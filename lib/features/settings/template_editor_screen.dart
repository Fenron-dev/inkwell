import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/vault/vault_provider.dart';
import '../editor/markdown_toolbar.dart';

/// Full-screen editor for the daily note template (`_templates/daily.md`).
class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({super.key});

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final vault = ref.read(vaultProvider).valueOrNull;
    if (vault == null) return;
    final service = ref.read(vaultServiceProvider);
    final content = await service.readTemplate(vault);
    if (mounted) {
      setState(() {
        _controller.text = content;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final vault = ref.read(vaultProvider).valueOrNull;
    if (vault == null) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(vaultServiceProvider);
      await service.writeTemplate(vault, _controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.templateSaved)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.templateEditorTitle),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: l10n.save,
              onPressed: _save,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                MarkdownToolbar(
                    controller: _controller, focusNode: _focusNode),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: l10n.templateEditorHint,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}
