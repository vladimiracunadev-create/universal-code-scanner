/// Picks the Sembast factory for the current platform at compile time.
///
/// The stub is the default so that an unsupported platform fails with a clear
/// message at the call site rather than a link error at build time.
library;

export 'database_opener_stub.dart'
    if (dart.library.io) 'database_opener_io.dart'
    if (dart.library.js_interop) 'database_opener_web.dart';
