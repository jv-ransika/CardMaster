import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

class OnnxModel {
  final String modelPath;
  OrtSession? session;

  OnnxModel({required this.modelPath});

  Future<void> loadModel() async {
    try {
      final modelData = await rootBundle.load(modelPath);
      final modelBytes = modelData.buffer.asUint8List();

      final options = OrtSessionOptions();
      session = OrtSession.fromBuffer(modelBytes, options);
      debugPrint('ONNX model loaded successfully: $modelPath');
    } catch (e) {
      debugPrint('Failed to load ONNX model: $e');
    }
  }

  Future<List<OrtValue?>> runInference(Map<String, OrtValue> inputs) async {
    if (session == null) {
      debugPrint('Session is not initialized.');
      return [];
    }

    final runOptions = OrtRunOptions();
    
    final outputs = session!.run(runOptions, inputs);

    runOptions.release();

    return outputs;
  }

  void inspectModel() {
    debugPrint('Inspecting model...');

    // Get input details
    final inputNames = session!.inputNames;
    debugPrint('Inputs:');
    for (int i = 0; i < inputNames.length; i++) {
      debugPrint('  Input $i: name=${inputNames[i]}');
    }

    // Get output details
    final outputNames = session!.outputNames;
    debugPrint('Outputs:');
    for (int i = 0; i < outputNames.length; i++) {
      debugPrint('  Output $i: name=${outputNames[i]}');
    }
  }

  void close() {
    if (session != null) {
      session!.release();
      debugPrint('Session released. Model: $modelPath');
    }
  }
}
