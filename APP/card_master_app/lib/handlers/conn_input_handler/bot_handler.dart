import 'dart:typed_data';
import 'package:card_master/handlers/conn_input_handler/handler.dart';

class BotInputHandler extends ConnectionInputHandler {
  static final String CMD_GETACARD = "ekak ganin";

  String? Function(String)? onLineReceived;

  BotInputHandler();

  List<int> buffer = [];
  String line = "";

  void listenToOnLineReceived(String? Function(String) callback) {
    onLineReceived = callback;
  }

  void sendString(String s) {
    Uint8List commandBytes = Uint8List.fromList(s.codeUnits);
    sendCommand(commandBytes);
  }

  void reset() {
    buffer.clear();
    line = "";
  }

  void _lineDone() {
    if (onLineReceived == null || line.isEmpty) return;
    String? reply = onLineReceived!.call(line);
  }

  @override
  void pushBytes(Uint8List bytes) {
    for (var byte in bytes) {
      // Check if byte is \n
      if (byte == 10) {
        line = String.fromCharCodes(buffer).trim();
        buffer.clear();
        _lineDone();
        break;
      }

      buffer.add(byte);
    }

    super.pushBytes(bytes);
  }
}
