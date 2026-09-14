import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web implementation — switch Flutter to the path-based URL strategy.
///
/// Without this the app would use hash URLs (`/#/invite/slug`), which breaks
/// the guest invite links that the app shares and that `GuestSlug.from()`
/// has to parse.
///
/// NOTE: this file is only imported when `dart:js_interop` is available
/// (web builds). Importing flutter_web_plugins on Android/iOS fails to
/// compile because it pulls in `dart:ui_web`.
void configureWebUrlStrategy() {
  usePathUrlStrategy();
}
