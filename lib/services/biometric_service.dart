import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _authentication = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      return await _authentication.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _authentication.authenticate(
        localizedReason: 'Autentícate para acceder a Universal Code Scanner.',
        persistAcrossBackgrounding: true,
      );
    } on Object {
      return false;
    }
  }
}
