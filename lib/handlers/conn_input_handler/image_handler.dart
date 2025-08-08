import 'dart:typed_data';
import 'package:card_master/handlers/conn_input_handler/handler.dart';
import 'package:image/image.dart' as img;

class ImageInputHandler extends ConnectionInputHandler {
  Function(int, int)? onImageCaptured;
  Function(double)? onProgressUpdate;

  ImageInputHandler();

  List<int> buffer = [];
  bool receivingImage = false;
  int imageSize = 0;
  int imageWidth = 0;
  int imageHeight = 0;
  int receivedBytes = 0;
  List<int> imageData = [];

  img.Image? image;

  double progress = 0.0;

  void listenToOnImageCaptured(Function(int, int) callback) {
    onImageCaptured = callback;
  }

  void listenToOnProgressUpdate(Function(double) callback) {
    onProgressUpdate = callback;
  }

  void reset() {
    buffer.clear();
    receivingImage = false;
    imageSize = 0;
    receivedBytes = 0;
    imageData.clear();
    image = null;
  }

  void captureImage() {
    reset();
    // Send command to capture image
    String command = "CAP\n";
    Uint8List commandBytes = Uint8List.fromList(command.codeUnits);
    sendCommand(commandBytes);
  }

  @override
  void pushBytes(Uint8List bytes) {
    for (var byte in bytes) {
      buffer.add(byte);

      // Check for start marker
      if (!receivingImage && buffer.length >= 4) {
        if (buffer.sublist(0, 4).toString() == [0xAA, 0x55, 0xAA, 0x55].toString()) {
          receivingImage = true;
          buffer.clear();
        }
      } else if (receivingImage && imageSize == 0 && buffer.length >= 8) {
        // Get image size
        imageSize = buffer[0] | (buffer[1] << 8) | (buffer[2] << 16) | (buffer[3] << 24);
        imageWidth = buffer[4] | (buffer[5] << 8);
        imageHeight = buffer[6] | (buffer[7] << 8);
        buffer.clear();
        receivedBytes = 0;
        imageData.clear();
      } else if (receivingImage && imageSize > 0) {
        imageData.add(byte);
        receivedBytes++;

        if (receivedBytes >= imageSize) {
          // Finished receiving image
          receivingImage = false;
          buffer.clear();

          // Display image
          image = img.decodeImage(Uint8List.fromList(imageData));
          // Use Image.memory(img) in your Flutter UI
          print("Image received: ${image!.lengthInBytes} bytes ($imageWidth x $imageHeight)");

          if (onImageCaptured != null) {
            onImageCaptured!(imageWidth, imageHeight);
          }
        }

        // Update progress
        progress = receivedBytes / imageSize;
        if (onProgressUpdate != null) {
          onProgressUpdate!(progress);
        }
      }
    }

    super.pushBytes(bytes);
  }
}
