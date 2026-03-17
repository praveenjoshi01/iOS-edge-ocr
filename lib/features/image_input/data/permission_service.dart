import 'package:permission_handler/permission_handler.dart';

/// Service wrapping permission_handler for camera and photo library access.
///
/// Provides point-of-use permission requests (not upfront) and handles
/// the iOS "limited photos" access mode as an acceptable grant.
class PermissionService {
  /// Request camera permission. Returns true if granted.
  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request photo library permission. Returns true if granted or limited.
  /// Limited access (iOS 14+) is treated as granted -- user will see
  /// only their selected photos in the picker, which is acceptable.
  Future<bool> requestPhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  /// Check if a permission is permanently denied.
  Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings so user can re-enable a denied permission.
  /// Returns true if the settings page was opened.
  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
