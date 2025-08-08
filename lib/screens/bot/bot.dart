import 'dart:async';
import 'dart:typed_data';
import 'package:card_master/config.dart';
import 'package:card_master/handlers/conn_input_handler/bot_handler.dart';
import 'package:card_master/handlers/conn_input_handler/image_handler.dart';
import 'package:card_master/screens/bot/connections_view.dart';
import 'package:card_master/screens/bot/omi_board.dart';
import 'package:card_master/tflite/tflite_model_isolate.dart';
import 'package:card_master/tflite/tflite_model.dart';
import 'package:card_master/tflite/yolo_detector.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum DeviceStatus { disconnected, connecting, connected }

class BotScreen extends StatefulWidget {
  const BotScreen({super.key});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
  bool isLoadingModels = true;

  TfliteModelIsolate yoloModel = TfliteModelIsolate(modelPath: "assets/yolo11s_f32.tflite");

  YoloDetector yoloDetector = YoloDetector();

  ImageInputHandler imageInputHandlerOuter = ImageInputHandler();
  ImageInputHandler imageInputHandlerInner = ImageInputHandler();
  BotInputHandler botInputHandler = BotInputHandler();

  double _progress = 0.0;

  bool _isDetecting = false;

  img.Image? _currentImage;

  OmiBoard omiBoard = OmiBoard();

  @override
  void initState() {
    super.initState();
    _getPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModels();
    });

    // Image capture listeners

    imageInputHandlerOuter.listenToOnImageCaptured((int width, int height) async {
      print("Outer Image Captured: Width: $width, Height: $height");
      _currentImage = imageInputHandlerOuter.image!;
      _progress = 0.0;
      List<YOLODetection> detections = await detectCurrentImage();
      // omiBoard.classifyDetections(detections, _currentImage!.width.toDouble(), _currentImage!.height.toDouble());
    });

    imageInputHandlerInner.listenToOnImageCaptured((int width, int height) async {
      print("Inner Image Captured: Width: $width, Height: $height");
      _currentImage = imageInputHandlerInner.image!;
      _currentImage = img.copyExpandCanvas(_currentImage!, newWidth: 800, newHeight: 800, backgroundColor: img.ColorRgb8(255, 255, 255));
      _progress = 0.0;
      List<YOLODetection> detections = await detectCurrentImage();
      // Do something...
    });

    // Image download progress update listeners

    imageInputHandlerOuter.listenToOnProgressUpdate((double progress) {
      _progress = progress;
      setState(() {});
    });

    imageInputHandlerInner.listenToOnProgressUpdate((double progress) {
      _progress = progress;
      setState(() {});
    });

    // Bot command listener

    botInputHandler.listenToOnLineReceived((String line) {
      print('Received: $line, ${line.length}');
      return null;
    });

    // onConnected and onDisconnected listeners

    imageInputHandlerOuter.onConnected = () {};

    imageInputHandlerInner.onConnected = () {};

    botInputHandler.onConnected = () {
      print("hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh");
      botInputHandler.sendString("hi");
    };
  }

  @override
  void dispose() {
    yoloModel.stop();
    super.dispose();
  }

  Future<void> _getPermissions() async {
    await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.locationWhenInUse].request();
  }

  Future<void> _loadModels() async {
    try {
      await yoloModel.start();
      isLoadingModels = false;
      setState(() {});
    } catch (e) {
      debugPrint('Error loading models: $e');
    }
  }

  void drawBoundaryBoxes(List<YOLODetection> detections, img.Image image) {
    for (var detection in detections) {
      print("${detection.className} - ${detection.confidence} - ${detection.boxX}, ${detection.boxY}, ${detection.boxWidth}, ${detection.boxHeight}");
      // Convert center-based coords to corner-based
      final x1 = (detection.boxX - detection.boxWidth / 2).toInt();
      final y1 = (detection.boxY - detection.boxHeight / 2).toInt();
      final x2 = (detection.boxX + detection.boxWidth / 2).toInt();
      final y2 = (detection.boxY + detection.boxHeight / 2).toInt();

      img.drawRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: img.ColorRgb8(0, 255, 0), thickness: 2);
    }
  }

  Future<List<YOLODetection>> detectCurrentImage() async {
    setState(() {
      _isDetecting = true;
    });

    try {
      List<YOLODetection> detections = await yoloDetector.detectObjects(_currentImage!, yoloModel);

      drawBoundaryBoxes(detections, _currentImage!);

      setState(() {
        _isDetecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("YOLO detection completed.")));

      return detections;
    } catch (e) {
      print('Error during YOLO detection: $e');
    }

    setState(() {
      _isDetecting = true;
    });

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ESP32 BLE")),
      body: isLoadingModels
          ? Center(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Loading Models...")]),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (_isDetecting) LinearProgressIndicator(),
                  ConnectionsView(inputHandlers: {"Outer Camera": imageInputHandlerOuter, "Inner Camera": imageInputHandlerInner, "Bot": botInputHandler}),
                  ElevatedButton(
                    onPressed: () async {
                      imageInputHandlerOuter.captureImage();
                    },
                    child: const Text("Cap Outer"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      imageInputHandlerInner.captureImage();
                    },
                    child: const Text("Cap Inner"),
                  ),
                  LinearProgressIndicator(value: _progress),
                  // RawImage(image: _image),
                  _currentImage != null ? Image.memory(Uint8List.fromList(img.encodePng(_currentImage!)), fit: BoxFit.contain) : Text('No oc image captured yet.'),
                ],
              ),
            ),
    );
  }
}
