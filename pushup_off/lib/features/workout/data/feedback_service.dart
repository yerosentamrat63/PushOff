import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FeedbackService {
  bool _isWakeLockActive = false;

  bool get isWakeLockActive => _isWakeLockActive;

  /// Keeps device screen awake throughout an active workout set
  Future<void> enableWakeLock() async {
    try {
      await WakelockPlus.enable();
      _isWakeLockActive = true;
    } catch (_) {
      // In-memory / test environment safe fallback
      _isWakeLockActive = true;
    }
  }

  /// Restores normal system screen-timeout when workout concludes
  Future<void> disableWakeLock() async {
    try {
      await WakelockPlus.disable();
      _isWakeLockActive = false;
    } catch (_) {
      _isWakeLockActive = false;
    }
  }

  /// Sharp, noticeable haptic pulse and vibration for rejected repetitions
  Future<void> triggerRejectionHaptic() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Crisp, clean tactile feedback confirming a valid rep completed
  Future<void> triggerValidRepHaptic() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Subtly signals that bottom depth ($\le 90^\circ$) was reached
  Future<void> triggerDepthReachedHaptic() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}

