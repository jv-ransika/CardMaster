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

  late _GameState _gameState;

  void showTrumpSuitSelection() {
    final suits = {
      'H': {'name': 'Hearts', 'symbol': '♥', 'color': Colors.red},
      'D': {'name': 'Diamonds', 'symbol': '♦', 'color': Colors.red},
      'C': {'name': 'Clubs', 'symbol': '♣', 'color': Colors.black},
      'S': {'name': 'Spades', 'symbol': '♠', 'color': Colors.black},
    };

    showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Text("Select Trump Suit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: suits.entries.map((entry) {
                final code = entry.key;
                final data = entry.value;
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: Text(
                      data['symbol'] as String,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: data['color'] as Color),
                    ),
                    title: Text(data['name'] as String, style: const TextStyle(fontSize: 18)),
                    onTap: () {
                      Navigator.of(context).pop(code);
                      remotePlayHandler.sendMessage(jsonEncode({"type": "trump_suit", "data": code}));
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _gameState = _GameState(
      onTrumpSuitRequest: () {
        showTrumpSuitSelection();
      },
    );

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

    if (!remotePlayHandler.connecting && remotePlayHandler.channel == null) {
      body = const _StatusView(title: "Disconnected", subtitle: "Please try again", showLoader: false);
    } else if (remotePlayHandler.connecting) {
      body = const _StatusView(title: "Connecting to server...", subtitle: "Please wait", showLoader: true);
    } else if (!remotePlayHandler.paired && !joining) {
      body = _CodeInputView(
        controller: _codeController,
        onPairPressed: () {
          final code = _codeController.text.trim();
          if (code.length != 6) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid 6-digit code")));
            return;
          }
          setState(() => joining = true);
          remotePlayHandler.joinGame(code);
        },
      );
    } else if (joining && !remotePlayHandler.paired) {
      body = const _StatusView(title: "Pairing with host...", subtitle: "Please wait", showLoader: true);
    } else if (remotePlayHandler.paired) {
      body = GameView(
        cardsOnHand: _gameState.cardsOnHand,
        cardsOnDesk: _gameState.cardsOnDesk,
        trumpSuit: _gameState.trumpSuit,
        ourScore: _gameState.ourScore,
        opponentScore: _gameState.opponentScore,
        currentState: _gameState.currentState,
        roundOver: _gameState.roundOver,
        specialGameStates: ["Your Turn", "Say Trump Suit"],
        onCardClick: (card) {
          if (_gameState.currentState != "Your Turn") {
            remotePlayHandler.sendMessage(jsonEncode({"type": "selected_card", "data": card}));
          }
        },
      );
    } else {
      body = const _StatusView(title: "Disconnected", subtitle: "Please try again", showLoader: false);
    }

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

  final Function onTrumpSuitRequest;

  _GameState({required this.onTrumpSuitRequest});

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
          if (currentState == "Say Trump Suit") {
            onTrumpSuitRequest();
          }
          break;
        case 'roundOver':
          roundOver = entry.value;
          break;
      }
    }
  }
}
