import 'dart:async';
import 'package:card_master/handlers/conn_input_handler/bot_handler.dart';
import 'package:card_master/handlers/conn_input_handler/image_handler.dart';
import 'package:card_master/handlers/game_handler/game_handler.dart';
import 'package:card_master/onnx/onnx_model.dart';
import 'package:card_master/onnx/oomi_predictor.dart';
import 'package:card_master/screens/bot/cameras_view.dart';
import 'package:card_master/screens/bot/connections_view.dart';
import 'package:card_master/screens/bot/game_view.dart';
import 'package:card_master/screens/bot/logs_view.dart';
import 'package:card_master/screens/bot/test_view.dart';
import 'package:card_master/tflite/tflite_model_isolate.dart';
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
  /*
I/flutter (29486): Discovered device: CardMaster - OC (3C:8A:1F:D4:7C:1E)
D/FlutterBluePlugin(29486): Discovered 08:B6:1F:8E:7A:4E
I/flutter (29486): Discovered device: CardMaster - IC (08:B6:1F:8E:7A:4E)
D/FlutterBluePlugin(29486): Discovered 68:25:DD:33:8C:0A
I/flutter (29486): Discovered device: CardMaster - Bot (68:25:DD:33:8C:0A)
  */

  int tabIndex = 0;
  List<Widget> tabs = [];

  bool isLoadingModels = true;

  // TfliteModelIsolate yoloModel = TfliteModelIsolate(modelPath: "assets/yolo11s_f32.tflite");
  TfliteModelIsolate yoloModel = TfliteModelIsolate(modelPath: "assets/yolov5nu_f16.tflite");
  OnnxModel oomiModel = OnnxModel(modelPath: "assets/oomi_agent.onnx");

  YoloDetector yoloDetector = YoloDetector();
  OomiPredictor oomiPredictor = OomiPredictor();

  ImageInputHandler imageInputHandlerOuter = ImageInputHandler();
  ImageInputHandler imageInputHandlerInner = ImageInputHandler();
  BotInputHandler botInputHandler = BotInputHandler();

  img.Image? _currentImage;

  GameHandler gameHandler = GameHandler();

  late CamerasViewController camerasViewController;
  late GameViewController gameViewController;
  late TestViewController testViewController;
  late LogsViewController logsViewController;

  void _initializeTabs() {
    camerasViewController = CamerasViewController(
      onNeedUpdateOuterImage: () {
        imageInputHandlerOuter.captureImage();
      },
      onNeedUpdateInnerImage: () async {
        imageInputHandlerInner.captureImage();
        // await oomiPredictor.predict(oomiModel);
      },
    );

    gameViewController = GameViewController(
      onUpdateTrumpSuit: (String suit) {
        gameHandler.trumpSuit = suit;
      },
    );

    testViewController = TestViewController(
      onTestCommand: (String command) {
        botInputHandler.sendString(command);
      },
    );

    logsViewController = LogsViewController();

    tabs = [
      ConnectionsView(inputHandlers: {"Outer Camera": imageInputHandlerOuter, "Inner Camera": imageInputHandlerInner, "Bot": botInputHandler}),
      GameView(controller: gameViewController),
      CamerasView(controller: camerasViewController),
      TestView(controller: testViewController),
      Column(
        children: [Expanded(child: LogsView(controller: logsViewController))],
      ),
    ];
  }

  Future<void> _loadModels() async {
    try {
      await yoloModel.start();
      await oomiModel.loadModel();
      oomiModel.inspectModel();
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

  Future<void> detectCurrentImage() async {
    try {
      await yoloDetector.detectObjects(_currentImage!, yoloModel);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("YOLO detection completed.")));
    } catch (e) {
      print('Error during YOLO detection: $e');
    }
  }

  //=================

  void setCurrentTrump(String suit) {
    gameHandler.trumpSuit = suit;
    updateGameView();
  }

  void updateGameView() {
    gameViewController.stack = gameHandler.stack;
    gameViewController.trumpSuit = gameHandler.trumpSuit;
    gameViewController.update();
  }

  //=================

  @override
  void initState() {
    super.initState();
    _initializeTabs();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModels();
    });

    // Image capture listeners

    imageInputHandlerOuter.listenToOnImageCaptured((int width, int height) async {
      debugPrint("Outer Image Captured: Width: $width, Height: $height");
      _currentImage = imageInputHandlerOuter.image!;
      await detectCurrentImage();
      gameHandler.analyzeOuterCamDetections(yoloDetector.detections!, yoloDetector.processedImage!.width.toDouble(), yoloDetector.processedImage!.height.toDouble());
      //...
      camerasViewController.outerImage = yoloDetector.processedImage;
      camerasViewController.progressOuterImage = 0.0;
      camerasViewController.cardsOnBoard = gameHandler.cardsOnBoard;
      camerasViewController.update();
      //...
      updateGameView();
    });

    imageInputHandlerInner.listenToOnImageCaptured((int width, int height) async {
      debugPrint("Inner Image Captured: Width: $width, Height: $height");
      //==== pad image to 800x800 (240x240 is received, to more accuracy we do this)
      final originalImage = imageInputHandlerInner.image!;
      _currentImage = img.copyExpandCanvas(originalImage, newWidth: 800, newHeight: 800, backgroundColor: img.ColorRgb8(255, 255, 255));
      //============================================================================
      await detectCurrentImage();
      gameHandler.analyzeInnerCamDetections(yoloDetector.detections!);
      //...
      camerasViewController.innerImage = yoloDetector.processedImage;
      camerasViewController.progressInnerImage = 0.0;
      camerasViewController.currentInputCardSymbol = gameHandler.currentInputCardSymbol;
      camerasViewController.update();
      //...
      updateGameView();
    });

    // Image download progress update listeners

    imageInputHandlerOuter.listenToOnProgressUpdate((double progress) {
      camerasViewController.progressOuterImage = progress;
      camerasViewController.update();
    });

    imageInputHandlerInner.listenToOnProgressUpdate((double progress) {
      camerasViewController.progressInnerImage = progress;
      camerasViewController.update();
    });

    // Bot command listener

    botInputHandler.listenToOnLineReceived((String line) {
      debugPrint('Received: $line, ${line.length}');

      // Detect logs (starts with "log -")
      if (line.startsWith("log -")) {
        logsViewController.addLog(line);
        return null;
      }

      switch (line) {
        //======================================
        case "card-in":
          gameHandler.btnCardInPressed = true;
          imageInputHandlerInner.captureImage();
          break;
        case "card-out":
          gameHandler.btnCardOutPressed = true;
          imageInputHandlerOuter.captureImage();
          break;
        //======================================
        case "set-trump-h":
          setCurrentTrump("H");
          break;
        case "set-trump-d":
          setCurrentTrump("D");
          break;
        case "set-trump-c":
          setCurrentTrump("C");
          break;
        case "set-trump-s":
          setCurrentTrump("S");
          break;
        //======================================
        case "Test mode enabled.":
          testViewController.testModeEnabled = true;
          testViewController.update();
          break;
        case "Test mode exit.":
          testViewController.testModeEnabled = false;
          testViewController.update();
          break;
        //======================================
        default:
          debugPrint("Unknown input received: $line");
      }

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
    oomiModel.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Card Master Bot")),
      body: isLoadingModels
          ? Center(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Loading Models...")]),
              ),
            )
          : IndexedStack(index: tabIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[400],
        backgroundColor: Theme.of(context).primaryColor,
        currentIndex: tabIndex,
        onTap: (int index) {
          setState(() {
            tabIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: 'Connections'),
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Game'),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Cameras'),
          BottomNavigationBarItem(icon: Icon(Icons.troubleshoot), label: 'Test'),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'Logs'),
        ],
      ),
    );
  }
}
