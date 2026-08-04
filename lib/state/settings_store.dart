import 'package:flutter/foundation.dart';
import 'package:universal_code_scanner/models/app_settings.dart';
import 'package:universal_code_scanner/services/settings_repository.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._repository);

  final SettingsRepository _repository;
  AppSettings _value = const AppSettings();

  AppSettings get value => _value;

  Future<void> initialize() async {
    _value = await _repository.load();
  }

  Future<void> update(AppSettings value) async {
    _value = value;
    notifyListeners();
    await _repository.save(value);
  }
}
