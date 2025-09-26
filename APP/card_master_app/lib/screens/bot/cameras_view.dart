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
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),

          buildOuterCameraSection(
            title: "Outer Camera",
            onUpdatePressed: widget.controller.callNeedUpdateOuterImage,
            isUpdating: widget.controller.progressOuterImage > 0,
            content: OmiBoard(me: widget.controller.cardsOnBoard["me"], infront: widget.controller.cardsOnBoard["infront"], left: widget.controller.cardsOnBoard["left"], right: widget.controller.cardsOnBoard["right"], capturedImage: widget.controller.outerImage, progress: widget.controller.progressOuterImage),
          ),

          const SizedBox(height: 16),

          buildInnerCameraSection(
            title: "Inner Camera",
            onUpdatePressed: widget.controller.callNeedUpdateInnerImage,
            isUpdating: widget.controller.progressInnerImage > 0,
            content: CardInputSymbolWindow(symbol: widget.controller.currentInputCardSymbol, capturedImage: widget.controller.innerImage, progress: widget.controller.progressInnerImage),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget buildOuterCameraSection({required String title, required VoidCallback onUpdatePressed, required bool isUpdating, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400, width: 1.0),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 2, blurRadius: 4, offset: const Offset(0, 2))],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onUpdatePressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: const Text("Update"),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            content,
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                widget.controller.onCalibrateCenterClick();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(fontSize: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: const Text("Calibrate Center"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInnerCameraSection({required String title, required VoidCallback onUpdatePressed, required bool isUpdating, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400, width: 1.0),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 2, blurRadius: 4, offset: const Offset(0, 2))],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onUpdatePressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: const Text("Update"),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

class CamerasViewController {
  final Function onNeedUpdateOuterImage;
  final Function onNeedUpdateInnerImage;
  final Function onCalibrateCenterClick;

  img.Image? outerImage;
  img.Image? innerImage;
  double progressOuterImage = 0.0;
  double progressInnerImage = 0.0;

  Map<String, String?> cardsOnBoard = {"me": null, "infront": null, "left": null, "right": null};
  String? currentInputCardSymbol;

  Function? onUpdate;

  CamerasViewController({required this.onNeedUpdateOuterImage, required this.onNeedUpdateInnerImage, required this.onCalibrateCenterClick});

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
