// No-op Dart stub for Windows — speech recognition returns 'unavailable'.
// Uses dartPluginClass so Flutter does NOT generate any C++ registration
// code or CMake targets, eliminating all native-build issues on Windows CI.

/// Stub class referenced by pubspec.yaml dartPluginClass.
/// The speech_to_text platform interface will fall back to its defaults
/// (initialize → false) since this class does not register an implementation.
class SpeechToTextWindowsStub {
  static void registerWith() {
    // Intentionally empty — SpeechToText.initialize() will return false.
  }
}
