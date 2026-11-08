import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectorService {
  late final PoseDetector _poseDetector;
  bool _isBusy = false;
  bool _isDisposed = false;
  DateTime _lastProcessedTime = DateTime.fromMillisecondsSinceEpoch(0);
  
  // Throttle to max ~18 frames per second to ensure smooth real-time tracking
  static const int minFrameIntervalMs = 55;

  PoseDetectorService({PoseDetectionModel model = PoseDetectionModel.base}) {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: model,
      ),
    );
  }

  Future<Pose?> processCameraImage({
    required CameraImage cameraImage,
    required CameraDescription cameraDescription,
  }) async {
    if (_isDisposed) return null;

    final now = DateTime.now();
    if (_isBusy || now.difference(_lastProcessedTime).inMilliseconds < minFrameIntervalMs) {
      return null;
    }

    _isBusy = true;
    _lastProcessedTime = now;

    try {
      final inputImage = await _createInputImageFromCameraImage(
        cameraImage: cameraImage,
        cameraDescription: cameraDescription,
      );

      if (inputImage == null) return null;

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty) {
        return poses.first;
      }
      return null;
    } catch (e) {
      // Gracefully handle any dropped or incompatible frame
      return null;
    } finally {
      _isBusy = false;
    }
  }

  Future<InputImage?> _createInputImageFromCameraImage({
    required CameraImage cameraImage,
    required CameraDescription cameraDescription,
  }) async {
    final sensorOrientation = cameraDescription.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[DeviceOrientation.portraitUp] ?? 0;
      if (cameraDescription.lensDirection == CameraLensDirection.front) {
        // Front-facing camera
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // Back-facing camera
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
    if (format == null) return null;

    // Plane byte concatenation. This is the heaviest per-frame CPU work and
    // must not run on the UI isolate: a 1080p YUV frame is several MB and
    // copying it on the main isolate causes GC pauses and dropped camera fps.
    // Each plane is handed to the worker as TransferableTypedData so the bytes
    // move instead of being copied twice.
    final transferables = cameraImage.planes
        .map((plane) => TransferableTypedData.fromList([plane.bytes]))
        .toList(growable: false);
    final bytes = await compute(_concatenatePlanes, transferables);

    final metadata = InputImageMetadata(
      size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: cameraImage.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  static final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _poseDetector.close();
  }
}

/// Runs in a background isolate. Materializes the transferred plane buffers
/// and copies them into one contiguous allocation for ML Kit.
Uint8List _concatenatePlanes(List<TransferableTypedData> chunks) {
  final planes = <Uint8List>[];
  var totalBytes = 0;
  for (final chunk in chunks) {
    final bytes = chunk.materialize().asUint8List();
    planes.add(bytes);
    totalBytes += bytes.lengthInBytes;
  }

  final output = Uint8List(totalBytes);
  var offset = 0;
  for (final plane in planes) {
    output.setRange(offset, offset + plane.lengthInBytes, plane);
    offset += plane.lengthInBytes;
  }
  return output;
}

