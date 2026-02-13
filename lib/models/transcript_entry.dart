enum Speaker { user, agent, system }

class TranscriptEntry {
  final Speaker speaker;
  final String text;
  final DateTime timestamp;

  const TranscriptEntry({
    required this.speaker,
    required this.text,
    required this.timestamp,
  });
}
