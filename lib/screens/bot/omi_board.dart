import 'dart:ui';
import 'package:card_master/tflite/yolo_detector.dart';

class OmiBoard {
  bool isValid = false;

  final Map<String, String?> cards = {"me": null, "infront": null, "left": null, "right": null};

  OmiBoard();

  void reset() {
    isValid = false;
    cards.forEach((key, value) {
      cards[key] = null;
    });
  }

  void classifyDetections(List<YOLODetection> detections, double imgWidth, double imgHeight) {
    reset();

    final centers = calcDistinctClassCenters(detections);

    if (centers.length > 4) return;
    isValid = true;

    // Get board center
    double boardCenterX = imgWidth / 2;
    double boardCenterY = imgHeight / 2;

    // Map cards to direction based on position relative to board center
    for (var entry in centers.entries) {
      String className = entry.key;
      Offset center = entry.value;

      double dx = center.dx - boardCenterX;
      double dy = center.dy - boardCenterY;

      if (dy > 0 && dy.abs() > dx.abs()) {
        cards["me"] = className; // My card
      } else if (dy < 0 && dy.abs() > dx.abs()) {
        cards["infront"] = className; // Partner's card
      } else if (dx < 0) {
        cards["left"] = className; // Opponent 1's card
      } else {
        cards["right"] = className; // Opponent 2's card
      }
    }
  }

  Map<String, Offset> calcDistinctClassCenters(List<YOLODetection> detections) {
    final Map<String, List<Offset>> classToCenters = {};

    // Group centers by class
    for (var detection in detections) {
      classToCenters.putIfAbsent(detection.className, () => []);
      classToCenters[detection.className]!.add(Offset(detection.boxX, detection.boxY));
    }

    final Map<String, Offset> result = {};

    // Compute geometric center for each class
    classToCenters.forEach((className, centers) {
      if (centers.isEmpty) return;

      double sumX = 0;
      double sumY = 0;

      for (var center in centers) {
        sumX += center.dx;
        sumY += center.dy;
      }

      double avgX = sumX / centers.length;
      double avgY = sumY / centers.length;

      result[className] = Offset(avgX, avgY);
    });

    return result;
  }
}
