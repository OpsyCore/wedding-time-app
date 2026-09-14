/// Non-web stub for web-only URL strategy setup.
///
/// Android / iOS / desktop have no address bar, so there is nothing to
/// configure. This file is selected by the conditional import in main.dart
/// whenever `dart:js_interop` is unavailable (i.e. everything except web).
void configureWebUrlStrategy() {
  // no-op
}
