import 'dart:async';

import 'package:flutter/services.dart';

abstract final class ClipboardService {
  /// Copies a value and, unless disabled, wipes it again after a delay.
  ///
  /// Two deliberate properties. The timer is never stored or cancelled: it
  /// outlives the widget that started it, because the goal is to clear the
  /// clipboard no matter where the user navigated to. And it re-reads the
  /// clipboard before wiping, so that copying something else in the meantime
  /// is not silently destroyed by a timer the user has forgotten about.
  ///
  /// `clearAfterSeconds` of zero means «never wipe» and is a real option in
  /// the settings screen.
  static Future<void> copy(String value, {int clearAfterSeconds = 30}) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (clearAfterSeconds <= 0) return;
    Timer(Duration(seconds: clearAfterSeconds), () async {
      final ClipboardData? current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == value) await Clipboard.setData(const ClipboardData(text: ''));
    });
  }
}
