import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class OmiBoard extends StatefulWidget {
  final String? me;
  final String? infront;
  final String? left;
  final String? right;
  final img.Image? capturedImage;
  final double progress;

  const OmiBoard({super.key, this.me, this.infront, this.left, this.right, this.capturedImage, this.progress = 0.0});

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
              decoration: BoxDecoration(
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
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 2))],
            ),
            child: const Text(
              'No Card',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
            ),
          );
  }

  Uint8List? getCapturedImageBytes() {
    if (widget.capturedImage == null) return null;
    return Uint8List.fromList(img.encodePng(widget.capturedImage!));
  }

  @override
  Widget build(BuildContext context) {
    final random = Random();

    // Clamp progress between 0 and 1
    final progress = widget.progress.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Show Board'),
              Switch(
                value: showBoard,
                onChanged: (val) {
                  setState(() {
                    showBoard = val;
                  });
                },
              ),
              const Text('Show Image'),
            ],
          ),
        ),

        Stack(
          children: [
            Container(
              width: boardSize,
              height: boardSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.brown[900]!, width: 5),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 6))],
              ),
              child: showBoard
                  ? Container(
                      decoration: BoxDecoration(color: Colors.green[800], borderRadius: BorderRadius.circular(16)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(top: 15, left: boardSize / 2 - cardWidth / 2, child: buildCard(widget.infront, 3.1416, random)),
                          Positioned(left: 45, top: boardSize / 2 - cardHeight / 2, child: buildCard(widget.left, -3.1416 / 2, random)),
                          Positioned(bottom: 15, left: boardSize / 2 - cardWidth / 2, child: buildCard(widget.me, 0, random)),
                          Positioned(right: 45, top: boardSize / 2 - cardHeight / 2, child: buildCard(widget.right, 3.1416 / 2, random)),
                        ],
                      ),
                    )
                  : Builder(
                      builder: (_) {
                        final bytes = getCapturedImageBytes();
                        if (bytes == null) {
                          return const Center(child: Text('No Image Captured'));
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(bytes, width: boardSize, height: boardSize, fit: BoxFit.cover),
                        );
                      },
                    ),
            ),

            // Progress overlay only if progress > 0
            if (progress > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: boardSize * progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        shadows: [Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 3)],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  bool showBoard = true; // moved here to keep track of toggle state
}
