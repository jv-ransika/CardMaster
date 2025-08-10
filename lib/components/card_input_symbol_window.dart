import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CardInputSymbolWindow extends StatefulWidget {
  final String? symbol;
  final img.Image? capturedImage;
  final double progress; // 0 to 1

  const CardInputSymbolWindow({super.key, required this.symbol, this.capturedImage, this.progress = 0.0});

  @override
  State<CardInputSymbolWindow> createState() => _CardInputSymbolWindowState();
}

class _CardInputSymbolWindowState extends State<CardInputSymbolWindow> {
  bool showCard = true;

  static const double cardWidth = 60;
  static const double cardHeight = 90;
  static const double windowWidth = 320;
  static const double windowHeight = 180;

  Uint8List? getCapturedImageBytes() {
    if (widget.capturedImage == null) return null;
    return Uint8List.fromList(img.encodePng(widget.capturedImage!));
  }

  Widget buildCardImage(String? symbol) {
    return symbol != null && symbol.isNotEmpty
        ? Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 3))],
            ),
            child: Image.asset('assets/images/cards/$symbol.png', fit: BoxFit.cover),
          )
        : Container(
            width: cardWidth,
            height: cardHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6)),
            child: const Text(
              'No Card',
              style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final capturedBytes = getCapturedImageBytes();

    final progress = widget.progress.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle Switch
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Show Image'),
              const SizedBox(width: 8),
              Switch(
                value: !showCard,
                onChanged: (val) {
                  setState(() {
                    showCard = !val;
                  });
                },
              ),
            ],
          ),
        ),

        Stack(
          children: [
            Container(
              width: windowWidth,
              height: windowHeight,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[400]!),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 4))],
              ),
              child: Center(
                child: showCard
                    ? buildCardImage(widget.symbol)
                    : (capturedBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(capturedBytes, width: double.infinity, height: double.infinity, fit: BoxFit.contain),
                            )
                          : const Text(
                              'No Image Captured',
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            )),
              ),
            ),

            // Progress overlay if progress > 0
            if (progress > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: windowHeight * progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
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
}
