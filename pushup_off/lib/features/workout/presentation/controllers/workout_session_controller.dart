import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../data/camera_service.dart';
import '../../data/feedback_service.dart';
import '../../data/pose_detector_service.dart';
import '../../data/tts_service.dart';
import '../../domain/models/completed_set_summary.dart';
import '../../domain/models/mlkit_pose_adapter.dart';
import '../../domain/models/rep_counter_output.dart';
import '../../domain/pose_landmarks_extension.dart';
import '../../domain/rep_counter.dart';
import '../../domain/rep_counter_config.dart';
import '../../../settings/presentation/settings_controller.dart';

class WorkoutSessionState {
  final CameraStateStatus cameraStatus;
  final Pose? currentPose;
  final LandmarkVisibilityStatus visibilityStatus;
  final Size imageSize;
  final bool isFrontCamera;
  final RepCounterOutput repOutput;
  final int secondsElapsed;
  final bool isPaused;
  final bool isSessionActive;
  final bool showRejectionFlash;

  const WorkoutSessionState({
    this.cameraStatus = CameraStateStatus.uninitialized,
    this.currentPose,
    this.visibilityStatus = const LandmarkVisibilityStatus(
      shouldersVisible: false,
      elbowsVisible: false,
      wristsVisible: false,
      hipsVisible: false,
      anklesVisible: false,
      averageConfidence: 0.0,
    ),
    this.imageSize = Size.zero,
    this.isFrontCamera = true,
    this.repOutput = const RepCounterOutput(),
    this.secondsElapsed = 0,
    this.isPaused = false,
    this.isSessionActive = false,
    this.showRejectionFlash = false,
  });

  WorkoutSessionState copyWith({
    CameraStateStatus? cameraStatus,
    Pose? currentPose,
    LandmarkVisibilityStatus? visibilityStatus,
    Size? imageSize,
    bool? isFrontCamera,
    RepCounterOutput? repOutput,
    int? secondsElapsed,
    bool? isPaused,
    bool? isSessionActive,
    bool? showRejectionFlash,
  }) {
    return WorkoutSessionState(
      cameraStatus: cameraStatus ?? this.cameraStatus,
      currentPose: currentPose ?? this.currentPose,
      visibilityStatus: visibilityStatus ?? this.visibilityStatus,
      imageSize: imageSize ?? this.imageSize,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      repOutput: repOutput ?? this.repOutput,
      secondsElapsed: secondsElapsed ?? this.secondsElapsed,
      isPaused: isPaused ?? this.isPaused,
      isSessionActive: isSessionActive ?? this.isSessionActive,
      showRejectionFlash: showRejectionFlash ?? this.showRejectionFlash,
    );
  }
}

class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  final CameraService _cameraService;
  final PoseDetectorService _poseDetectorService;
  final TtsService _ttsService;
  final FeedbackService _feedbackService;
  final Ref _ref;
  final RepCounter _repCounter = RepCounter(config: RepCounterConfig.defaultConfig);

  Timer? _sessionTimer;
  Timer? _flashResetTimer;
  int _lastValidRepsSpoken = 0;
  int _lastRejectedCount = 0;
  bool _appPaused = false;
  bool _manualPausedBeforeAppPause = false;
  bool _preferFront = true;

  WorkoutSessionNotifier({
    required CameraService cameraService,
    required PoseDetectorService poseDetectorService,
    required TtsService ttsService,
    required FeedbackService feedbackService,
    required Ref ref,
  })  : _cameraService = cameraService,
        _poseDetectorService = poseDetectorService,
        _ttsService = ttsService,
        _feedbackService = feedbackService,
        _ref = ref,
        super(const WorkoutSessionState());

  CameraService get cameraService => _cameraService;

  Future<void> startWorkoutSession({bool preferFront = true}) async {
    if (state.isSessionActive) return;

    _preferFront = preferFront;
    _appPaused = false;
    _repCounter.reset();
    _lastValidRepsSpoken = 0;
    _lastRejectedCount = 0;

    // Enable screen wake lock throughout the set
    await _feedbackService.enableWakeLock();

    final status = await _cameraService.initialize(preferFront: preferFront);
    if (status != CameraStateStatus.ready) {
      state = state.copyWith(cameraStatus: status);
      return;
    }

    final cameraDescription = _cameraService.selectedCamera;
    final isFront = _cameraService.isFrontCamera;

    state = state.copyWith(
      cameraStatus: status,
      isFrontCamera: isFront,
      isSessionActive: true,
      isPaused: false,
      secondsElapsed: 0,
      repOutput: const RepCounterOutput(),
      showRejectionFlash: false,
    );

    _startTimer();
    _attachImageStream(cameraDescription);
  }

  void _attachImageStream(CameraDescription? cameraDescription) {
    if (cameraDescription == null) return;

    _cameraService.startImageStream((cameraImage) async {
      if (state.isPaused || _appPaused) return;

      final pose = await _poseDetectorService.processCameraImage(
        cameraImage: cameraImage,
        cameraDescription: cameraDescription,
      );

      if (!mounted) return;

      if (pose != null) {
        final visibility = LandmarkVisibilityStatus.fromPose(pose, threshold: 0.6);
        final poseFrame = MLKitPoseAdapter.toPoseFrame(pose);
        final repOutput = _repCounter.processFrame(poseFrame);

        // Handle audio & haptic feedback + visual flash
        _handleRepFeedback(repOutput);

        state = state.copyWith(
          currentPose: pose,
          visibilityStatus: visibility,
          imageSize: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
          repOutput: repOutput,
        );
      }
    });
  }

  /// Called when the app leaves the foreground. Follows the required teardown
  /// order: stream -> camera -> wake lock. The detector stays alive so the set
  /// can resume without losing state.
  Future<void> handleAppPaused() async {
    if (!state.isSessionActive || _appPaused) return;
    _appPaused = true;
    _manualPausedBeforeAppPause = state.isPaused;
    _sessionTimer?.cancel();

    await _cameraService.stopImageStream();
    await _cameraService.dispose();
    await _feedbackService.disableWakeLock();
  }

  /// Restores the camera after the app returns to the foreground.
  Future<void> handleAppResumed() async {
    if (!state.isSessionActive || !_appPaused) return;
    _appPaused = false;

    final status = await _cameraService.initialize(preferFront: _preferFront);
    if (!mounted) return;

    if (status != CameraStateStatus.ready) {
      state = state.copyWith(cameraStatus: status, isPaused: true);
      return;
    }

    await _feedbackService.enableWakeLock();
    if (!mounted) return;

    state = state.copyWith(
      cameraStatus: status,
      isPaused: _manualPausedBeforeAppPause,
    );
    _attachImageStream(_cameraService.selectedCamera);
    if (!_manualPausedBeforeAppPause) {
      _startTimer();
    }
  }

  void _handleRepFeedback(RepCounterOutput repOutput) {
    // 1. Newly completed valid rep
    if (repOutput.validReps > _lastValidRepsSpoken) {
      _lastValidRepsSpoken = repOutput.validReps;
      _feedbackService.triggerValidRepHaptic();

      final ttsEnabled = _ref.read(voiceRepCountEnabledProvider);
      if (ttsEnabled) {
        _ttsService.speakRep(_lastValidRepsSpoken, enabled: true);
      }
    }
    // 2. Newly rejected rep
    else if (repOutput.rejectedReps > _lastRejectedCount) {
      _lastRejectedCount = repOutput.rejectedReps;
      _feedbackService.triggerRejectionHaptic();

      // Trigger short red/warning flash overlay
      state = state.copyWith(showRejectionFlash: true);
      _flashResetTimer?.cancel();
      _flashResetTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          state = state.copyWith(showRejectionFlash: false);
        }
      });

      final ttsEnabled = _ref.read(voiceRepCountEnabledProvider);
      final reason = repOutput.latestRejectionReason;
      if (ttsEnabled && reason != null) {
        _ttsService.speakAlert(reason.coachTip, enabled: true);
      }
    }
  }

  void togglePause() {
    final newPaused = !state.isPaused;
    if (newPaused) {
      _sessionTimer?.cancel();
    } else {
      _startTimer();
    }
    state = state.copyWith(isPaused: newPaused);
  }

  void _startTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isPaused) {
        state = state.copyWith(secondsElapsed: state.secondsElapsed + 1);
      }
    });
  }

  Future<CompletedSetSummary> endWorkoutSession() async {
    _sessionTimer?.cancel();
    _flashResetTimer?.cancel();

    // Exact teardown order: stop frames, release the camera, close the native
    // ML Kit detector, then drop the wake lock.
    await _cameraService.stopImageStream();
    await _cameraService.dispose();
    await _poseDetectorService.dispose();
    await _feedbackService.disableWakeLock();

    final summary = CompletedSetSummary(
      validReps: state.repOutput.validReps,
      rejectedReps: state.repOutput.rejectedReps,
      formScore: state.repOutput.formScore,
      durationSeconds: state.secondsElapsed,
      rejectedRepsList: state.repOutput.rejectedRepsList,
      completedAt: DateTime.now(),
      averageElbowAngle: state.repOutput.liveElbowAngle,
      averageBodyLineAngle: state.repOutput.liveBodyLineAngle,
      prominentSide: state.repOutput.activeSide.name,
    );

    // Save to completed set provider
    _ref.read(lastCompletedSetProvider.notifier).state = summary;

    state = state.copyWith(
      isSessionActive: false,
      cameraStatus: CameraStateStatus.uninitialized,
      currentPose: null,
      showRejectionFlash: false,
    );

    return summary;
  }

  Future<void> _teardownResources() async {
    // Stream -> camera -> native detector -> wake lock. CameraService also
    // serializes these calls so a new session cannot race this cleanup.
    await _cameraService.stopImageStream();
    await _cameraService.dispose();
    await _poseDetectorService.dispose();
    await _feedbackService.disableWakeLock();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _flashResetTimer?.cancel();
    _ttsService.stop();
    unawaited(_teardownResources());
    super.dispose();
  }
}

final feedbackServiceProvider = Provider<FeedbackService>((ref) => FeedbackService());

final ttsServiceProvider = Provider<TtsService>((ref) {
  final tts = TtsService();
  ref.onDispose(() => tts.stop());
  return tts;
});

final lastCompletedSetProvider = StateProvider<CompletedSetSummary?>((ref) => null);

final workoutSessionProvider =
    StateNotifierProvider.autoDispose<WorkoutSessionNotifier, WorkoutSessionState>((ref) {
  // The live workout owns its own camera and detector instances. Detection has
  // already released the setup/countdown camera before this provider starts.
  final ttsService = ref.watch(ttsServiceProvider);
  final feedbackService = ref.watch(feedbackServiceProvider);

  return WorkoutSessionNotifier(
    cameraService: CameraService(),
    poseDetectorService: PoseDetectorService(),
    ttsService: ttsService,
    feedbackService: feedbackService,
    ref: ref,
  );
});
