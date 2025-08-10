import 'package:flutter/material.dart';

class TrumpSelector extends StatefulWidget {
  final Function(String) onSuitSelected;
  final String? initialSuit;

  const TrumpSelector({Key? key, required this.onSuitSelected, this.initialSuit}) : super(key: key);

  @override
  State<TrumpSelector> createState() => _TrumpSelectorState();
}

class _TrumpSelectorState extends State<TrumpSelector> {
  late String? _selectedSuit;

  final Map<String, String> suitSymbols = {'H': '♥', 'D': '♦', 'C': '♣', 'S': '♠'};

  final Map<String, Color> suitColors = {'H': Colors.green[700]!, 'D': Colors.green[700]!, 'C': Colors.green[700]!, 'S': Colors.green[700]!};

  @override
  void initState() {
    super.initState();
    _selectedSuit = widget.initialSuit;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: suitSymbols.keys.map((suit) {
        return _buildSuitButton(suit);
      }).toList(),
    );
  }

  Widget _buildSuitButton(String suit) {
    bool isSelected = _selectedSuit == suit;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSuit = suit);
        widget.onSuitSelected(suit);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: suitColors[suit]!.withOpacity(isSelected ? 0.9 : 0.7),
          border: isSelected ? Border.all(color: Colors.yellow, width: 3) : null,
          boxShadow: isSelected ? [BoxShadow(color: Colors.yellow.withOpacity(0.6), blurRadius: 8)] : [],
        ),
        child: Text(
          suitSymbols[suit]!,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSelected ? 28 : 22),
        ),
      ),
    );
  }
}
