import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RemotePlayHandler extends ChangeNotifier {
  final String serverUrl = "ws://161.97.145.21:6969";

  WebSocketChannel? channel;
  String? myCode;
  bool paired = false;
  bool connecting = false;

  final Function onConnected;
  final Function(String code) onCodeReceived;
  final Function onPaired;
  final Function(String message) onMessageReceived;
  final Function onPairLost;
  final Function(String msg) onErrorReceived;
  final Function onDisconnected;

  RemotePlayHandler({required this.onConnected, required this.onCodeReceived, required this.onPaired, required this.onPairLost, required this.onDisconnected, required this.onErrorReceived, required this.onMessageReceived});

  void connectAndHost() async {
    if (connecting) return;
    connecting = true;
    notifyListeners();

    try {
      channel = IOWebSocketChannel(await WebSocket.connect(serverUrl));

      channel!.stream.listen(
        (message) {
          final jsonData = jsonDecode(message.toString());
          _handleIncomingJson(jsonData);
        },
        onDone: () {
          onDisconnected();
          _resetState();
        },
        onError: (_) {
          _resetState();
          onDisconnected();
        },
        cancelOnError: true,
      );
      onConnected();
      hostGame();
    } catch (e) {
      _resetState();
      onDisconnected();
      debugPrint("Error connecting to WebSocket: $e");
    }
  }

  void _handleIncomingJson(Map<String, dynamic> jsonData) {
    switch (jsonData['type']) {
      case 'host_ready':
        myCode = jsonData['code'];
        connecting = false;
        notifyListeners();
        onCodeReceived(myCode!);
        break;
      case 'paired':
        paired = true;
        notifyListeners();
        onPaired();
        break;
      case 'message':
        final message = jsonData['text'];
        notifyListeners();
        onMessageReceived(message);
        break;
      case 'error':
        final errorMsg = jsonData['message'];
        notifyListeners();
        onErrorReceived(errorMsg);
        break;
      case 'disconnected':
        paired = false;
        notifyListeners();
        onPairLost();
        break;
      default:
        debugPrint("Unknown message type: ${jsonData['type']}");
    }
  }

  void hostGame() {
    channel?.sink.add('{"type":"host"}');
  }

  void joinGame(String code) {
    channel?.sink.add('{"type":"join", "code":"$code"}');
  }

  void sendMessage(String msg) {
    channel?.sink.add('{"type":"message", "text":"$msg"}');
  }

  void disconnect() {
    if (channel == null) return;
    channel!.sink.close();
    _resetState();
    onDisconnected();
  }

  void _resetState() {
    connecting = false;
    myCode = null;
    paired = false;
    notifyListeners();
  }
}
