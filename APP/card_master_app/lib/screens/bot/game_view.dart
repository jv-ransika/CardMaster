import 'package:card_master/components/card_stack.dart';
import 'package:card_master/components/current_scores.dart';
import 'package:card_master/components/current_trump.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class GameView extends StatefulWidget {
  final GameViewController controller;
  final Function onReset;

  GameView({required this.controller, required this.onReset});

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  @override
  void initState() {
    widget.controller.onUpdate = () {
      setState(() {});
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current scores
            Text("Current Scores", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CurrentScores(ourScore: widget.controller.ourScore, opponentScore: widget.controller.opponentScore),

            const SizedBox(height: 16),

            // Current trump suit
            Text("Current Trump Suit", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: CurrentTrump(trumpSuit: widget.controller.trumpSuit),
            ),

            const SizedBox(height: 24),

            // Card stack section
            Text("Current Stack", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: CardStack(stacks: widget.controller.stack),
            ),

            // Reset button
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirm Reset'),
                    content: Text('Are you sure you want to reset the game?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Reset')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  widget.onReset.call();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Game has been reset successfully!')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Danger button color
                foregroundColor: Colors.white, // Text color
              ),
              child: Text("Reset Game"),
            ),
          ],
        ),
      ),
    );
  }
}

class GameViewController {
  final Function(String) onUpdateTrumpSuit;

  List<String?> stack = [null, null, null, null, null, null, null, null];
  String? trumpSuit;
  int ourScore = 0;
  int opponentScore = 0;

  Function? onUpdate;

  GameViewController({required this.onUpdateTrumpSuit});

  void callUpdateTrumpSuit(String suit) {
    onUpdateTrumpSuit.call(suit);
  }

  void update() {
    onUpdate?.call();
  }
}
