/// Reusable form validators
class Validators {
  /// Validates that a field is not empty
  static String? required(String? value, {String fieldName = 'field'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a $fieldName';
    }
    return null;
  }

  /// Validates minimum length
  static String? minLength(
    String? value,
    int min, {
    String? fieldName,
  }) {
    if (value == null || value.trim().length < min) {
      return fieldName != null
          ? '$fieldName must be at least $min characters'
          : 'Must be at least $min characters';
    }
    return null;
  }

  /// Validates maximum length
  static String? maxLength(
    String? value,
    int max, {
    String? fieldName,
  }) {
    if (value != null && value.trim().length > max) {
      return fieldName != null
          ? '$fieldName must be at most $max characters'
          : 'Must be at most $max characters';
    }
    return null;
  }

  /// Combines multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validates URL format
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    try {
      Uri.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }
}
