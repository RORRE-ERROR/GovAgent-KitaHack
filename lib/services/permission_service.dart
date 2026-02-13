import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> isMicrophoneGranted() async {
    return await Permission.microphone.isGranted;
  }

  Future<void> openSettingsIfDenied() async {
    final status = await Permission.microphone.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
}
