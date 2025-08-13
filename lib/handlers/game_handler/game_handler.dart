import 'dart:typed_data';
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

  final List<String> suitOrder = ["H", "D", "C", "S"];
  final List<String> valueOrder = ["7", "8", "9", "10", "J", "Q", "K", "A"];
  final List<String> labelOrder = ["H7", "H8", "H9", "H10", "HJ", "HQ", "HK", "HA", "D7", "D8", "D9", "D10", "DJ", "DQ", "DK", "DA", "C7", "C8", "C9", "C10", "CJ", "CQ", "CK", "CA", "S7", "S8", "S9", "S10", "SJ", "SQ", "SK", "SA"];
  final Map<String, String> nextPlayerOf = {"me": "right", "right": "infront", "infront": "left", "left": "me"};

  bool isValid = false;

  final Map<String, String?> cardsOnDesk = {"me": null, "infront": null, "left": null, "right": null};
  String? currentInputCardSymbol;

  List<String?> stack = [null, null, null, null, null, null, null, null]; // Current stack
  String? trumpSuit; // Current trump suit
  List<String> cardUsedSoFar = [];

  String? beginSuitOfCurrentTrick;
  String? beginPlayerOfCurrentTrick;

  int ourScore = 0;
  int opponentScore = 0;

  BotAction? currentAction;
  String? actionResponse;

  final Function onSayTrumpSuit;
  final Function onScoreUpdate;
  final Function(String response) onActionResponse;
  final Future<int> Function(Int64List trumpSuitData, Int64List handData, Int64List deskData, Int64List playedData, List<bool> validActionsData) onGetPredictedCard;

  GameHandler({required this.onSayTrumpSuit, required this.onScoreUpdate, required this.onActionResponse, required this.onGetPredictedCard});

  void reset() {
    isValid = false;

    cardsOnDesk.forEach((key, value) {
      cardsOnDesk[key] = null;
    });
    currentInputCardSymbol = null;

    stack = [null, null, null, null, null, null, null, null];
    trumpSuit = null;
    cardUsedSoFar.clear();

    beginSuitOfCurrentTrick = null;
    beginPlayerOfCurrentTrick = null;

    ourScore = 0;
    opponentScore = 0;

    currentAction = null;
    actionResponse = null;
  }

  void analyzeInnerCamDetections(List<YOLODetection> detections) {
    if (detections.isNotEmpty) {
      currentInputCardSymbol = detections.first.className;
      debugPrint("Current Input Card Symbol: $currentInputCardSymbol");
      performActions();
    } else {
      currentInputCardSymbol = null;
    }
  }

  void analyzeOuterCamDetections(List<YOLODetection> detections, double imgWidth, double imgHeight) {
    cardsOnDesk.forEach((key, value) {
      cardsOnDesk[key] = null;
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
        cardsOnDesk["me"] = className; // My card
      } else if (dy < 0 && dy.abs() > dx.abs()) {
        cardsOnDesk["infront"] = className; // Partner's card
      } else if (dx < 0) {
        cardsOnDesk["left"] = className; // Opponent 1's card
      } else {
        cardsOnDesk["right"] = className; // Opponent 2's card
      }
    }

    debugPrint("Cards on Desk: $cardsOnDesk");

    performActions();
  }

  void performActions() {
    switch (currentAction) {
      case BotAction.btnCardInPressed:
        sendResponseForBtnCardIn();
        break;
      case BotAction.btnCardOutPressed:
        sendResponseForBtnCardOut();
        break;
      case BotAction.btnDetermineCurrentRoundScoresPressed:
        sendResponseForBtnDetermineCurrentRoundScores();
        break;
      default:
    }

    currentAction = null;

    if (actionResponse != null) {
      onActionResponse(actionResponse!);
      actionResponse = null;
    }
  }

  void sendResponseForBtnDetermineCurrentRoundScores() {
    _addOtherPlayedCardsToCardUsedSoFar();

    String? maxPlayer;
    int maxMark = 0;

    cardsOnDesk.forEach((player, card) {
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
      debugPrint("We won the trick! Score: $ourScore, Opponent Score: $opponentScore");
    } else {
      opponentScore += 1;
      actionResponse = "loss";
      debugPrint("We lost the trick! Our Score: $ourScore, Opponent Score: $opponentScore");
    }

    // If stack card count is 0, the current round is over
    if (_stackCardCount() == 0) {
      actionResponse = actionResponse! + "-final";
      debugPrint("Round over! Our Score: $ourScore, Opponent Score: $opponentScore");
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

    actionResponse = currentInputCardSymbol;
  }

  void sendResponseForBtnCardOut() async {
    // Bot need to say the trump if the length of stack is 4 and trumpSuit is not set
    if (stack.length == 4 && trumpSuit == null) {
      _determineTrumpSuit();
      onSayTrumpSuit();
      actionResponse = trumpSuit;
      return;
    }

    // Add other played cards into cardUsedSoFar
    _addOtherPlayedCardsToCardUsedSoFar();

    if (_deskCardCount() > 0) {
      // Beginner of current trick is not me
      _determineBeginSuitOfCurrentTrick();
    } else {
      // Beginner of current trick is me
      beginSuitOfCurrentTrick = null;
      beginPlayerOfCurrentTrick = "me";
    }

    //============== Prepare inputs to feed to model ==============

    // Input: trump_suit (shape [1], type int64) -> H, D, C, S
    // Ex: Int64List.fromList([3])
    Int64List trumpSuitData = Int64List.fromList([suitOrder.indexOf(trumpSuit!)]);

    // Input: hand (shape [1, 8], type int64) -> index of symbol
    // Ex: Int64List.fromList([10, 14, 25, 28, 0, 0, 0, 0]);
    Int64List handData = Int64List.fromList(
      stack.map((card) {
        if (card == null) return 0;
        return _getCardIndex(card);
      }).toList(),
    );

    // Input: desk (shape [1, 4], type int64)
    // Ex: Int64List.fromList([5, 9, 0, 0]); | <beginPlayerOfCurrentTrick, nextPlayer, nextPlayer, nextPlayer>
    Int64List deskData = Int64List(0);
    if (beginSuitOfCurrentTrick != null) {
      String temp = beginPlayerOfCurrentTrick!;
      for (var i = 0; i < 4; i++) {
        deskData.add(cardsOnDesk[temp] != null ? _getCardIndex(cardsOnDesk[temp]!) : 0);
        temp = nextPlayerOf[temp]!;
      }
    } else {
      deskData = [0, 0, 0, 0] as Int64List;
    }

    // Input: played (shape [1, 32], type int64)
    // Ex: Int64List(32);
    Int64List playedData = Int64List(32);
    for (var card in cardUsedSoFar) {
      playedData[_getCardIndex(card)] = 1;
    }
    for (var i = 0; i < labelOrder.length - cardUsedSoFar.length; i++) {
      playedData.add(0); // Padding with 0
    }

    // Input: valid_actions (shape [1, 32], type boolean)
    // Ex:  [List.generate(32, (i) => i == 10 || i == 14 || i == 25 || i == 28)]
    List<bool> validActionsData = List.generate(labelOrder.length, (index) => false);

    String? currentSuit = beginSuitOfCurrentTrick;

    if (currentSuit != null && stack.any((card) => card != null && _getCardSuit(card) == currentSuit)) {
      for (var card in stack) {
        if (card != null && _getCardSuit(card) == currentSuit) {
          validActionsData[_getCardIndex(card)] = true;
        }
      }
    } else {
      for (var card in stack) {
        if (card != null) {
          validActionsData[_getCardIndex(card)] = true;
        }
      }
    }

    //=============================================================

    int predictedIndex = await onGetPredictedCard(trumpSuitData, handData, deskData, playedData, validActionsData);
    if (predictedIndex == -1) {
      throw Exception("Failed to predict card");
    }

    String predictedCard = labelOrder[predictedIndex];

    // Remove predictedCard from stack
    _removeCardFromStack(predictedCard);

    // Set the begin suit of the current trick (begin player "me")
    beginSuitOfCurrentTrick = _getCardSuit(predictedCard);

    // Add predictedCard to cardUsedSoFar
    if (!cardUsedSoFar.contains(predictedCard)) {
      cardUsedSoFar.add(predictedCard);
    }

    actionResponse = predictedCard;
  }

  _removeCardFromStack(String card) {
    for (var i = 0; i < stack.length; i++) {
      if (stack[i] == card) {
        stack[i] = null;
        break;
      }
    }
  }

  _addOtherPlayedCardsToCardUsedSoFar() {
    for (var entry in cardsOnDesk.entries) {
      if (entry.key != "me" && entry.value != null && !cardUsedSoFar.contains(entry.value)) {
        cardUsedSoFar.add(entry.value!);
      }
    }
  }

  _determineTrumpSuit() {
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
  }

  _determineBeginSuitOfCurrentTrick() {
    // Move through me -> right -> infront -> left, and find the first non-null card
    for (var position in ["me", "right", "infront", "left"]) {
      if (cardsOnDesk[position] != null) {
        beginSuitOfCurrentTrick = _getCardSuit(cardsOnDesk[position]!);
        beginPlayerOfCurrentTrick = position;
        break;
      }
    }

    debugPrint("Begin suit of current trick: $beginSuitOfCurrentTrick, player: $beginPlayerOfCurrentTrick");
  }

  int _cardToMark(String card) {
    int value = _getCardValue(card);
    String suit = _getCardSuit(card);

    int mark = 0;

    mark += value;

    if (suit == trumpSuit) {
      mark += 16;
    } else if (suit == beginSuitOfCurrentTrick) {
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

  int _getCardIndex(String card) {
    return labelOrder.indexOf(card);
  }

  int _deskCardCount() {
    return cardsOnDesk.values.where((card) => card != null).length;
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
