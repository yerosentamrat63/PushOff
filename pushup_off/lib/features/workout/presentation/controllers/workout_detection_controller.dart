import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../data/camera_service.dart';
import '../../data/pose_detector_service.dart';
import '../../domain/pose_landmarks_extension.dart';

class DetectionState {
  final CameraStateStatus cameraStatus;
  final Pose? currentPose;
  final LandmarkVisibilityStatus visibilityStatus;
  final Size imageSize;
  final bool isFrontCamera;

  const DetectionState({
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
  });

  DetectionState copyWith({
    CameraStateStatus? cameraStatus,
    Pose? currentPose,
    LandmarkVisibilityStatus? visibilityStatus,
    Size? imageSize,
    bool? isFrontCamera,
  }) {
    return DetectionState(
      cameraStatus: cameraStatus ?? this.cameraStatus,
      currentPose: currentPose ?? this.currentPose,
      visibilityStatus: visibilityStatus ?? this.visibilityStatus,
      imageSize: imageSize ?? this.imageSize,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
    );
  }
}

class WorkoutDetectionNotifier extends StateNotifier<DetectionState> {
  final CameraService _cameraService;
  final PoseDetectorService _poseDetectorService;

  WorkoutDetectionNotifier(this._cameraService, this._poseDetectorService)
      : super(const DetectionState());

  CameraService get cameraService => _cameraService;

  Future<void> startDetection({bool preferFront = true}) async {
    var status = _cameraService.status;

    // Setup and countdown share a single detection session; only open the
    // camera if it is not already healthy.
    if (status != CameraStateStatus.ready || !_cameraService.isReady) {
      status = await _cameraService.initialize(preferFront: preferFront);
    }

    if (status != CameraStateStatus.ready) {
      state = state.copyWith(cameraStatus: status);
      return;
    }

    state = state.copyWith(
      cameraStatus: status,
      isFrontCamera: _cameraService.isFrontCamera,
    );
    _attachStream();
  }

  void _attachStream() {
    final cameraDescription = _cameraService.selectedCamera;
    if (cameraDescription == null) return;

    _cameraService.startImageStream((cameraImage) async {
      final pose = await _poseDetectorService.processCameraImage(
        cameraImage: cameraImage,
        cameraDescription: cameraDescription,
      );

      if (!mounted || pose == null) return;

      final visibility = LandmarkVisibilityStatus.fromPose(pose, threshold: 0.6);
      state = state.copyWith(
        currentPose: pose,
        visibilityStatus: visibility,
        imageSize: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
      );
    });
  }

  Future<void> switchCamera() async {
    await _cameraService.switchCamera();
    if (!mounted) return;

    state = state.copyWith(
      cameraStatus: _cameraService.status,
      isFrontCamera: _cameraService.isFrontCamera,
    );

    if (_cameraService.isReady) {
      _attachStream();
    }
  }

  Future<void> stopDetection() async {
    await _cameraService.stopImageStream();
    await _cameraService.dispose();
    if (mounted) {
      state = const DetectionState();
    }
  }

  @override
  void dispose() {
    // The camera and pose detector are owned by their auto-dispose providers,
    // which release them when this notifier goes away.
    unawaited(_cameraService.dispose());
    super.dispose();
  }
}

final cameraServiceProvider = Provider.autoDispose<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(service.dispose);
  return service;
});

final poseDetectorServiceProvider = Provider.autoDispose<PoseDetectorService>((ref) {
  final service = PoseDetectorService();
  ref.onDispose(service.dispose);
  return service;
});

final workoutDetectionProvider =
    StateNotifierProvider.autoDispose<WorkoutDetectionNotifier, DetectionState>((ref) {
  final cameraService = ref.watch(cameraServiceProvider);
  final poseDetectorService = ref.watch(poseDetectorServiceProvider);
  return WorkoutDetectionNotifier(cameraService, poseDetectorService);
});
