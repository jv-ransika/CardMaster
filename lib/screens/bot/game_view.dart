import 'package:card_master/components/card_stack.dart';
import 'package:card_master/components/trump_selector.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class GameView extends StatefulWidget {
  final GameViewController controller;

  GameView({required this.controller});

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
            // Trump suit selector section
            Text("Select Trump Suit", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TrumpSelector(
                onSuitSelected: (suit) {
                  // TODO: Handle suit selection
                },
              ),
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
              child: CardStack(stacks: widget.controller.currentStack),
            ),
          ],
        ),
      ),
    );
  }
}

class GameViewController {
  final Function(String) onUpdateTrumpSuit;

  List<String?> currentStack = [null, null, null, null, null, null, null, null];

  Function? onUpdate;

  GameViewController({required this.onUpdateTrumpSuit});

  void callUpdateTrumpSuit(String suit) {
    onUpdateTrumpSuit.call(suit);
  }

  void update() {
    onUpdate?.call();
  }
}
