/// Custom exception for storage-related errors
class StorageException implements Exception {
  final String message;
  final String? path;
  final Object? originalError;

  StorageException(this.message, {this.path, this.originalError});

  @override
  String toString() => message;
}
