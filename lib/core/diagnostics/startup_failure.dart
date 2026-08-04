class StartupFailure {
  const StartupFailure({required this.errorType, required this.message, required this.stackFingerprint});

  final String errorType;
  final String message;
  final String stackFingerprint;

  factory StartupFailure.from(Object error, StackTrace stack) {
    final int hash = Object.hash(error.runtimeType.toString(), stack.toString().split('\n').take(4).join('|'));
    return StartupFailure(
      errorType: error.runtimeType.toString(),
      message: 'No fue posible inicializar uno o más servicios locales.',
      stackFingerprint: hash.toUnsigned(32).toRadixString(16).padLeft(8, '0'),
    );
  }
}
