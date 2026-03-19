#define FLUTTER_PLUGIN_IMPL
#include "include/speech_to_text_windows/speech_to_text_windows_plugin.h"

// No-op stub: speech recognition is not supported on Windows in this build.
// SpeechToText.initialize() will return false on Windows, so the mic button
// will not appear in the editor toolbar.
void SpeechToTextWindowsRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {}
