import 'dart:ui';
import 'package:card_master/tflite/yolo_detector.dart';
import 'package:flutter/material.dart';

enum BotAction { btnCardInPressed, btnCardOutPressed, btnDetermineCurrentRoundScoresPressed }

class GameHandler {
  /**
   * H7, H8, H9, H10, HJ, HQ, HK, HA,
   * D7, D8, D9, D10, DJ, DQ, DK, DA,
   * C7, C8, C9, C10, CJ, CQ, CK, CA,
   * S7, S8, S9, S10, SJ, SQ, SK, SA
   */

  final List<String> valueOrder = ["7", "8", "9", "10", "J", "Q", "K", "A"];

  final List<String> labelOrder = ["H7", "H8", "H9", "H10", "HJ", "HQ", "HK", "HA", "D7", "D8", "D9", "D10", "DJ", "DQ", "DK", "DA", "C7", "C8", "C9", "C10", "CJ", "CQ", "CK", "CA", "S7", "S8", "S9", "S10", "SJ", "SQ", "SK", "SA"];

  bool isValid = false;

  final Map<String, String?> cardsOnBoard = {"me": null, "infront": null, "left": null, "right": null};
  String? currentInputCardSymbol;

  List<String?> stack = [null, null, null, null, null, null, null, null]; // Current stack
  String? trumpSuit; // Current trump suit
  List<String> cardUsedSoFar = [];

  String? beginSuitOfCurrentRound;

  int ourScore = 0;
  int opponentScore = 0;

  BotAction? currentAction;
  String? actionResponse;

  final Function onSayTrumpSuit;
  final Function onScoreUpdate;
  final Function(String response) onActionResponse;

  GameHandler({required this.onSayTrumpSuit, required this.onScoreUpdate, required this.onActionResponse});

  void reset() {
    isValid = false;
    currentInputCardSymbol = null;
    cardsOnBoard.forEach((key, value) {
      cardsOnBoard[key] = null;
    });

    stack = [null, null, null, null, null, null, null, null];
    cardUsedSoFar.clear();
  }

  void analyzeInnerCamDetections(List<YOLODetection> detections) {
    if (detections.isNotEmpty) {
      currentInputCardSymbol = detections.first.className;
      performActions();
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

    performActions();
  }

  void performActions() {
    switch (currentAction) {
      case BotAction.btnCardInPressed:
        sendResponseForBtnCardIn();
        break;
      case BotAction.btnCardOutPressed:
        sendResponseForBtnCardOut();
        _determineBeginSuitOfCurrentRound();
        break;
      case BotAction.btnDetermineCurrentRoundScoresPressed:
        sendResponseForBtnDetermineCurrentRoundScores();
        break;
      default:
    }

    if (actionResponse != null) {
      onActionResponse(actionResponse!);
      actionResponse = null;
    }
  }

  void sendResponseForBtnDetermineCurrentRoundScores() {
    String? maxPlayer;
    int maxMark = 0;

    cardsOnBoard.forEach((player, card) {
      if (card != null) {
        int mark = _cardToMark(card);
        if (mark > maxMark) {
          maxMark = mark;
          maxPlayer = player;
        }
      }
    });

    if (maxPlayer == "me" || maxPlayer == "infront") {
      ourScore += 1;
      actionResponse = "win";
    } else {
      opponentScore += 1;
      actionResponse = "loss";
    }

    // If stack card count is 0, the current round is over
    if (_stackCardCount() == 0) {
      actionResponse = actionResponse! + "-final";
    }

    onScoreUpdate();
  }

  void sendResponseForBtnCardIn() {
    for (int i = 0; i < stack.length; i++) {
      if (stack[i] == null) {
        stack[i] = currentInputCardSymbol;
        break;
      }
    }

    //...
  }

  void sendResponseForBtnCardOut() {
    for (var card in cardsOnBoard.values) {
      if (card != null && !cardUsedSoFar.contains(card)) {
        cardUsedSoFar.add(card);
      }
    }

    // Bot need to say the trump if the length of stack is 4 and trumpSuit is not set
    if (stack.length == 4 && trumpSuit == null) {
      sayTrumpSuit();
      return;
    }
  }

  void sayTrumpSuit() {
    // The mostly existing suit of current stack is the trump suit
    Map<String, int> suitCount = {};
    for (var card in stack) {
      if (card != null) {
        String suit = card.substring(card.length - 1);
        suitCount[suit] = (suitCount[suit] ?? 0) + 1;
      }
    }

    // Find the suit(s) with the maximum count
    List<String> maxSuits = [];
    int maxCount = suitCount.values.reduce((a, b) => a > b ? a : b);
    suitCount.forEach((suit, count) {
      if (count == maxCount) {
        maxSuits.add(suit);
      }
    });

    if (maxSuits.length == 1) {
      trumpSuit = maxSuits.first;
    } else if (maxSuits.length > 1) {
      int prevValue = 0;
      for (var card in stack) {
        if (card == null) continue;
        String suit = _getCardSuit(card);
        int value = _getCardValue(card);
        if (!maxSuits.contains(suit)) continue;
        if (value > prevValue) {
          prevValue = value;
          trumpSuit = suit;
        }
      }
    }

    onSayTrumpSuit();
  }

  String _determineBeginSuitOfCurrentRound() {
    // Move through me -> left -> infront -> right, and find the first non-null card
    for (var position in ["me", "left", "infront", "right"]) {
      if (cardsOnBoard[position] != null) {
        beginSuitOfCurrentRound = cardsOnBoard[position]!.substring(cardsOnBoard[position]!.length - 1);
        break;
      }
    }
    return beginSuitOfCurrentRound ?? "";
  }

  int _cardToMark(String card) {
    int value = _getCardValue(card);
    String suit = _getCardSuit(card);

    int mark = 0;

    mark += value;

    if (suit == trumpSuit) {
      mark += 16;
    } else if (suit == beginSuitOfCurrentRound) {
      mark += 8;
    }

    return mark;
  }

  String _getCardSuit(String card) {
    return card[0];
  }

  int _getCardValue(String card) {
    return valueOrder.indexOf(card[1]) + 1;
  }

  int _stackCardCount() {
    return stack.where((card) => card != null).length;
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
