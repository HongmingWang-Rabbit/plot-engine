import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatusMessage {
  final String message;
  final StatusType type;
  final DateTime timestamp;

  StatusMessage({
    required this.message,
    required this.type,
  }) : timestamp = DateTime.now();

  StatusMessage.info(this.message)
      : type = StatusType.info,
        timestamp = DateTime.now();

  StatusMessage.success(this.message)
      : type = StatusType.success,
        timestamp = DateTime.now();

  StatusMessage.error(this.message)
      : type = StatusType.error,
        timestamp = DateTime.now();

  StatusMessage.loading(this.message)
      : type = StatusType.loading,
        timestamp = DateTime.now();
}

enum StatusType {
  info,
  success,
  error,
  loading,
}

class StatusNotifier extends StateNotifier<StatusMessage?> {
  StatusNotifier() : super(null);

  void showInfo(String message) {
    state = StatusMessage.info(message);
    _clearAfterDelay();
  }

  void showSuccess(String message) {
    state = StatusMessage.success(message);
    _clearAfterDelay();
  }

  void showError(String message) {
    state = StatusMessage.error(message);
    _clearAfterDelay(duration: const Duration(seconds: 5));
  }

  void showLoading(String message) {
    state = StatusMessage.loading(message);
    // Don't auto-clear loading messages
  }

  void clear() {
    state = null;
  }

  void _clearAfterDelay({Duration duration = const Duration(seconds: 3)}) {
    Future.delayed(duration, () {
      if (mounted) {
        state = null;
      }
    });
  }
}

final statusProvider = StateNotifierProvider<StatusNotifier, StatusMessage?>((ref) {
  return StatusNotifier();
});
