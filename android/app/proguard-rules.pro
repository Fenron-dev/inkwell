# google_mlkit_text_recognition references optional script-specific recognizer
# classes (Chinese, Devanagari, Japanese, Korean) that are not on the classpath
# unless the corresponding ML Kit modules are added. Tell R8 to treat them as
# missing-but-OK instead of failing the build.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
