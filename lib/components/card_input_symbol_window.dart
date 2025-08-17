// import 'dart:typed_data';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;

// class CardInputSymbolWindow extends StatefulWidget {
//   final String? symbol;
//   final img.Image? capturedImage;
//   final double progress; // 0 to 1

//   const CardInputSymbolWindow({super.key, required this.symbol, this.capturedImage, this.progress = 0.0});

//   @override
//   State<CardInputSymbolWindow> createState() => _CardInputSymbolWindowState();
// }

// class _CardInputSymbolWindowState extends State<CardInputSymbolWindow> {
//   bool showCard = true;

//   static const double cardWidth = 60;
//   static const double cardHeight = 90;
//   static const double windowWidth = 320;
//   static const double windowHeight = 180;

//   Uint8List? getCapturedImageBytes() {
//     if (widget.capturedImage == null) return null;
//     return Uint8List.fromList(img.encodePng(widget.capturedImage!));
//   }

//   Widget buildCardImage(String? symbol) {
//     return symbol != null && symbol.isNotEmpty
//         ? Container(
//             width: cardWidth,
//             height: cardHeight,
//             decoration: BoxDecoration(
//               boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 3))],
//             ),
//             child: Image.asset('assets/images/cards/$symbol.png', fit: BoxFit.cover),
//           )
//         : Container(
//             width: cardWidth,
//             height: cardHeight,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6)),
//             child: const Text(
//               'No Card',
//               style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold),
//             ),
//           );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final capturedBytes = getCapturedImageBytes();

//     final progress = widget.progress.clamp(0.0, 1.0);

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Toggle Switch
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text('Show Image'),
//               const SizedBox(width: 8),
//               Switch(
//                 value: !showCard,
//                 onChanged: (val) {
//                   setState(() {
//                     showCard = !val;
//                   });
//                 },
//               ),
//             ],
//           ),
//         ),

//         Stack(
//           children: [
//             Container(
//               width: windowWidth,
//               height: windowHeight,
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(color: Colors.grey[400]!),
//                 boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 4))],
//               ),
//               child: Center(
//                 child: showCard
//                     ? buildCardImage(widget.symbol)
//                     : (capturedBytes != null
//                           ? ClipRRect(
//                               borderRadius: BorderRadius.circular(10),
//                               child: Image.memory(capturedBytes, width: double.infinity, height: double.infinity, fit: BoxFit.contain),
//                             )
//                           : const Text(
//                               'No Image Captured',
//                               style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
//                             )),
//               ),
//             ),

//             // Progress overlay if progress > 0
//             if (progress > 0)
//               Positioned(
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 height: windowHeight * progress,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.45),
//                     borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
//                   ),
//                   child: Center(
//                     child: Text(
//                       '${(progress * 100).toStringAsFixed(0)}%',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 24,
//                         shadows: [Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 3)],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ],
//     );
//   }
// }

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
            decoration: const BoxDecoration(
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

  Future<void> saveImageToGallery() async {
    final bytes = getCapturedImageBytes();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No image to save')));
      return;
    }

    if (await requestGalleryPermission()) {
      try {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/card_capture_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        final success = await GallerySaver.saveImage(file.path, albumName: 'Card Master');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success == true ? 'Image saved!' : 'Failed to save image')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery permission denied')));
    }
  }

  Future<bool> requestGalleryPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted || await Permission.photos.isGranted) {
        return true;
      }

      final status = await [
        Permission.storage,
        Permission.photos, // for Android 13+
      ].request();

      return status.values.any((element) => element.isGranted);
    }
    return true; // iOS handled separately
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

        // Image container
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
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 4))],
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

            // Progress overlay
            if (progress > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: windowHeight * progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  ),
                  child: Center(
                    child: Text(
                      progress < 1.0 ? '${(progress * 100).toStringAsFixed(0)}%' : 'Processing...',
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

        const SizedBox(height: 12),

        // Save button (only visible if there is an image)
        if (capturedBytes != null)
          ElevatedButton.icon(
            onPressed: saveImageToGallery,
            icon: const Icon(Icons.save_alt),
            label: const Text('Save to Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
      ],
    );
  }
}
