import 'package:flutter/material.dart';

class CardStack extends StatelessWidget {
  final List<String?> stacks; // length should be 8

  const CardStack({Key? key, required this.stacks}) : assert(stacks.length == 8, 'CardStack requires exactly 8 stacks'), super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(8, (index) {
        int stackNumber = index + 1; // 1 to 8
        String? cardLabel = stacks[index];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Stack number
              SizedBox(
                width: 24,
                child: Text(
                  stackNumber.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: 8),

              // Card image (rotated) or placeholder
              Container(
                width: 90, // Landscape width
                height: 60, // Landscape height
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade400),
                  color: Colors.grey.shade200,
                ),
                child: cardLabel != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: RotatedBox(
                          quarterTurns: 1, // 90-degree rotation
                          child: Image.asset('assets/images/cards/${cardLabel.toUpperCase()}.png', fit: BoxFit.cover),
                        ),
                      )
                    : const Center(
                        child: Text('—', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
