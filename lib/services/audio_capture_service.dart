import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:gov_agent/config/app_config.dart';

class AudioCaptureService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Stream<Uint8List> startCapture() {
    final controller = StreamController<Uint8List>();

    () async {
      try {
        final stream = await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: AppConfig.micSampleRate,
            numChannels: 1,
            autoGain: true,
            echoCancel: true,
            noiseSuppress: true,
          ),
        );

        _isRecording = true;

        _subscription = stream.listen(
          (data) => controller.add(data),
          onError: (error) => controller.addError(error),
          onDone: () => controller.close(),
        );
      } catch (e) {
        controller.addError(e);
        controller.close();
      }
    }();

    return controller.stream;
  }

  Future<void> stopCapture() async {
    _isRecording = false;
    await _subscription?.cancel();
    _subscription = null;
    await _recorder.stop();
  }

  Future<double> getAmplitude() async {
    if (!_isRecording) return 0.0;
    final amp = await _recorder.getAmplitude();
    // Normalize from dBFS (typically -160 to 0) to 0.0-1.0
    final normalized = (amp.current + 60) / 60;
    return normalized.clamp(0.0, 1.0);
  }

  void dispose() {
    stopCapture();
    _recorder.dispose();
  }
}
