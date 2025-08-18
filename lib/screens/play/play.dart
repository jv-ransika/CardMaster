import 'dart:convert';

import 'package:card_master/handlers/remote_play_handler/remote_play_handler.dart';
import 'package:card_master/screens/play/game_view.dart';
import 'package:flutter/material.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({Key? key}) : super(key: key);

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late RemotePlayHandler remotePlayHandler;
  final TextEditingController _codeController = TextEditingController();
  bool joining = false; // waiting for host confirmation

  final _GameState _gameState = _GameState();

  @override
  void initState() {
    super.initState();
    remotePlayHandler = RemotePlayHandler(
      onConnected: () => setState(() {}),
      onCodeReceived: (_) {}, // not needed on client
      onPaired: () {
        setState(() {
          joining = false;
        });
        debugPrint("Remote Play Paired");
      },
      onMessageReceived: (message) {
        debugPrint("Remote Play Message: $message");
        _gameState.handleMessage(message);
        setState(() {});
      },
      onPairLost: () => setState(() {}),
      onErrorReceived: (msg) {
        setState(() {
          joining = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
      onDisconnected: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      },
    );

    remotePlayHandler.connectAndHost(); // connect to server
  }

  @override
  void dispose() {
    remotePlayHandler.disconnect();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    // if (!remotePlayHandler.connecting && remotePlayHandler.channel == null) {
    //   body = const _StatusView(title: "Disconnected", subtitle: "Please try again", showLoader: false);
    // } else if (remotePlayHandler.connecting) {
    //   body = const _StatusView(title: "Connecting to server...", subtitle: "Please wait", showLoader: true);
    // } else if (!remotePlayHandler.paired && !joining) {
    //   body = _CodeInputView(
    //     controller: _codeController,
    //     onPairPressed: () {
    //       final code = _codeController.text.trim();
    //       if (code.length != 6) {
    //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid 6-digit code")));
    //         return;
    //       }
    //       setState(() => joining = true);
    //       remotePlayHandler.joinGame(code);
    //     },
    //   );
    // } else if (joining && !remotePlayHandler.paired) {
    //   body = const _StatusView(title: "Pairing with host...", subtitle: "Please wait", showLoader: true);
    // } else if (remotePlayHandler.paired) {
    //   body = const Center(
    //     child: Text("Implement here...", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    //   );
    // } else {
    //   body = const _StatusView(title: "Disconnected", subtitle: "Please try again", showLoader: false);
    // }

    body = GameView(
      cardsOnHand: ["7D", null, null, null, null, null, null, null],
      cardsOnDesk: {"me": "5H", "infront": "9C", "left": "3D", "right": "7S"},
      trumpSuit: "H",
      ourScore: 2,
      opponentScore: 3,
      currentState: "Your Turn",
      roundOver: false,
      specialGameStates: ["Your Turn"],
      onCardClick: (card) {
        debugPrint("Card clicked: $card");
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Show confirmation dialog
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Exit Game"),
            content: const Text("Are you sure you want to leave the game?"),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Yes")),
            ],
          ),
        );

        if (shouldExit == true) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: body),
        ),
      ),
    );
  }
}

/// Status view with optional loader
class _StatusView extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showLoader;

  const _StatusView({required this.title, required this.subtitle, this.showLoader = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLoader) const CircularProgressIndicator(),
            if (showLoader) const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Input for host code
class _CodeInputView extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPairPressed;

  const _CodeInputView({required this.controller, required this.onPairPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enter Game Code", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "6-digit code", counterText: ""),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 6),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPairPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Play", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameState {
  List<String?> cardsOnHand = [null, null, null, null, null, null, null, null];
  Map<String, String?> cardsOnDesk = {"me": null, "infront": null, "left": null, "right": null};
  String? trumpSuit;
  int ourScore = 0;
  int opponentScore = 0;
  String currentState = "Waiting";
  bool roundOver = false;

  void handleMessage(String message) {
    final json = jsonDecode(message);
    if (json['type'] == 'game_state') {
      _updateGameState(json['data']);
    }
  }

  void _updateGameState(Map<String, dynamic> data) {
    for (MapEntry<String, dynamic> entry in data.entries) {
      switch (entry.key) {
        case 'cardsOnHand':
          cardsOnHand = List<String?>.from(entry.value);
          break;
        case 'cardsOnDesk':
          cardsOnDesk = Map<String, String?>.from(entry.value);
          break;
        case 'trumpSuit':
          trumpSuit = entry.value;
          break;
        case 'ourScore':
          ourScore = entry.value;
          break;
        case 'opponentScore':
          opponentScore = entry.value;
          break;
        case 'currentState':
          currentState = entry.value;
          break;
        case 'roundOver':
          roundOver = entry.value;
          break;
      }
    }
  }
}
