import 'dart:typed_data';

import 'package:card_master/components/card_input_symbol_window.dart';
import 'package:card_master/components/omi_board.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CamerasView extends StatefulWidget {
  final CamerasViewController controller;

  CamerasView({required this.controller});

  @override
  _CamerasViewState createState() => _CamerasViewState();
}

class _CamerasViewState extends State<CamerasView> {
  @override
  void initState() {
    widget.controller.onUpdate = () {
      setState(() {});
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 1.0),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 2, blurRadius: 4, offset: const Offset(0, 2))],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("Outer Camera", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => widget.controller.progressOuterImage > 0 ? null : widget.controller.callNeedUpdateOuterImage(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // Reduced border radius
                    ),
                  ),
                  child: const Text("Update"),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),

        OmiBoard(me: "2D", infront: "3C", left: "AH", right: "6S", capturedImage: widget.controller.outerImage, progress: widget.controller.progressOuterImage),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 1.0),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 2, blurRadius: 4, offset: const Offset(0, 2))],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("Inner Camera", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => widget.controller.progressInnerImage > 0 ? null : widget.controller.callNeedUpdateInnerImage(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // Reduced border radius
                    ),
                  ),
                  child: const Text("Update"),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),

        CardInputSymbolWindow(symbol: "2D", capturedImage: widget.controller.outerImage, progress: widget.controller.progressOuterImage),

        const SizedBox(height: 16),
      ],
    );
  }
}

class CamerasViewController {
  final Function onNeedUpdateOuterImage;
  final Function onNeedUpdateInnerImage;

  img.Image? outerImage;
  img.Image? innerImage;
  double progressOuterImage = 0.0;
  double progressInnerImage = 0.0;

  Function? onUpdate;

  CamerasViewController({required this.onNeedUpdateOuterImage, required this.onNeedUpdateInnerImage});

  void callNeedUpdateOuterImage() {
    onNeedUpdateOuterImage.call();
  }

  void callNeedUpdateInnerImage() {
    onNeedUpdateInnerImage.call();
  }

  void update() {
    onUpdate?.call();
  }
}
