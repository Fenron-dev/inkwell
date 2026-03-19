import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/utils/url_utils.dart';

/// Full-screen camera screen that scans for URLs in the viewfinder.
///
/// Call [OcrScannerScreen.scan] to push the screen and await the selected URL.
/// Returns null if the user cancels or no URL is selected.
///
/// Only available on Android and iOS. For other platforms the method returns
/// null immediately without showing any UI.
class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  /// Push the scanner and return the URL the user tapped, or null.
  static Future<String?> scan(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const OcrScannerScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  CameraController? _cam;
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _initializing = true;
  bool _scanning = false;
  String? _initError;
  List<String> _urls = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _recognizer.close();
    _cam?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _initError = AppLocalizations.of(context)!.ocrNoCameraError;
            _initializing = false;
          });
        }
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _cam = controller;
      setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e.toString();
          _initializing = false;
        });
      }
    }
  }

  Future<void> _scan() async {
    if (_scanning || _cam == null) return;
    setState(() {
      _scanning = true;
      _urls = [];
    });
    try {
      final photo = await _cam!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final result = await _recognizer.processImage(inputImage);
      // Clean up temp file
      final file = File(photo.path);
      if (await file.exists()) file.delete().ignore();

      final found = extractUrls(result.text);
      if (mounted) setState(() => _urls = found);
    } catch (_) {
      // Leave _urls empty — "try again" hint is shown
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Camera preview ───────────────────────────────────────────
            if (_cam != null && !_initializing)
              Positioned.fill(child: CameraPreview(_cam!)),

            if (_initializing && _initError == null)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            if (_initError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _initError!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // ── Close button (top-left) ──────────────────────────────────
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // ── Hint (top-center) ────────────────────────────────────────
            Positioned(
              top: 8,
              left: 52,
              right: 8,
              child: Text(
                l10n.ocrScanHint,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  shadows: [Shadow(blurRadius: 4)],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // ── Bottom panel ─────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Detected URL cards
                    if (_urls.isNotEmpty) ...[
                      Text(
                        l10n.ocrSelectUrl,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._urls.map(
                        (url) => _UrlCard(
                          url: url,
                          onTap: () => Navigator.of(context).pop(url),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else if (!_scanning && !_initializing) ...[
                      Text(
                        l10n.ocrNoUrlsYet,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Scan button
                    FilledButton.icon(
                      onPressed:
                          (_scanning || _initializing) ? null : _scan,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _scanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.document_scanner_outlined),
                      label: Text(
                        _scanning ? l10n.ocrScanning : l10n.ocrScanButton,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrlCard extends StatelessWidget {
  final String url;
  final VoidCallback onTap;
  const _UrlCard({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          url,
          style: const TextStyle(
            color: Colors.lightBlueAccent,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
