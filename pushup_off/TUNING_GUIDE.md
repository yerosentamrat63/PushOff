# Push-Up Off — Real Device Testing & Kinematic Calibration Guide

This guide details calibration procedures, real-device mounting recommendations, lighting mitigation, and threshold tuning parameters for **Push-Up Off**.

---

## 1. Optimal Camera Setup & Mounting

| Parameter | Recommended Specification | Acceptable Range | Notes |
| :--- | :--- | :--- | :--- |
| **Distance** | **2.0 meters (6.5 ft)** | 1.6m – 2.6m | Entire body (head to heels) must remain in-frame at both top and bottom of movement. |
| **Camera Angle** | **70° to 90° Lateral Profile** | 60° – 90° | Side profile view produces the highest precision for elbow flexion and hip sagittal alignment. |
| **Phone Height** | **15 – 30 cm off the floor** | Floor to 45 cm | Propping the device against a water bottle or small stand tilted slightly upward ($\sim 15^\circ$) yields ideal keypoint tracking. |
| **Orientation** | **Portrait** | Portrait | App UI and ML Kit processing pipeline are optimized for vertical orientation. |

---

## 2. Environmental Lighting Protocols

### A. Backlighting (Avoid)
- **Symptom**: When bright windows, spotlights, or sunlight are directly behind the user, the athlete becomes a dark silhouette. ML Kit joint confidence scores drop below $0.4$.
- **Remedy**: Position the camera with the light source **behind or beside the camera**, illuminating the chest, elbows, and hips.

### B. Low Indoor Lighting
- **Symptom**: Low frame illumination causes motion blur during fast descents, resulting in noisy landmark coordinates.
- **Remedy**: The app displays an amber tracking warning: *"Move back into frame / Increase lighting"*. Turn on overhead or ambient room lights.

---

## 3. Kinematic Thresholds Tuning Matrix

All kinematic parameters are centralized in [`rep_counter_config.dart`](lib/features/workout/domain/rep_counter_config.dart):

```dart
class RepCounterConfig {
  final double minElbowDepthAngle;     // Default: 90.0°
  final double minElbowLockoutAngle;   // Default: 155.0°
  final double minBodyLineAngle;       // Default: 165.0°
  final double enterDownAngle;         // Default: 100.0°
  final double leaveDownAngle;         // Default: 120.0°
  final double enterUpAngle;           // Default: 155.0°
  final double minRepDurationSeconds;  // Default: 0.40s
  final int movingAverageWindowSize;   // Default: 5 frames
  final double minConfidenceThreshold; // Default: 0.60
}
```

### When and How to Tune Each Parameter:

### 1. `minElbowDepthAngle` (Elbow Depth)
- **Default**: $90.0^\circ$
- **Strict / Competition Mode**: $90.0^\circ$ (upper arm parallel to floor).
- **Casual / General Fitness Mode**: If beta testers report legitimate reps being rejected with *"Go lower"*, adjust to **$95.0^\circ$** or **$98.0^\circ$**.
- **Loose Clothing**: Baggy hoodies can obscure the elbow joint vertex by $4^\circ - 7^\circ$. Tighter athletic wear is recommended for strict scoring.

### 2. `minElbowLockoutAngle` (Arm Extension at Top)
- **Default**: $155.0^\circ$
- **Tuning**: Some athletes have natural joint stiffness or anatomical restrictions preventing full $180^\circ$ hyperextension.
- If users trigger *"No lockout"* despite fully pushing up, reduce to **$150.0^\circ$**.

### 3. `minBodyLineAngle` (Hip Sagging & Piking)
- **Default**: $165.0^\circ$
- **Sagging**: Measured when the hip vertex drops below the shoulder-ankle vector (cross-product sign check).
- **Piking**: Measured when the hip vertex elevates above the vector (butt in air).
- If natural lumbar lordosis or baggy workout shorts cause false sagging rejections, adjust to **$160.0^\circ$**.

### 4. `minRepDurationSeconds` (Rep Cadence Guard)
- **Default**: $0.40\text{ seconds}$
- Discards bouncing, partial twitches, or camera noise.
- For elite calisthenics speed reps, adjust to **$0.35\text{s}$**. Never set below $0.25\text{s}$ to preserve anti-cheat validity.

### 5. Angle Smoothing (1€ Filter)
- **`oneEuroMinCutoff`** (default $1.2\text{ Hz}$): baseline cutoff. Lower = smoother but slightly laggier at rest.
- **`oneEuroBeta`** (default $0.05$): speed coefficient. Higher = less phase lag during fast reps by raising the cutoff when angular velocity is high.
- **`oneEuroDerivativeCutoff`** (default $1.0\text{ Hz}$): smoothing applied to the estimated angular velocity.
- **`useOneEuroFilter`** (default `true`): set to `false`, or `movingAverageWindowSize: 1`, to consume raw angles (used by deterministic unit tests).
- At $\sim 18\text{ FPS}$ ($55\text{ms}$ throttle) the adaptive cutoff removes jitter without suppressing the turnaround inflection of a ~400ms rep, which a fixed 5-frame moving average did.

### 6. Depth-Aware Angles
- When landmark depth (`z`, ML Kit image-space depth) is present, elbow and body-line angles are computed in 3D so a camera that is not exactly side-on does not foreshorten shallow reps into appearing deep.
- Sources without depth (or all-zero `z`) fall back to the 2D calculation automatically.

---

## 4. Platform-Specific Verifications

### Android Verifications (Pixel, Samsung Galaxy, OnePlus)
- **Image Format**: Stream delivers `YUV_420_8888` or `NV21`.
- **Front Camera Sensor Orientation**: Typically $270^\circ$. Handled by `InputImageRotation.rotation270deg`. Horizontal mirroring is applied **only** in `PoseSkeletonPainter` for display; angle math consumes the unmirrored landmarks, so sag/pike classification stays consistent.
- **Battery Optimization**: Verify that app backgrounding pauses camera streams and releases the wakelock cleanly.

### iOS Verifications (iPhone 12 through 16 Pro)
- **Image Format**: Stream delivers `BGRA8888`.
- **Front Camera Sensor Orientation**: Typically $90^\circ$. Handled by `InputImageRotation.rotation90deg`.
- **Screen Wake Lock**: Verify `WakelockPlus.enable()` prevents the iPhone from dimming the screen during 3-minute sets.
- **Haptic Engine**: Taptic engine pulses on rejection via `HapticFeedback.heavyImpact()`.

---

## 5. Verification Checklist Before Store Release

- [x] Onboarding permission prompt properly explains camera usage (zero cloud video upload).
- [x] Skeleton overlay painter matches athlete's real-time motion without perceptible lag ($<60\text{ms}$).
- [x] Screen wake lock activates upon workout start and deactivates upon set completion.
- [x] Rejection flash visually alerts user without obstructing camera preview.
- [x] Spoken TTS cues do not overlap and honor the Settings audio toggle.
- [x] Firestore security rules block tampered uploads ($>90\text{ reps/minute}$).
- [x] SQLite local cache preserves workout history offline.

