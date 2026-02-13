import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:gov_agent/config/app_config.dart';

class AudioPlaybackService {
  SoLoud? _soloud;
  AudioSource? _currentSource;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    _soloud = SoLoud.instance;
    await _soloud!.init();
    _initialized = true;
  }

  Future<void> playPcmData(Uint8List pcmData) async {
    if (!_initialized) await initialize();

    // Create a WAV header for the PCM data so SoLoud can play it
    final wavData = _createWavFromPcm(pcmData, AppConfig.playbackSampleRate);

    // Dispose previous source if exists
    if (_currentSource != null) {
      _soloud!.disposeSource(_currentSource!);
    }

    _currentSource = await _soloud!.loadMem(
      'response.wav',
      wavData,
    );
    await _soloud!.play(_currentSource!);
  }

  void clearPlayback() {
    if (_currentSource != null && _initialized) {
      _soloud!.disposeSource(_currentSource!);
      _currentSource = null;
    }
  }

  Uint8List _createWavFromPcm(Uint8List pcmData, int sampleRate) {
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt sub-chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // sub-chunk size
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);

    // data sub-chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final wav = Uint8List(44 + dataSize);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + dataSize, pcmData);
    return wav;
  }

  void dispose() {
    clearPlayback();
    if (_initialized) {
      _soloud?.deinit();
      _initialized = false;
    }
  }
}
