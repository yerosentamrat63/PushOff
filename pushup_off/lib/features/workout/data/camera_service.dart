import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraStateStatus {
  uninitialized,
  permissionDenied,
  permissionPermanentlyDenied,
  ready,
  error,
}

class CameraService {
  CameraController? _controller;
  CameraDescription? _selectedCamera;
  List<CameraDescription> _availableCameras = [];
  CameraStateStatus _status = CameraStateStatus.uninitialized;

  /// Serializes camera operations across every service instance so that a
  /// dispose from one screen can never race with an initialize from the next
  /// screen (both use the same physical camera).
  static Future<void> _operationQueue = Future<void>.value();

  CameraController? get controller => _controller;
  CameraDescription? get selectedCamera => _selectedCamera;
  CameraStateStatus get status => _status;
  bool get isReady => _controller != null && _controller!.value.isInitialized;
  bool get isFrontCamera => _selectedCamera?.lensDirection == CameraLensDirection.front;

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<CameraStateStatus> initialize({bool preferFront = true}) {
    return _serialized(() => _initialize(preferFront: preferFront));
  }

  Future<CameraStateStatus> _initialize({required bool preferFront}) async {
    // 1. Request camera permission
    final permissionStatus = await Permission.camera.request();
    if (permissionStatus.isPermanentlyDenied) {
      _status = CameraStateStatus.permissionPermanentlyDenied;
      return _status;
    } else if (permissionStatus.isDenied) {
      _status = CameraStateStatus.permissionDenied;
      return _status;
    }

    try {
      // 2. Discover available cameras
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        _status = CameraStateStatus.error;
        return _status;
      }

      // 3. Prefer front camera
      final target = _availableCameras.firstWhere(
        (cam) => preferFront
            ? cam.lensDirection == CameraLensDirection.front
            : cam.lensDirection == CameraLensDirection.back,
        orElse: () => _availableCameras.first,
      );

      // 4. Reuse an already initialized controller for the same lens instead of
      // opening the camera a second time (setup and countdown share detection).
      if (_controller != null &&
          _controller!.value.isInitialized &&
          _selectedCamera?.name == target.name) {
        _status = CameraStateStatus.ready;
        return _status;
      }

      await _disposeInternal();
      _selectedCamera = target;

      // 5. Initialize CameraController
      final controller = CameraController(
        target,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      _controller = controller;

      await controller.initialize();
      _status = CameraStateStatus.ready;
      return _status;
    } catch (e) {
      debugPrint('CameraService error: $e');
      await _disposeInternal();
      _status = CameraStateStatus.error;
      return _status;
    }
  }

  void startImageStream(Function(CameraImage image) onImage) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    try {
      controller.startImageStream(onImage);
    } catch (e) {
      debugPrint('Error starting image stream: $e');
    }
  }

  Future<void> stopImageStream() {
    return _serialized(_stopImageStreamInternal);
  }

  Future<void> _stopImageStreamInternal() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (!controller.value.isStreamingImages) return;

    try {
      await controller.stopImageStream();
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_availableCameras.length < 2) return;
    final isCurrentFront = _selectedCamera?.lensDirection == CameraLensDirection.front;
    await initialize(preferFront: !isCurrentFront);
  }

  Future<void> dispose() {
    return _serialized(_disposeInternal);
  }

  Future<void> _disposeInternal() async {
    // Detach first so a concurrent initialize can never have its fresh
    // controller disposed by this cleanup pass.
    final controller = _controller;
    _controller = null;

    if (controller != null) {
      try {
        if (controller.value.isInitialized && controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (e) {
        debugPrint('Error stopping image stream during dispose: $e');
      }

      try {
        await controller.dispose();
      } catch (e) {
        debugPrint('Error disposing camera: $e');
      }
    }

    _status = CameraStateStatus.uninitialized;
  }
}
