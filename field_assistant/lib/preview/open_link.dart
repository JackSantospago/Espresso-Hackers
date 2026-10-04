// Opens a web page in a new browser tab. Only the web preview can do this; on
// other platforms (tests, `flutter analyze` of the VM build) it does nothing,
// so no url_launcher dependency is needed for one link.
export 'open_link_stub.dart' if (dart.library.js_interop) 'open_link_web.dart';
