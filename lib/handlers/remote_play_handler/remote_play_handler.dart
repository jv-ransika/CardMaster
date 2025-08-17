import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RemotePlayHandler {
  final String serverUrl = "ws://161.97.145.21:6969";

  WebSocketChannel? channel;
  String? myCode;
  bool paired = false;

  final Function onConnected;
  final Function(String code) onCodeReceived;
  final Function onPaired;
  final Function onPairLost;
  final Function onDisconnected;

  RemotePlayHandler({required this.onConnected, required this.onCodeReceived, required this.onPaired, required this.onPairLost, required this.onDisconnected});

  void connect() {
    try {
      channel = IOWebSocketChannel.connect(serverUrl); // emulator
      channel!.stream.listen((message) {
        final jsonData = jsonDecode(message.toString());
        _handleIncomingJson(jsonData);
      });
      onConnected();
    } catch (e) {
      debugPrint("Error connecting to WebSocket: $e");
    }
  }

  _handleIncomingJson(Map<String, dynamic> jsonData) {
    switch (jsonData['type']) {
      case 'host_ready':
        myCode = jsonData['data'];
        onCodeReceived(myCode!);
        break;
      case 'paired':
        paired = true;
        onPaired();
        break;
      case 'disconnected':
        paired = false;
        onDisconnected();
        break;
      default:
        debugPrint("Unknown message type: ${jsonData['type']}");
    }
  }

  void hostGame() {
    channel!.sink.add('{"type":"host"}');
  }

  void joinGame(String code) {
    channel!.sink.add('{"type":"join", "code":"$code"}');
  }

  void sendUpdate(String msg) {
    channel!.sink.add('{"type":"update", "data":"$msg"}');
  }

  void disconnect() {
    if (channel == null) return;
    channel!.sink.close();
    onDisconnected();
  }
}
