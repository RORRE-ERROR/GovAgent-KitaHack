class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;
  final bool requiresConfirmation;

  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    this.requiresConfirmation = false,
  });

  factory ToolCall.fromGemini(Map<String, dynamic> json) {
    final name = json['name'] as String;
    return ToolCall(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      arguments: Map<String, dynamic>.from(json['args'] as Map? ?? {}),
      requiresConfirmation: name == 'submit_form',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'args': arguments,
      };
}
