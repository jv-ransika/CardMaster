import 'dart:typed_data';

class ConnectionInputHandler {
  ConnectionInputHandler();

  Function? onConnected;
  Function? onDisconnected;

  Function(Uint8List)? onSendCommand;

  void pushBytes(Uint8List bytes) {
    // Handle incoming bytes
  }

  void sendCommand(Uint8List command) {
    if (onSendCommand != null) {
      onSendCommand!(command);
    }
  }

  void listenToOnSendCommand(Function(Uint8List) callback) {
    onSendCommand = callback;
  }

  void notifyConnected() {
    if (onConnected != null) onConnected!();
  }

  void notifyDisconnected() {
    if (onDisconnected != null) onDisconnected!();
  }
}
