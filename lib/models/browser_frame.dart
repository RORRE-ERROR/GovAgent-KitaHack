import 'dart:typed_data';

class BrowserFrame {
  final Uint8List imageBytes;
  final String? actionLabel;
  final DateTime timestamp;

  const BrowserFrame({
    required this.imageBytes,
    this.actionLabel,
    required this.timestamp,
  });

  factory BrowserFrame.fromJson(Map<String, dynamic> json, Uint8List imageBytes) {
    return BrowserFrame(
      imageBytes: imageBytes,
      actionLabel: json['action'] as String?,
      timestamp: DateTime.now(),
    );
  }
}
