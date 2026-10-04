import 'dart:js_interop';

@JS('window.open')
external JSAny? _windowOpen(JSString url, JSString target);

/// Opens [url] in a new browser tab.
void openLink(String url) => _windowOpen(url.toJS, '_blank'.toJS);
