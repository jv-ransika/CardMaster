import 'dart:async';
import 'dart:convert';
import 'package:card_master/components/remote_play_status.dart';
import 'package:card_master/handlers/conn_input_handler/bot_handler.dart';
import 'package:card_master/handlers/conn_input_handler/image_handler.dart';
import 'package:card_master/handlers/game_handler/game_handler.dart';
import 'package:card_master/handlers/remote_play_handler/remote_play_handler.dart';
import 'package:card_master/onnx/onnx_model.dart';
import 'package:card_master/onnx/oomi_predictor.dart';
import 'package:card_master/screens/bot/cameras_view.dart';
import 'package:card_master/screens/bot/connections_view.dart';
import 'package:card_master/screens/bot/game_view.dart';
import 'package:card_master/screens/bot/logs_view.dart';
import 'package:card_master/screens/bot/test_view.dart';
import 'package:card_master/screens/qr_scan/qr_scan.dart';
import 'package:card_master/tflite/tflite_model_isolate.dart';
import 'package:card_master/tflite/yolo_detector.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool isLoadingAddresses = true;

  TfliteModelIsolate yoloModel = TfliteModelIsolate(modelPath: "assets/yolo11s_f32.tflite");
  // TfliteModelIsolate yoloModel = TfliteModelIsolate(modelPath: "assets/yolov5nu_f16.tflite");
  OnnxModel oomiModel = OnnxModel(modelPath: "assets/oomi_agent.onnx");

  List<String>? deviceAddresses = [];

  YoloDetector yoloDetector = YoloDetector();
  OomiPredictor oomiPredictor = OomiPredictor();

  ImageInputHandler imageInputHandlerOuter = ImageInputHandler();
  ImageInputHandler imageInputHandlerInner = ImageInputHandler();
  BotInputHandler botInputHandler = BotInputHandler();

  img.Image? _currentImage;

  late GameHandler gameHandler;

  late ConnectionsViewController connectionsViewController;
  late CamerasViewController camerasViewController;
  late GameViewController gameViewController;
  late TestViewController testViewController;
  late LogsViewController logsViewController;
  late RemotePlayHandler remotePlayHandler;

  Completer<String>? _remoteResponseCompleter;
  bool remoteMode = false;

  void _initializeTabs() {
    connectionsViewController = ConnectionsViewController();

    camerasViewController = CamerasViewController(
      onNeedUpdateOuterImage: () {
        imageInputHandlerOuter.captureImage();
      },
      onNeedUpdateInnerImage: () async {
        imageInputHandlerInner.captureImage();
      },
      onCalibrateCenterClick: () {
        if (yoloDetector.detections == null || yoloDetector.detections!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No detections available to calibrate center.")));
          return;
        }
        // Calculate the center of the detected cards
        gameHandler.calcLocalBoardCenter(yoloDetector.detections!);
        // Draw calibration markers on the image
        if (yoloDetector.processedImage != null) {
          img.drawCircle(yoloDetector.processedImage!, x: gameHandler.boardCenter.dx.toInt(), y: gameHandler.boardCenter.dy.toInt(), radius: 10, color: img.ColorRgb8(255, 0, 0));
          camerasViewController.outerImage = yoloDetector.processedImage!;
          camerasViewController.update();
        }
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
    logsViewController.onSendText = (String text) {
      debugPrint("Sending text: $text");
      botInputHandler.sendString(text);
    };

    tabs = [
      ConnectionsView(
        controller: connectionsViewController,
        inputHandlers: {"Outer Camera": imageInputHandlerOuter, "Inner Camera": imageInputHandlerInner, "Bot": botInputHandler},
        onAddressesClearClicked: () async {
          await _clearCurrentDeviceAddresses();
          setState(() {});
        },
      ),
      GameView(
        controller: gameViewController,
        onReset: () {
          gameHandler.reset();
          updateGameView();
        },
      ),
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

  Future<void> _loadDeviceAddresses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    deviceAddresses = prefs.getStringList('addresses');
    if (deviceAddresses != null) {
      updateConnectionsView();
    }
    isLoadingAddresses = false;
    setState(() {});
  }

  Future<void> _clearCurrentDeviceAddresses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('addresses');
    deviceAddresses = null;
  }

  Future<void> _saveDeviceAddresses() async {
    if (deviceAddresses == null) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('addresses', deviceAddresses!);
  }

  Future<void> _detectCurrentImage() async {
    try {
      await yoloDetector.detectObjects(_currentImage!, yoloModel);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("YOLO detection completed.")));
    } catch (e) {
      print('Error during YOLO detection: $e');
    }
  }

  //=================

  void _updateRemote(String currentState) {
    if (!remoteMode) return;
    debugPrint("Updating remote with current state: $currentState");

    // Build json
    Map<String, dynamic> jsonData = {
      'type': 'game_state',
      'data': {'trumpSuit': gameHandler.trumpSuit, 'cardsOnHand': gameHandler.stack, 'cardsOnDesk': gameHandler.cardsOnDesk, 'ourScore': gameHandler.ourScore, 'opponentScore': gameHandler.opponentScore, 'roundOver': gameHandler.currentState == GameState.roundOver, 'currentState': currentState},
    };

    remotePlayHandler.sendMessage(jsonEncode(jsonData));
  }

  void _handleRemoteMessage(String message) {
    final json = jsonDecode(message);

    String? result;

    if (json['type'] == 'selected_card') {
      result = json['data'];
      debugPrint("Remote player selected card: $result");
    } else if (json['type'] == 'trump_suit') {
      result = json['data'];
      debugPrint("Remote player said trump suit: $result");
    }

    if (result != null && _remoteResponseCompleter != null) {
      _remoteResponseCompleter!.complete(result);
      _remoteResponseCompleter = null;
    }
  }

  //=================

  void setCurrentTrump(String? suit) {
    gameHandler.trumpSuit = suit;
    _updateRemote("Trump Suit Updated");
    updateGameView();
  }

  void updateGameView() {
    gameViewController.stack = gameHandler.stack;
    gameViewController.trumpSuit = gameHandler.trumpSuit;
    gameViewController.ourScore = gameHandler.ourScore;
    gameViewController.opponentScore = gameHandler.opponentScore;
    gameViewController.update();
  }

  void updateConnectionsView() {
    connectionsViewController.deviceAddresses["Bot"] = deviceAddresses![0];
    connectionsViewController.deviceAddresses["Inner Camera"] = deviceAddresses![1];
    connectionsViewController.deviceAddresses["Outer Camera"] = deviceAddresses![2];
    connectionsViewController.update();
  }

  //=================

  @override
  void initState() {
    super.initState();
    _initializeTabs();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeviceAddresses();
      _loadModels();
    });

    // GameHandler
    gameHandler = GameHandler(
      onCardInserted: () {
        debugPrint("Card inserted");
        _updateRemote("New Card");
        updateGameView();
      },
      onGameStarted: () {
        debugPrint("Game Started");
        _updateRemote("Game Started");
        updateGameView();
      },
      onSayTrumpSuit: () async {
        if (!remoteMode) {
          String? trump = gameHandler.getTrumpSuit();
          debugPrint("Trump Suit: ${gameHandler.trumpSuit}");
          _updateRemote("Trump Suit Updated");
          updateGameView();
          return trump;
        } else {
          debugPrint("Requesting card from remote player...");
          _remoteResponseCompleter = Completer<String>();
          _updateRemote("Say Trump Suit");
          String suit = await _remoteResponseCompleter!.future;
          setCurrentTrump(suit);
          return suit;
        }
      },
      onScoreUpdate: () {
        debugPrint("Score Updated");
        if (gameHandler.ourWinState == "w") {
          _updateRemote("We Won!");
        } else if (gameHandler.ourWinState == "l") {
          _updateRemote("We Lost!");
        } else {
          _updateRemote("Score Updated");
        }
        updateGameView();
      },
      onCardThrow: () {
        debugPrint("Card thrown");
        _updateRemote("Great throw!");
        updateGameView();
      },
      onActionResponse: (String response) {
        debugPrint("Action Response: $response");
        botInputHandler.sendString(response);
      },
      onGetPredictedCard: (Int64List trumpSuitData, Int64List handData, Int64List deskData, Int64List playedData, List<bool> validActionsData) async {
        if (!remoteMode) {
          debugPrint("Getting predicted card...");
          return await oomiPredictor.predict(trumpSuitData, handData, deskData, playedData, validActionsData, oomiModel);
        } else {
          debugPrint("Requesting card from remote player...");
          _remoteResponseCompleter = Completer<String>();
          _updateRemote("Your Turn");
          String card = await _remoteResponseCompleter!.future;
          return gameHandler.getCardIndex(card);
        }
      },
      onRoundOver: () {
        debugPrint("Round Over");
        updateGameView();
      },
    );

    // Remote Play Handler
    remotePlayHandler = RemotePlayHandler(
      onConnected: () {
        remoteMode = true;
        setState(() {});
        debugPrint("Connected to Remote Play");
      },
      onCodeReceived: (code) {
        setState(() {});
        debugPrint("Remote Play Code Received: $code");
      },
      onPaired: () {
        _updateRemote("Welcome!");
        setState(() {});
        debugPrint("Remote Play Paired");
      },
      onMessageReceived: (message) {
        _handleRemoteMessage(message);
        setState(() {});
        debugPrint("Remote Play Message Received: $message");
      },
      onPairLost: () {
        setState(() {});
        debugPrint("Remote Play Unpaired");
      },
      onErrorReceived: (msg) {
        setState(() {});
        debugPrint("Remote Play Error: $msg");
      },
      onDisconnected: () {
        remoteMode = false;
        setState(() {});
        debugPrint("Disconnected from Remote Play");
      },
    );

    // Image capture listeners

    imageInputHandlerOuter.listenToOnImageCaptured((int width, int height) async {
      debugPrint("Outer Image Captured: Width: $width, Height: $height");
      _currentImage = imageInputHandlerOuter.image!;
      // Rotate 180 degrees
      _currentImage = img.copyRotate(_currentImage!, angle: 180);
      await _detectCurrentImage();
      gameHandler.analyzeOuterCamDetections(yoloDetector.detections!);
      //...
      camerasViewController.outerImage = yoloDetector.processedImage;
      camerasViewController.progressOuterImage = 0.0;
      camerasViewController.cardsOnBoard = gameHandler.cardsOnDesk;
      camerasViewController.update();
      //...
      updateGameView();
    });

    imageInputHandlerInner.listenToOnImageCaptured((int width, int height) async {
      debugPrint("Inner Image Captured: Width: $width, Height: $height");
      //==== pad image to 1200x1200 (240x240 is received, to more accuracy we do this)
      final originalImage = imageInputHandlerInner.image!;
      _currentImage = img.copyExpandCanvas(originalImage, newWidth: 1200, newHeight: 1200, backgroundColor: img.ColorRgb8(255, 255, 255));
      //============================================================================
      await _detectCurrentImage();
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

    imageInputHandlerOuter.listenToOnError(() {
      debugPrint("Outer Image Error");
      camerasViewController.progressOuterImage = 0.0;
      camerasViewController.update();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Outer Image Error")));
    });

    imageInputHandlerInner.listenToOnError(() {
      debugPrint("Inner Image Error");
      camerasViewController.progressInnerImage = 0.0;
      camerasViewController.update();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Inner Image Error")));
    });

    // Bot command listener

    botInputHandler.listenToOnLineReceived((String line) {
      debugPrint('Received: $line, ${line.length}');

      // Detect logs (starts with "log -")
      if (line.startsWith("log -")) {
        logsViewController.addLog(line.substring(6), LogType.received);
        return null;
      }

      switch (line) {
        //======================================
        case "cmd-cardAv":
          gameHandler.triggerBotAction(BotAction.btnInPressed);
          if (gameHandler.cameraCaptureRequired) {
            Future.delayed(Duration(milliseconds: 2000), () {
              imageInputHandlerInner.captureImage();
            });
          }
          break;
        case "cmd-main":
          gameHandler.triggerBotAction(BotAction.btnMainPressed);
          if (gameHandler.cameraCaptureRequired) {
            Future.delayed(Duration(milliseconds: 2000), () {
              imageInputHandlerOuter.captureImage();
            });
          }
          break;
        //======================================
        case "cmd-H":
          setCurrentTrump("H");
          break;
        case "cmd-D":
          setCurrentTrump("D");
          break;
        case "cmd-C":
          setCurrentTrump("C");
          break;
        case "cmd-S":
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
      debugPrint("Bot connected");
      botInputHandler.sendString("cmd-hi");
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
      appBar: AppBar(
        title: const Text("Card Master"),
        actions: [
          RemotePlayStatusWidget(handler: remotePlayHandler), // pass your handler here
        ],
      ),
      body: isLoadingModels || isLoadingAddresses
          ? Center(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Loading Models...")]),
              ),
            )
          : deviceAddresses == null
          ? QRScanScreen(
              onPairingComplete: (macAddresses) async {
                deviceAddresses = macAddresses;
                updateConnectionsView();
                await _saveDeviceAddresses();
                setState(() {});
              },
            )
          : Column(
              children: [
                Container(
                  color: remoteMode ? Colors.yellow : Colors.green,
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(remoteMode ? Icons.info : Icons.smart_toy, color: Colors.black, size: 16),
                      SizedBox(width: 8),
                      Text(
                        remoteMode ? "Remote Mode Enabled" : "AI Mode Enabled",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // ElevatedButton(
                //   onPressed: () {
                //     _updateRemote("Say Trump Suit");
                //   },
                //   child: const Text("Send Message"),
                // ),
                Expanded(
                  child: IndexedStack(index: tabIndex, children: tabs),
                ),
              ],
            ),
      bottomNavigationBar: deviceAddresses == null
          ? null
          : BottomNavigationBar(
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
