import 'package:flutter/material.dart';

class CurrentTrump extends StatelessWidget {
  final String? trumpSuit; // nullable now
  final double size;

  const CurrentTrump({this.trumpSuit, this.size = 56.0});

  static const Map<String, String> suitSymbols = {'H': '♥', 'D': '♦', 'C': '♣', 'S': '♠'};

  static const Map<String, Color> suitColors = {'H': Colors.red, 'D': Colors.red, 'C': Colors.black, 'S': Colors.black};

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: suitSymbols.keys.map((suit) {
        final bool isSelected = trumpSuit != null && trumpSuit == suit;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(size * 0.18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? suitColors[suit]!.withOpacity(0.9) : Colors.transparent,
            border: isSelected ? Border.all(color: Colors.yellow, width: 3) : null,
            boxShadow: isSelected ? [BoxShadow(color: Colors.yellow.withOpacity(0.6), blurRadius: 8)] : null,
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
