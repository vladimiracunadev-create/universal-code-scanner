import 'package:local_auth/local_auth.dart';

/// Thin wrapper over `local_auth` that can only ever fail closed.
///
/// Both methods swallow every platform error and return `false`. That is the
/// safe direction for an access control: a plugin failure, a device without
/// enrolment or a cancelled prompt all mean «not authenticated», never
/// «authenticated by default».
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
      // `persistAcrossBackgrounding` matters here: the system prompt itself
      // sends the application to an inactive state, which is exactly what
      // `BiometricLockGate` watches for. Without it, showing the prompt would
      // arm another lock and the two would chase each other.
      return await _authentication.authenticate(
        localizedReason: 'Autentícate para acceder a Universal Code Scanner.',
        persistAcrossBackgrounding: true,
      );
    } on Object {
      return false;
    }
  }
}
