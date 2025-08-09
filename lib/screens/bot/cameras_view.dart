import 'dart:typed_data';

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
        const Text("Outer Image"),
        const SizedBox(height: 8),

        if (widget.controller.progressOuterImage > 0) ...[LinearProgressIndicator(value: widget.controller.progressOuterImage)],
        if (widget.controller.outerImage != null) ...[Image.memory(Uint8List.fromList(img.encodeJpg(widget.controller.outerImage!)))],
        ElevatedButton(onPressed: () => widget.controller.callNeedUpdateOuterImage(), child: const Text("Update Outer Image")),

        const Text("Inner Image"),
        const SizedBox(height: 8),

        if (widget.controller.progressInnerImage > 0) ...[LinearProgressIndicator(value: widget.controller.progressInnerImage)],
        if (widget.controller.innerImage != null) ...[Image.memory(Uint8List.fromList(img.encodeJpg(widget.controller.innerImage!)))],
        ElevatedButton(onPressed: () => widget.controller.callNeedUpdateInnerImage(), child: const Text("Update Inner Image")),
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

  CamerasViewController({
    required this.onNeedUpdateOuterImage,
    required this.onNeedUpdateInnerImage,
  });

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
