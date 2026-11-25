/// Errors the app knows how to explain. Anything else is a bug.
sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  /// Developer-facing description (shown in logs and in debug builds).
  final String message;
  final Object? cause;

  @override
  String toString() => cause == null ? '$runtimeType: $message' : '$runtimeType: $message ($cause)';
}

/// The bundled content database is missing, corrupt or of the wrong version.
final class ContentDatabaseException extends AppException {
  const ContentDatabaseException(super.message, [super.cause]);
}

/// A row the UI asked for does not exist (e.g. a bad ayah reference).
final class ContentNotFoundException extends AppException {
  const ContentNotFoundException(super.message);
}
