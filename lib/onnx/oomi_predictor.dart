import 'dart:typed_data';
import 'package:card_master/onnx/onnx_model.dart';
import 'package:flutter/foundation.dart';
import 'package:onnxruntime/onnxruntime.dart';

class OomiPredictor {
  OomiPredictor();

  Future<int> predict(Int64List trumpSuitData, Int64List handData, Int64List deskData, Int64List playedData, List<bool> validActionsData, OnnxModel model) async {
    // Input: trump_suit (shape [1], type int64) -> H, D, C, S
    final trumpSuitOrt = OrtValueTensor.createTensorWithDataList(trumpSuitData, [1]);

    // Input: hand (shape [1, 8], type int64) -> index of symbol
    final handOrt = OrtValueTensor.createTensorWithDataList(handData, [1, 8]);

    // Input: desk (shape [1, 4], type int64)
    final deskOrt = OrtValueTensor.createTensorWithDataList(deskData, [1, 4]);

    // Input: played (shape [1, 32], type int64)
    final playedOrt = OrtValueTensor.createTensorWithDataList(playedData, [1, 32]);

    // Input: valid_actions (shape [1, 32], type boolean)
    final validActionsOrt = OrtValueTensor.createTensorWithDataList(validActionsData, [1, 32]);

    // Create the inputs map. The keys MUST match the model's input names.
    final inputs = {'trump_suit': trumpSuitOrt, 'hand': handOrt, 'desk': deskOrt, 'played': playedOrt, 'valid_actions': validActionsOrt};

    // Run inference
    final outputs = await model.runInference(inputs);

    // Release the input tensors
    trumpSuitOrt.release();
    handOrt.release();
    deskOrt.release();
    playedOrt.release();
    validActionsOrt.release();

    // Print the outputs
    for (var output in outputs) {
      if (output != null) {
        final nestedList = output.value as List<List<double>>;
        final flatList = nestedList.expand((inner) => inner).toList();
        debugPrint('Output: $flatList');
        output.release();
        return flatList.indexOf(1);
      } else {
        debugPrint('Output is null');
      }
    }

    return -1;
  }
}

//   Future<void> predict(OnnxModel model) async {
//     // Input: trump_suit (shape [1], type int64) -> H, D, C, S
//     final trumpSuitData = Int64List.fromList([3]); // Example: Suit '3' is trump
//     final trumpSuitShape = [1];
//     final trumpSuitOrt = OrtValueTensor.createTensorWithDataList(trumpSuitData, trumpSuitShape);

//     // Input: hand (shape [1, 8], type int64) -> index of symbol
//     final handData = Int64List.fromList([10, 14, 25, 28, 0, 0, 0, 0]); // Padded with 0
//     final handShape = [1, 8];
//     final handOrt = OrtValueTensor.createTensorWithDataList(handData, handShape);

//     // Input: desk (shape [1, 4], type int64)
//     final deskData = Int64List.fromList([5, 9, 0, 0]); // Cards on desk, padded
//     final deskShape = [1, 4];
//     final deskOrt = OrtValueTensor.createTensorWithDataList(deskData, deskShape);

//     // Input: played (shape [1, 32], type int64)
//     final playedData = Int64List(32); // Creates a list of 32 zeros
//     playedData[5] = 1; // Mark card '5' as played
//     playedData[9] = 1; // Mark card '9' as played
//     final playedShape = [1, 32];
//     final playedOrt = OrtValueTensor.createTensorWithDataList(playedData, playedShape);

//     // Input: valid_actions (shape [1, 32], type boolean)
//     final validActionsData = [List.generate(32, (i) => i == 10 || i == 14 || i == 25 || i == 28)];
//     final validActionsOrt = OrtValueTensor.createTensorWithDataList(validActionsData, [1, 32]);

//     // Create the inputs map. The keys MUST match the model's input names.
//     final inputs = {'trump_suit': trumpSuitOrt, 'hand': handOrt, 'desk': deskOrt, 'played': playedOrt, 'valid_actions': validActionsOrt};

//     // Run inference
//     final outputs = await model.runInference(inputs);

//     // Release the input tensors
//     trumpSuitOrt.release();
//     handOrt.release();
//     deskOrt.release();
//     playedOrt.release();
//     validActionsOrt.release();

//     // Print the outputs
//     for (var output in outputs) {
//       if (output != null) {
//         final nestedList = output.value as List<List<double>>;
//         final flatList = nestedList.expand((inner) => inner).toList();
//         print('Output: $flatList');
//         output.release();
//       } else {
//         print('Output is null');
//       }
//     }
//   }
// }
