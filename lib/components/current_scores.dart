import 'package:flutter/material.dart';

class CurrentScores extends StatelessWidget {
  final int ourScore;
  final int opponentScore;
  final double size;

  const CurrentScores({Key? key, required this.ourScore, required this.opponentScore, this.size = 46.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildScoreBox("Us", ourScore, Colors.blue),
        SizedBox(width: size * 0.4),
        _buildScoreBox("Opp", opponentScore, Colors.red),
      ],
    );
  }

  Widget _buildScoreBox(String label, int score, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.4, vertical: size * 0.2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: Colors.yellow, width: 3),
        boxShadow: [BoxShadow(color: Colors.yellow.withOpacity(0.6), blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: size * 0.25),
          ),
          Text(
            score.toString(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.5),
          ),
        ],
      ),
    );
  }
}
