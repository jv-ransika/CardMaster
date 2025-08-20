import 'dart:typed_data';
import 'dart:ui';
import 'package:card_master/tflite/yolo_detector.dart';
import 'package:flutter/material.dart';

enum BotAction { btnInPressed, btnMainPressed }

enum GameState {
  waitingForCards, // Initial stack filling
  playingTricks, // Playing trick cards
  roundOver, // Round finished, scores updated
}

class GameHandler {
  /**
   * H7, H8, H9, H10, HJ, HQ, HK, HA,
   * D7, D8, D9, D10, DJ, DQ, DK, DA,
   * C7, C8, C9, C10, CJ, CQ, CK, CA,
   * S7, S8, S9, S10, SJ, SQ, SK, SA
   */

  final List<String> suitOrder = ["H", "D", "C", "S"];
  final List<String> valueOrder = ["7", "8", "9", "10", "J", "Q", "K", "A"];
  final List<String> labelOrder = ["7H", "8H", "9H", "10H", "JH", "QH", "KH", "AH", "7D", "8D", "9D", "10D", "JD", "QD", "KD", "AD", "7C", "8C", "9C", "10C", "JC", "QC", "KC", "AC", "7S", "8S", "9S", "10S", "JS", "QS", "KS", "AS"];
  final Map<String, String> nextPlayerOf = {"me": "right", "right": "infront", "infront": "left", "left": "me"};

  bool isValid = false;

  final Map<String, String?> cardsOnDesk = {"me": null, "infront": null, "left": null, "right": null};
  String? currentInputCardSymbol;

  // List<String?> stack = [null, null, null, null, null, null, null, null]; // Current stack
  List<String?> stack = ["7H", "10S", "JC", "QH", "AC", "10C", "9S", "8S"];
  String? trumpSuit = "H"; // Current trump suit
  List<String> cardUsedSoFar = [];

  String? beginSuitOfCurrentTrick;
  String? beginPlayerOfCurrentTrick;

  int ourScore = 0;
  int opponentScore = 0;

  GameState? currentState = GameState.playingTricks;
  String actionResponse = "";

  Function? afterAnalyzeActionResponse; // Closure to be executed after analyzing detections

  bool cameraCaptureRequired = false;

  Offset boardCenter = Offset(320, 320);

  final Function onGameStarted;
  final Function onRoundOver;
  final Function onSayTrumpSuit;
  final Function onScoreUpdate;
  final Function onCardThrow;
  final Function(String response) onActionResponse;
  final Future<int> Function(Int64List trumpSuitData, Int64List handData, Int64List deskData, Int64List playedData, List<bool> validActionsData) onGetPredictedCard;

  GameHandler({required this.onGameStarted, required this.onRoundOver, required this.onSayTrumpSuit, required this.onScoreUpdate, required this.onCardThrow, required this.onActionResponse, required this.onGetPredictedCard});

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

    currentState = GameState.waitingForCards;
    actionResponse = "";

    afterAnalyzeActionResponse = null;

    cameraCaptureRequired = false;

    printAllValues();
  }

  void printAllValues() {
    debugPrint("Cards on Desk: $cardsOnDesk");
    debugPrint("Current Input Card Symbol: $currentInputCardSymbol");
    debugPrint("Stack: $stack");
    debugPrint("Trump Suit: $trumpSuit");
    debugPrint("Card Used So Far: $cardUsedSoFar");
    debugPrint("Begin Suit Of Current Trick: $beginSuitOfCurrentTrick");
    debugPrint("Begin Player Of Current Trick: $beginPlayerOfCurrentTrick");
    debugPrint("Our Score: $ourScore");
    debugPrint("Opponent Score: $opponentScore");
  }

  void triggerBotAction(BotAction action) {
    debugPrint("Bot Action: $action");

    switch (currentState!) {
      case GameState.waitingForCards:
        if (action == BotAction.btnInPressed) {
          debugPrint("Perform: Card In, Waiting for inner camera detection...");
          cameraCaptureRequired = true;
          afterAnalyzeActionResponse = () {
            debugPrint("After Analyze Action Response: Card In");
            sendResponseForBtnCardIn();
            if (stackCardCount() == 8) {
              onGameStarted();
              currentState = GameState.playingTricks;
            }
            callbackActionResponse();
          };
        } else if (action == BotAction.btnMainPressed) {
          if (stackCardCount() == 4) {
            debugPrint("Perform: Say Trump Suit");
            cameraCaptureRequired = false;
            String? trump = getTrumpSuit();
            if (trump != null) {
              actionResponse = "res-trump-$trump";
            }
            callbackActionResponse();
          }
        }
        break;
      case GameState.playingTricks:
        if (action == BotAction.btnMainPressed) {
          debugPrint("Perform: Card Out, Waiting for outer camera detection...");
          cameraCaptureRequired = true;
          afterAnalyzeActionResponse = () async {
            if (deskCardCount() == 4) {
              debugPrint("After Analyze Action Response: Determining Trick Scores (4 Cards)");
              String result = getCurrentTrickScores();
              actionResponse = "res-trick-$result";
            } else {
              debugPrint("After Analyze Action Response: Card Out");
              await sendResponseForBtnCardOut();
            }

            // Detect, round is over
            if (deskCardCount() == 0 && stackCardCount() == 0) {
              debugPrint("After Analyze Action Response: Round Over");
              onRoundOver();
              currentState = GameState.roundOver;
              actionResponse = "res-game-${getFinalRoundScores()}";
            }

            callbackActionResponse();
          };
        }
        break;
      case GameState.roundOver:
        // Handle round over state
        break;
    }
  }

  void analyzeInnerCamDetections(List<YOLODetection> detections) {
    if (detections.isNotEmpty) {
      currentInputCardSymbol = detections.first.className;
      if (!labelOrder.contains(currentInputCardSymbol!)) {
        debugPrint("Invalid card detected: $currentInputCardSymbol");
        currentInputCardSymbol = null;
        actionResponse = "res-invalid";
        callbackActionResponse();
        return;
      }
      debugPrint("Current Input Card Symbol: $currentInputCardSymbol");
      performAfterAnalyzeActionResponse();
    } else {
      currentInputCardSymbol = null;
    }
  }

  void analyzeOuterCamDetections(List<YOLODetection> detections, {bool lockCallActions = false}) {
    cardsOnDesk.forEach((key, value) {
      if (key != "me") cardsOnDesk[key] = null;
    });

    final centers = _calcDistinctClassCenters(detections);

    if (centers.length > 4) return;
    isValid = true;

    // Get board center
    double boardCenterX = boardCenter.dx;
    double boardCenterY = boardCenter.dy;

    // Map cards to direction based on position relative to board center
    for (var entry in centers.entries) {
      print(entry);
      String className = entry.key;
      Offset center = entry.value;

      double dx = center.dx - boardCenterX;
      double dy = center.dy - boardCenterY;

      if (dy > 0 && dy.abs() > dx.abs()) {
        // cardsOnDesk["me"] = className; // My card
      } else if (dy < 0 && dy.abs() > dx.abs()) {
        cardsOnDesk["infront"] = className; // Partner's card
      } else if (dx < 0) {
        cardsOnDesk["left"] = className; // Opponent 1's card
      } else {
        cardsOnDesk["right"] = className; // Opponent 2's card
      }
    }

    // Check all not null cards contains in label order
    bool invalid = false;
    for (var player in cardsOnDesk.keys) {
      if (cardsOnDesk[player] != null && !labelOrder.contains(cardsOnDesk[player]!)) {
        debugPrint("Invalid card detected on $player: ${cardsOnDesk[player]}");
        cardsOnDesk[player] = null;
        invalid = true;
      }
    }

    if (invalid) {
      actionResponse = "res-invalid";
      callbackActionResponse();
      return;
    }

    debugPrint("Cards on Desk: $cardsOnDesk");

    performAfterAnalyzeActionResponse();
  }

  void performAfterAnalyzeActionResponse() {
    if (afterAnalyzeActionResponse == null) return;
    afterAnalyzeActionResponse!();
    afterAnalyzeActionResponse = null;
  }

  void callbackActionResponse() {
    if (actionResponse == "") return;
    printAllValues();
    onActionResponse(actionResponse);
    actionResponse = "";
  }

  void sendResponseForBtnCardIn() {
    if (currentInputCardSymbol == null) return;

    // Resend last card index if exists
    if (isCardExistsInStack(currentInputCardSymbol!)) {
      debugPrint("Resending last card index for: $currentInputCardSymbol");
      int lastIndex = stack.lastIndexOf(currentInputCardSymbol!);
      actionResponse = "res-in-${lastIndex + 1}";
      return;
    }

    // Avoid after game starts
    if (cardUsedSoFar.isNotEmpty) {
      return;
    }

    int insertedIndex = -1;

    for (int i = 0; i < stack.length; i++) {
      if (stack[i] == null) {
        stack[i] = currentInputCardSymbol;
        insertedIndex = i;
        break;
      }
    }

    actionResponse = "res-in-${insertedIndex + 1}";
  }

  Future<void> sendResponseForBtnCardOut() async {
    // Add other played cards into cardUsedSoFar
    _addOtherPlayedCardsToCardUsedSoFar();

    if (deskCardCount() > 0) {
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
        return getCardIndex(card);
      }).toList(),
    );

    // Input: desk (shape [1, 4], type int64)
    // Ex: Int64List.fromList([5, 9, 0, 0]); | <beginPlayerOfCurrentTrick, nextPlayer, nextPlayer, nextPlayer>
    Int64List deskData = Int64List(4);
    if (beginSuitOfCurrentTrick != null) {
      String temp = beginPlayerOfCurrentTrick!;
      for (var i = 0; i < 4; i++) {
        deskData[i] = (temp != "me" && cardsOnDesk[temp] != null) ? getCardIndex(cardsOnDesk[temp]!) : 0;
        temp = nextPlayerOf[temp]!;
      }
    } else {
      deskData = Int64List.fromList([0, 0, 0, 0]);
    }

    // Input: played (shape [1, 32], type int64)
    // Ex: Int64List(32);
    Int64List playedData = Int64List(32);
    for (var card in cardUsedSoFar) {
      playedData[getCardIndex(card)] = 1;
    }

    // Input: valid_actions (shape [1, 32], type boolean)
    // Ex:  [List.generate(32, (i) => i == 10 || i == 14 || i == 25 || i == 28)]
    List<bool> validActionsData = List.generate(labelOrder.length, (index) => false);

    String? currentSuit = beginSuitOfCurrentTrick;

    if (currentSuit != null && stack.any((card) => card != null && getCardSuit(card) == currentSuit)) {
      for (var card in stack) {
        if (card != null && getCardSuit(card) == currentSuit) {
          validActionsData[getCardIndex(card)] = true;
        }
      }
    } else {
      for (var card in stack) {
        if (card != null) {
          validActionsData[getCardIndex(card)] = true;
        }
      }
    }

    debugPrint("Valid actions: $validActionsData");

    //=============================================================

    int predictedIndex = await onGetPredictedCard(trumpSuitData, handData, deskData, playedData, validActionsData);
    if (predictedIndex == -1) {
      throw Exception("Failed to predict card");
    }

    String predictedCard = labelOrder[predictedIndex];
    debugPrint("Predicted card: $predictedCard");

    // Update cardsOnDesk for me
    cardsOnDesk["me"] = predictedCard;

    // Set the begin suit of the current trick (begin player "me")
    if (beginPlayerOfCurrentTrick == "me") {
      beginSuitOfCurrentTrick = getCardSuit(predictedCard);
    }

    // Add predictedCard to cardUsedSoFar
    if (!cardUsedSoFar.contains(predictedCard)) {
      cardUsedSoFar.add(predictedCard);
    }

    // Set the action response
    actionResponse = "res-out-${stack.indexOf(predictedCard) + 1}";

    // Remove predictedCard from stack
    _removeCardFromStack(predictedCard);

    // Check if all players have played their cards
    if (deskCardCount() == 4) {
      String result = getCurrentTrickScores();
      actionResponse = "$actionResponse-$result";
    }

    onCardThrow();

    debugPrint("Action Response: $actionResponse");
  }

  String? getTrumpSuit() {
    // Bot need to say the trump if the length of stack is 4 and trumpSuit is not set
    if (stackCardCount() == 4) {
      _determineTrumpSuit();
      onSayTrumpSuit();
    }

    return trumpSuit;
  }

  String getFinalRoundScores() {
    if (ourScore > opponentScore) return "w";
    if (ourScore < opponentScore) return "l";
    return "d";
  }

  String getCurrentTrickScores() {
    _addOtherPlayedCardsToCardUsedSoFar();

    String res = "";

    List<String> winners = [];
    int maxMark = 0;

    // Find max mark
    cardsOnDesk.forEach((player, card) {
      if (card != null) {
        int mark = _cardToMark(card);
        debugPrint("Player: $player, Card: $card, Mark: $mark");
        if (mark > maxMark) {
          maxMark = mark;
        }
      }
    });

    // Collect all players with that max mark
    cardsOnDesk.forEach((player, card) {
      if (card != null && _cardToMark(card) == maxMark) {
        winners.add(player);
      }
    });

    debugPrint("Winners: $winners");

    // Decide result
    if (winners.length > 1) {
      // Draw case
      res = "d";
      debugPrint("Trick is a draw! Players: $winners");
    } else {
      String maxPlayer = winners.first;

      if (maxPlayer == "me" || maxPlayer == "infront") {
        ourScore += 1;
        res = "w";
        debugPrint("We won the trick! Score: $ourScore, Opponent Score: $opponentScore");
      } else {
        opponentScore += 1;
        res = "l";
        debugPrint("We lost the trick! Our Score: $ourScore, Opponent Score: $opponentScore");
      }
    }

    onScoreUpdate();

    // Clear cardsOnDesk
    clearDesk();

    return res;
  }

  //=============================================================

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
        String suit = getCardSuit(card);
        int value = getCardValue(card);
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
        beginSuitOfCurrentTrick = getCardSuit(cardsOnDesk[position]!);
        beginPlayerOfCurrentTrick = position;
        break;
      }
    }

    debugPrint("Begin suit of current trick: $beginSuitOfCurrentTrick, player: $beginPlayerOfCurrentTrick");
  }

  int _cardToMark(String card) {
    int value = getCardValue(card);
    String suit = getCardSuit(card);

    int mark = 0;

    mark += value;

    if (suit == trumpSuit) {
      mark += 16;
    } else if (suit == beginSuitOfCurrentTrick) {
      mark += 8;
    }

    return mark;
  }

  String getCardSuit(String card) {
    return card[card.length - 1];
  }

  int getCardValue(String card) {
    return valueOrder.indexOf(card.substring(0, card.length - 1)) + 1;
  }

  int getCardIndex(String card) {
    return labelOrder.indexOf(card);
  }

  int deskCardCount() {
    return cardsOnDesk.values.where((card) => card != null).length;
  }

  bool isCardExistsInStack(String card) {
    return stack.contains(card);
  }

  int stackCardCount() {
    return stack.where((card) => card != null).length;
  }

  void clearDesk() {
    cardsOnDesk.forEach((player, card) {
      cardsOnDesk[player] = null;
    });
  }

  void calcLocalBoardCenter(List<YOLODetection> detections) {
    final centers = _calcDistinctClassCenters(detections);
    boardCenter = Offset(centers.values.map((e) => e.dx).reduce((a, b) => a + b) / centers.length, centers.values.map((e) => e.dy).reduce((a, b) => a + b) / centers.length);
    print(boardCenter);
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
