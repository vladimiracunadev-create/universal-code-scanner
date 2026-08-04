import 'dart:async';

import 'package:flutter/services.dart';

abstract final class ClipboardService {
  static Future<void> copy(String value, {int clearAfterSeconds = 30}) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (clearAfterSeconds <= 0) return;
    Timer(Duration(seconds: clearAfterSeconds), () async {
      final ClipboardData? current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == value) await Clipboard.setData(const ClipboardData(text: ''));
    });
  }
}
