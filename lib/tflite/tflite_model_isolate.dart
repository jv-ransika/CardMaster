// isolate_manager.dart
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteModelIsolate {
  late Isolate _isolate;
  late SendPort _sendPort;

  late List<int> inputShape;
  late List<int> outputShape;

  final String _modelPath;

  TfliteModelIsolate({required String modelPath}) : _modelPath = modelPath;

  Future<void> start() async {
    final modelData = await rootBundle.load(_modelPath);
    final modelBytes = modelData.buffer.asUint8List();

    final readyPort = ReceivePort();
    _isolate = await Isolate.spawn(_entryPoint, [modelBytes, readyPort.sendPort]);

    List readyData = await readyPort.first;
    inputShape = readyData[0];
    outputShape = readyData[1];
    _sendPort = readyData[2];

    debugPrint('Interpreter loaded successfully: $_modelPath, $inputShape, $outputShape');
  }

  static void _entryPoint(List<dynamic> args) async {
    final modelBytes = args[0] as Uint8List;
    SendPort readyPort = args[1];

    final interpreter = Interpreter.fromBuffer(modelBytes);

    final port = ReceivePort();

    List readyData = [];
    readyData.add(interpreter.getInputTensor(0).shape);
    readyData.add(interpreter.getOutputTensor(0).shape);
    readyData.add(port.sendPort);

    readyPort.send(readyData);

    await for (var message in port) {
      final input = message[0];
      var output = generateOutputBuffer(interpreter.getOutputTensor(0).shape);

      final replyTo = message[1] as SendPort;

      interpreter.run(input, output);

      replyTo.send(output);
    }
  }

  Future<dynamic> runInference(dynamic input) async {
    final completer = Completer<dynamic>();
    final responsePort = ReceivePort();
    _sendPort.send([input, responsePort.sendPort]);
    responsePort.listen((output) {
      completer.complete(output);
      responsePort.close();
    });
    return completer.future;
  }

  void stop() {
    _isolate.kill(priority: Isolate.immediate);
  }

  static dynamic generateOutputBuffer(List<int> shape, [double fill = 0.0]) {
    if (shape.isEmpty) return fill;
    return List.generate(shape[0], (_) => generateOutputBuffer(shape.sublist(1), fill));
  }
}
