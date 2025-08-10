import 'package:card_master/tflite/tflite_model.dart';
import 'package:card_master/tflite/tflite_model_isolate.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';

class YoloDetector {
  final List<String> classes = ["10C", "10D", "10H", "10S", "2C", "2D", "2H", "2S", "3C", "3D", "3H", "3S", "4C", "4D", "4H", "4S", "5C", "5D", "5H", "5S", "6C", "6D", "6H", "6S", "7C", "7D", "7H", "7S", "8C", "8D", "8H", "8S", "9C", "9D", "9H", "9S", "AC", "AD", "AH", "AS", "JC", "JD", "JH", "JS", "KC", "KD", "KH", "KS", "QC", "QD", "QH", "QS"];

  YoloDetector();

  Future<List<YOLODetection>> detectObjects(img.Image image, TfliteModelIsolate model) async {
    final int originalWidth = image.width;
    final int originalHeight = image.height;

    final int inputImageSize = model.inputShape[1];

    final input = await compute(preprocessImage, {'image': image, 'inputImageSize': inputImageSize});

    List<List<List<double>>> output = (await model.runInference(input)).cast<List<List<double>>>();

    return processYOLOOutput(output, classes, model.outputShape, originalWidth, originalHeight);
  }

  Future<List<List<List<List<double>>>>> preprocessImage(Map<String, dynamic> params) async {
    img.Image image = params['image'];
    int inputImageSize = params['inputImageSize'];

    img.Image resized = img.copyResize(image, width: inputImageSize, height: inputImageSize);

    List<List<List<double>>> imageData = List.generate(inputImageSize, (_) => List.generate(inputImageSize, (_) => List.filled(3, 0.0)));

    for (var i = 0; i < inputImageSize; i++) {
      for (var j = 0; j < inputImageSize; j++) {
        var pixel = resized.getPixel(j, i);
        imageData[i][j][0] = (pixel.r - 128) / 128;
        imageData[i][j][1] = (pixel.g - 128) / 128;
        imageData[i][j][2] = (pixel.b - 128) / 128;
      }
    }

    // Wrap into batch size of 1
    return [imageData];
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

      if (bestClassScore < 0.3) continue;

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
