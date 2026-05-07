import 'package:tflite_flutter/tflite_flutter.dart';

class OfflineVibeEngine {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      // Load the quantized model exported from your Python training
      _interpreter = await Interpreter.fromAsset('vibe_model_quant.tflite');
      print("Offline Brain Loaded Successfully");
    } catch (e) {
      print("Error loading offline model: $e");
    }
  }

  String predict(List<double> landmarks) {
    if (_interpreter == null) return "Engine Offline";

    // Prepare input and output buffers
    var input = [landmarks];
    var output = List.filled(
      1 * 500,
      0.0,
    ).reshape([1, 500]); // 500 possible words

    _interpreter!.run(input, output);

    // Logic to find the highest probability word and return it
    return "Habari"; // Example result
  }
}
