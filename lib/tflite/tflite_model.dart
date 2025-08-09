import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteModel {
  Interpreter? interpreter;

  String _modelPath;

  TfliteModel({required String modelPath}) : _modelPath = modelPath;

  Future loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(_modelPath, options: InterpreterOptions()..threads = 4);
      debugPrint('Interpreter loaded successfully: $_modelPath');
    } catch (e) {
      debugPrint('Failed to load model: $e');
    }
  }

  List<int> getInputShape() {
    if (interpreter == null) {
      debugPrint('Interpreter not initialized.');
      return [];
    }
    return interpreter!.getInputTensor(0).shape;
  }

  List<int> getOutputShape() {
    if (interpreter == null) {
      debugPrint('Interpreter not initialized.');
      return [];
    }

    return interpreter!.getOutputTensor(0).shape;
  }

  void close() {
    if (interpreter != null) {
      interpreter!.close();
      interpreter = null;
      debugPrint('Interpreter closed. Model: $_modelPath');
    }
  }
}
