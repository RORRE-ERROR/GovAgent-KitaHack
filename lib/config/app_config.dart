class AppConfig {
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'ws://localhost:8080/ws',
  );

  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.0-flash-live-001',
  );

  static const String appName = 'GovAgent';

  static const int micSampleRate = 16000;
  static const int playbackSampleRate = 24000;
}
