import 'dart:math';
import 'package:flutter/material.dart';

class GameView extends StatelessWidget {
  final List<String?> cardsOnHand; // length 8
  final Map<String, String?> cardsOnDesk; // {"me":..., "infront":..., "left":..., "right":...}
  final String? trumpSuit;
  final Function(String) onCardClick;
  final int ourScore;
  final int opponentScore;
  final String? currentState;
  final List<String> specialGameStates;
  final bool roundOver;

  const GameView({Key? key, required this.cardsOnHand, required this.cardsOnDesk, required this.trumpSuit, required this.onCardClick, required this.ourScore, required this.opponentScore, this.currentState, this.specialGameStates = const [], this.roundOver = false}) : assert(cardsOnHand.length == 8, 'cardsOnHand must be 8 elements'), super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSpecialState = currentState != null && specialGameStates.contains(currentState);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: screenSize.width,
            height: screenSize.height,
            color: Colors.green[900],
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Current Trump Suit
                CurrentTrump(trumpSuit: trumpSuit, size: 30),
                const SizedBox(height: 8),

                // Omi Board
                Expanded(
                  child: Center(
                    child: OmiBoard(me: cardsOnDesk["me"], infront: cardsOnDesk["infront"], left: cardsOnDesk["left"], right: cardsOnDesk["right"]),
                  ),
                ),
                const SizedBox(height: 8),

                // Scores
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScoreCard(label: 'Us', score: ourScore),
                    const SizedBox(width: 24),
                    ScoreCard(label: 'Opp', score: opponentScore),
                  ],
                ),
                const SizedBox(height: 16),

                // Current Game State
                if (currentState != null) SpecialStateText(text: currentState!, isSpecial: isSpecialState),

                const SizedBox(height: 16),

                // Cards On Hand
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cardsOnHand.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final card = cardsOnHand[index];
                      return GestureDetector(
                        onTap: card != null ? () => onCardClick(card) : null,
                        child: Container(
                          width: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.yellowAccent, width: 2),
                            color: Colors.grey.shade300,
                            boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 3)],
                          ),
                          child: card != null
                              ? Image.asset('assets/images/cards/${card.toUpperCase()}.png', fit: BoxFit.cover)
                              : const Center(
                                  child: Text('—', style: TextStyle(fontSize: 20, color: Colors.black54)),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Round Over Overlay
          if (roundOver)
            Positioned.fill(
              child: Container(
                color: Colors.black87.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Round is Over!',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellowAccent,
                          shadows: [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScoreCard(label: 'You', score: ourScore),
                          const SizedBox(width: 24),
                          ScoreCard(label: 'Opponent', score: opponentScore),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ---------------------- Local Components ----------------------

class CurrentTrump extends StatelessWidget {
  final String? trumpSuit; // nullable
  final double size;

  const CurrentTrump({Key? key, this.trumpSuit, this.size = 56.0}) : super(key: key);

  static const Map<String, String> suitSymbols = {'H': '♥', 'D': '♦', 'C': '♣', 'S': '♠'};
  static const Map<String, Color> suitColors = {'H': Colors.yellow, 'D': Colors.red, 'C': Colors.black, 'S': Colors.black};

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: suitSymbols.keys.map((suit) {
        final bool isSelected = trumpSuit != null && trumpSuit == suit;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: EdgeInsets.all(size * 0.15),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? suitColors[suit]!.withOpacity(0.9) : Colors.transparent,
            border: isSelected ? Border.all(color: Colors.yellow, width: 3) : null,
            boxShadow: isSelected ? [BoxShadow(color: Colors.yellow.withOpacity(0.6), blurRadius: 6)] : null,
          ),
          child: Text(
            suitSymbols[suit]!,
            style: TextStyle(color: isSelected ? Colors.white : suitColors[suit], fontWeight: FontWeight.bold, fontSize: isSelected ? size * 0.5 : size * 0.4),
          ),
        );
      }).toList(),
    );
  }
}

class OmiBoard extends StatefulWidget {
  final String? me;
  final String? infront;
  final String? left;
  final String? right;

  const OmiBoard({Key? key, this.me, this.infront, this.left, this.right}) : super(key: key);

  @override
  State<OmiBoard> createState() => _OmiBoardState();
}

class _OmiBoardState extends State<OmiBoard> {
  static const double cardWidth = 60;
  static const double cardHeight = 90;
  static const double boardSize = 320;

  double randomRotationOffset(Random random) {
    return (random.nextDouble() * 0.1745) - 0.08725;
  }

  Widget buildCard(String? cardName, double baseRotation, Random random) {
    final rotation = baseRotation + randomRotationOffset(random);
    return cardName != null
        ? Transform.rotate(
            angle: rotation,
            child: Container(
              decoration: const BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 3))],
              ),
              child: Image.asset('assets/images/cards/$cardName.png', width: cardWidth, height: cardHeight, fit: BoxFit.cover),
            ),
          )
        : Container(
            width: cardWidth,
            height: cardHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 2))],
            ),
            child: const Text(
              'No Card',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final random = Random();

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.brown[900]!, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 15, left: boardSize / 2 - cardWidth / 2, child: buildCard(widget.infront, pi, random)),
          Positioned(left: 30, top: boardSize / 2 - cardHeight / 2, child: buildCard(widget.left, -pi / 2, random)),
          Positioned(bottom: 15, left: boardSize / 2 - cardWidth / 2, child: buildCard(widget.me, 0, random)),
          Positioned(right: 30, top: boardSize / 2 - cardHeight / 2, child: buildCard(widget.right, pi / 2, random)),
        ],
      ),
    );
  }
}

/// ---------------------- Local Components ----------------------

class SpecialStateText extends StatefulWidget {
  final String text;
  final bool isSpecial;

  const SpecialStateText({Key? key, required this.text, this.isSpecial = false}) : super(key: key);

  @override
  State<SpecialStateText> createState() => _SpecialStateTextState();
}

class _SpecialStateTextState extends State<SpecialStateText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));

    // Scale pulses from 1.0 → 1.2 → 1.0
    _scaleAnim = TweenSequence<double>([TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)), weight: 50), TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50)]).animate(_controller);

    // Opacity pulses
    _opacityAnim = TweenSequence<double>([TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.0), weight: 50), TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 50)]).animate(_controller);

    // Glow color shift
    _colorAnim = ColorTween(begin: Colors.yellowAccent, end: Colors.white).animate(_controller);

    if (widget.isSpecial) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SpecialStateText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpecial && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isSpecial && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isSpecial ? _scaleAnim.value : 1.0,
          child: Opacity(
            opacity: widget.isSpecial ? _opacityAnim.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.isSpecial ? [BoxShadow(color: _colorAnim.value!.withOpacity(0.8), blurRadius: 12, offset: const Offset(0, 0)), BoxShadow(color: _colorAnim.value!.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 0))] : null,
              ),
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellowAccent,
                  letterSpacing: 1.2,
                  shadows: [Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ScoreCard extends StatelessWidget {
  final String label;
  final int score;

  const ScoreCard({Key? key, required this.label, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.yellow, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            score.toString(),
            style: const TextStyle(
              color: Colors.yellowAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }
}
