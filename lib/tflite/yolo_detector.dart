import 'package:card_master/tflite/tflite_model.dart';
import 'package:card_master/tflite/tflite_model_isolate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';

class YoloDetector {
  final List<String> classes = ["10C", "10D", "10H", "10S", "2C", "2D", "2H", "2S", "3C", "3D", "3H", "3S", "4C", "4D", "4H", "4S", "5C", "5D", "5H", "5S", "6C", "6D", "6H", "6S", "7C", "7D", "7H", "7S", "8C", "8D", "8H", "8S", "9C", "9D", "9H", "9S", "AC", "AD", "AH", "AS", "JC", "JD", "JH", "JS", "KC", "KD", "KH", "KS", "QC", "QD", "QH", "QS"];

  List<YOLODetection>? detections;
  img.Image? processedImage;

  YoloDetector();

  Future<void> detectObjects(img.Image image, TfliteModelIsolate model) async {
    final int originalWidth = image.width;
    final int originalHeight = image.height;

    final int inputImageSize = model.inputShape[1];

    final result = await compute(preprocessImage, {'image': image, 'inputImageSize': inputImageSize});

    final input = result['tensor'];
    processedImage = result['processedImage'];

    List<List<List<double>>> output = (await model.runInference(input)).cast<List<List<double>>>();

    detections = processYOLOOutput(output, classes, model.outputShape, processedImage!.width, processedImage!.height);

    drawBoundaryBoxes();
  }

  Future<Map<String, dynamic>> preprocessImage(Map<String, dynamic> params) async {
    // img.Image image = params['image'];
    // int inputImageSize = params['inputImageSize'];
    // img.Image resized = img.copyResize(image, width: inputImageSize, height: inputImageSize);

    //=================================

    img.Image image = params['image'];
    int inputImageSize = params['inputImageSize']; // e.g. 640

    // Original size
    int origWidth = image.width; // 1280
    int origHeight = image.height; // 720

    // Calculate square crop size based on smaller dimension (height)
    int cropSize = origHeight; // 720

    // Calculate left-top corner for center crop
    int cropX = ((origWidth - cropSize) / 2).round(); // (1280-720)/2 = 280
    int cropY = 0; // no vertical crop, use full height

    // Crop to square (720x720)
    img.Image cropped = img.copyCrop(image, x: cropX, y: cropY, width: cropSize, height: cropSize);

    // Resize to model input size (640x640)
    img.Image resized = img.copyResize(cropped, width: inputImageSize, height: inputImageSize);

    List<List<List<double>>> imageData = List.generate(inputImageSize, (_) => List.generate(inputImageSize, (_) => List.filled(3, 0.0)));

    for (var i = 0; i < inputImageSize; i++) {
      for (var j = 0; j < inputImageSize; j++) {
        var pixel = resized.getPixel(j, i);
        imageData[i][j][0] = (pixel.r - 128) / 128;
        imageData[i][j][1] = (pixel.g - 128) / 128;
        imageData[i][j][2] = (pixel.b - 128) / 128;
      }
    }

    return {
      'tensor': [imageData], // shape: 1x640x640x3
      'processedImage': resized,
    };
  }

  List<YOLODetection> processYOLOOutput(List<List<List<double>>> yoloOutput, List<String> classes, List<int> outputShape, int imageWidthOriginal, int imageHeightOriginal) {
    List<YOLODetection> detections = [];

    int numDetections = outputShape[2];
    int numClasses = outputShape[1] - 4;

    for (int i = 0; i < numDetections; i++) {
      int bestClass = -1;
      double bestClassScore = 0.0;

      for (int j = 4; j < 4 + numClasses; j++) {
        if (yoloOutput[0][j][i] > bestClassScore) {
          bestClassScore = yoloOutput[0][j][i];
          bestClass = j - 4;
        }
      }

      if (bestClassScore < 0.5) continue;

      final detection = YOLODetection()
        ..classIndex = bestClass
        ..confidence = bestClassScore
        ..boxX = yoloOutput[0][0][i] * imageWidthOriginal
        ..boxY = yoloOutput[0][1][i] * imageHeightOriginal
        ..boxWidth = yoloOutput[0][2][i] * imageWidthOriginal
        ..boxHeight = yoloOutput[0][3][i] * imageHeightOriginal
        ..className = (bestClass < classes.length) ? classes[bestClass] : '';

      detections.add(detection);
    }

    return applyNMS(detections, 0.5);
  }

  List<YOLODetection> applyNMS(List<YOLODetection> detections, double iouThreshold) {
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    List<YOLODetection> finalDetections = [];

    while (detections.isNotEmpty) {
      final bestDetection = detections.removeAt(0);
      finalDetections.add(bestDetection);

      detections.removeWhere((d) => computeIoU(bestDetection, d) > iouThreshold);
    }

    return finalDetections;
  }

  double computeIoU(YOLODetection box1, YOLODetection box2) {
    double x1 = math.max(box1.boxX, box2.boxX);
    double y1 = math.max(box1.boxY, box2.boxY);
    double x2 = math.min(box1.boxX + box1.boxWidth, box2.boxX + box2.boxWidth);
    double y2 = math.min(box1.boxY + box1.boxHeight, box2.boxY + box2.boxHeight);

    double intersection = math.max(0, x2 - x1) * math.max(0, y2 - y1);
    double box1Area = box1.boxWidth * box1.boxHeight;
    double box2Area = box2.boxWidth * box2.boxHeight;

    double union = box1Area + box2Area - intersection;
    return union > 0 ? intersection / union : 0;
  }

  void drawBoundaryBoxes() {
    for (var detection in detections!) {
      print("${detection.className} - ${detection.confidence} - ${detection.boxX}, ${detection.boxY}, ${detection.boxWidth}, ${detection.boxHeight}");
      // Convert center-based coords to corner-based
      final x1 = (detection.boxX - detection.boxWidth / 2).toInt();
      final y1 = (detection.boxY - detection.boxHeight / 2).toInt();
      final x2 = (detection.boxX + detection.boxWidth / 2).toInt();
      final y2 = (detection.boxY + detection.boxHeight / 2).toInt();

      img.drawRect(processedImage!, x1: x1, y1: y1, x2: x2, y2: y2, color: img.ColorRgb8(0, 255, 0), thickness: 2);
    }
  }
}

class YOLODetection {
  int classIndex = -1;
  double confidence = 0.0;
  double boxX = 0.0;
  double boxY = 0.0;
  double boxWidth = 0.0;
  double boxHeight = 0.0;
  String className = '';
}
