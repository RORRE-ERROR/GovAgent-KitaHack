import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:gov_agent/config/app_config.dart';
import 'package:gov_agent/models/browser_frame.dart';
import 'package:gov_agent/models/tool_call.dart';

class BackendWebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  final _frameController = StreamController<BrowserFrame>.broadcast();
  final _toolResultController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<BrowserFrame> get frameStream => _frameController.stream;
  Stream<Map<String, dynamic>> get toolResultStream => _toolResultController.stream;

  Future<void> connect() async {
    final uri = Uri.parse(AppConfig.backendUrl);
    _channel = WebSocketChannel.connect(uri);

    await _channel!.ready;
    _isConnected = true;

    _channel!.stream.listen(
      (message) {
        final json = jsonDecode(message as String) as Map<String, dynamic>;
        final type = json['type'] as String;

        switch (type) {
          case 'screenshot':
            final imageBase64 = json['data'] as String;
            final imageBytes = base64Decode(imageBase64);
            _frameController.add(BrowserFrame.fromJson(json, Uint8List.fromList(imageBytes)));
          case 'tool_result':
            _toolResultController.add(json);
          default:
            break;
        }
      },
      onError: (error) {
        _isConnected = false;
      },
      onDone: () {
        _isConnected = false;
      },
    );
  }

  void sendToolCall(ToolCall toolCall) {
    if (!_isConnected || _channel == null) return;

    final message = jsonEncode({
      'type': 'tool_call',
      ...toolCall.toJson(),
    });
    _channel!.sink.add(message);
  }

  Future<void> disconnect() async {
    _isConnected = false;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _frameController.close();
    _toolResultController.close();
  }
}
