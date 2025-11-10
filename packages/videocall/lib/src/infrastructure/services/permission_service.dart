import 'package:permission_handler/permission_handler.dart';

/// Service for handling app permissions
class PermissionService {
  /// Check if camera permission is granted
  static Future<bool> checkCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// Check if microphone permission is granted
  static Future<bool> checkMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  /// Request camera permission
  static Future<PermissionStatus> requestCameraPermission() async {
    return await Permission.camera.request();
  }

  /// Request microphone permission
  static Future<PermissionStatus> requestMicrophonePermission() async {
    return await Permission.microphone.request();
  }

  /// Request all required permissions for video calling
  static Future<Map<Permission, PermissionStatus>> requestVideoCallPermissions() async {
    return await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  /// Check if all required permissions are granted
  static Future<bool> hasAllRequiredPermissions() async {
    final cameraGranted = await checkCameraPermission();
    final micGranted = await checkMicrophonePermission();
    return cameraGranted && micGranted;
  }

  /// Open app settings
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}