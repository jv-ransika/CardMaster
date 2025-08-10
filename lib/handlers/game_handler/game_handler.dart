import 'dart:ui';
import 'package:card_master/tflite/yolo_detector.dart';

class GameHandler {
  /**
   * H7, H8, H9, H10, HJ, HQ, HK, HA,
   * D7, D8, D9, D10, DJ, DQ, DK, DA,
   * C7, C8, C9, C10, CJ, CQ, CK, CA,
   * S7, S8, S9, S10, SJ, SQ, SK, SA
   */

  bool isValid = false;

  final Map<String, String?> cardsOnBoard = {"me": null, "infront": null, "left": null, "right": null};
  String? currentInputCardSymbol;

  List<String?> currentStack = [null, null, null, null, null, null, null, null];
  String trumpSuit = "H";

  bool pushBtnCardInPressed = false;
  bool pushBtnCardBotTurnPressed = false;

  GameHandler();

  void reset() {
    isValid = false;
    currentInputCardSymbol = null;
    cardsOnBoard.forEach((key, value) {
      cardsOnBoard[key] = null;
    });
  }

  void analyzeInnerCamDetections(List<YOLODetection> detections) {
    if (detections.isNotEmpty) {
      currentInputCardSymbol = detections.first.className;
      sendResponseForPushButtonCardIn();
    } else {
      currentInputCardSymbol = null;
    }
  }

  void analyzeOuterCamDetections(List<YOLODetection> detections, double imgWidth, double imgHeight) {
    cardsOnBoard.forEach((key, value) {
      cardsOnBoard[key] = null;
    });

    final centers = _calcDistinctClassCenters(detections);

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
        cardsOnBoard["me"] = className; // My card
      } else if (dy < 0 && dy.abs() > dx.abs()) {
        cardsOnBoard["infront"] = className; // Partner's card
      } else if (dx < 0) {
        cardsOnBoard["left"] = className; // Opponent 1's card
      } else {
        cardsOnBoard["right"] = className; // Opponent 2's card
      }
    }

    sendResponseForPushButtonCardBotTurn();
  }

  void sendResponseForPushButtonCardIn() {
    if (!pushBtnCardInPressed) return;

    // Send response for "in" button press
  }

  void sendResponseForPushButtonCardBotTurn() {
    if (!pushBtnCardBotTurnPressed) return;

    // Send response for "predict" button press
  }

  Map<String, Offset> _calcDistinctClassCenters(List<YOLODetection> detections) {
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
