#ifndef FLUTTER_PLUGIN_SPEECH_TO_TEXT_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_SPEECH_TO_TEXT_WINDOWS_PLUGIN_H_

// Forward-declare the Flutter registrar type so we don't need
// flutter/plugin_registrar_windows.h in this stub header.
typedef struct FlutterDesktopPluginRegistrar* FlutterDesktopPluginRegistrarRef;

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void SpeechToTextWindowsRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_SPEECH_TO_TEXT_WINDOWS_PLUGIN_H_
