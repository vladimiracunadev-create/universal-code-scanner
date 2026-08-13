/// Single place where the application version is written for the interface.
///
/// The «Acerca de» tile used to carry the number as a literal, and it stayed at
/// 1.0.0 after the version was raised: a user reading the screen was told the
/// wrong version. `tool/validate_structure.py` now compares this constant with
/// `pubspec.yaml` and fails the build if they diverge, so the drift cannot come
/// back silently.
///
/// It is a constant rather than a runtime lookup on purpose: reading the real
/// package metadata would add a plugin dependency to display a string that is
/// already known when the package is built.
library;

/// Version shown in the interface, without the build number.
const String appVersion = '1.1.0';

/// Product name shown in the interface.
const String appName = 'Universal Code Scanner';
