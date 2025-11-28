import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StatusType {
  info,
  success,
  error,
  loading,
}

class StatusMessage {
  final String message;
  final StatusType type;
  final DateTime timestamp;

  const StatusMessage({
    required this.message,
    required this.type,
    required this.timestamp,
  });

  factory StatusMessage.info(String message) => StatusMessage(
        message: message,
        type: StatusType.info,
        timestamp: DateTime.now(),
      );

  factory StatusMessage.success(String message) => StatusMessage(
        message: message,
        type: StatusType.success,
        timestamp: DateTime.now(),
      );

  factory StatusMessage.error(String message) => StatusMessage(
        message: message,
        type: StatusType.error,
        timestamp: DateTime.now(),
      );

  factory StatusMessage.loading(String message) => StatusMessage(
        message: message,
        type: StatusType.loading,
        timestamp: DateTime.now(),
      );
}

class StatusNotifier extends StateNotifier<StatusMessage?> {
  Timer? _clearTimer;

  StatusNotifier() : super(null);

  void showInfo(String message) {
    state = StatusMessage.info(message);
    _scheduleClear();
  }

  void showSuccess(String message) {
    state = StatusMessage.success(message);
    _scheduleClear();
  }

  void showError(String message) {
    state = StatusMessage.error(message);
    _scheduleClear(duration: const Duration(seconds: 5));
  }

  void showLoading(String message) {
    _cancelClearTimer();
    state = StatusMessage.loading(message);
  }

  void clear() {
    _cancelClearTimer();
    state = null;
  }

  void _scheduleClear({Duration duration = const Duration(seconds: 3)}) {
    _cancelClearTimer();
    _clearTimer = Timer(duration, () {
      if (mounted) {
        state = null;
      }
    });
  }

  void _cancelClearTimer() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }

  @override
  void dispose() {
    _cancelClearTimer();
    super.dispose();
  }
}

final statusProvider = StateNotifierProvider<StatusNotifier, StatusMessage?>((ref) {
  return StatusNotifier();
});
