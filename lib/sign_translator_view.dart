import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
// Import the widget we just created
import 'package:vibe_app/widgets/sign_player.dart';

class SignTranslatorView extends StatefulWidget {
  const SignTranslatorView({super.key});

  @override
  _SignTranslatorViewState createState() => _SignTranslatorViewState();
}

class _SignTranslatorViewState extends State<SignTranslatorView> {
  CameraController? _controller;
  late PoseDetector _poseDetector;
  bool _isProcessing = false;
  String _translation = "Waiting for signs...";
  final FlutterTts _tts = FlutterTts();

  // Connected via your Wi-Fi IPv4 Address
  final channel = WebSocketChannel.connect(
    Uri.parse('ws://192.168.63.245:8000/ws/vibe/room_1'),
  );

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _setupCamera();
    _listenToBackend();
    _initTTS();
  }

  void _initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
  }

  void _setupCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras[1], // Front camera
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;

    _controller!.startImageStream((image) => _processCameraImage(image));
    setState(() {});
  }

  // --- VISION LOGIC ---

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing || _controller == null) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);

        if (poses.isNotEmpty) {
          List<Map<String, double>> landmarks = [];
          for (var pose in poses) {
            pose.landmarks.forEach((type, landmark) {
              if (type.index >= 11 && type.index <= 22) {
                landmarks.add({
                  "type": type.index.toDouble(),
                  "x": landmark.x,
                  "y": landmark.y,
                  "z": landmark.z,
                });
              }
            });
          }

          if (landmarks.isNotEmpty) {
            channel.sink.add(
              jsonEncode({
                "user_id": "current_user",
                "landmarks": landmarks,
                "timestamp": DateTime.now().millisecondsSinceEpoch,
              }),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Vision Error: $e");
    }
    _isProcessing = false;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = (sensorOrientation + 0) % 360;
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _listenToBackend() {
    channel.stream.listen((data) {
      final response = jsonDecode(data);
      final newTranslation = response['translation'] ?? "...";

      if (newTranslation != _translation && newTranslation != "Analyzing...") {
        setState(() {
          _translation = newTranslation;
        });
        _tts.speak(_translation);
      }
    }, onError: (error) => debugPrint("WS Error: $error"));
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. BACKGROUND: LIVE CAMERA PREVIEW
          Center(
            child: AspectRatio(
              aspectRatio: 1 / _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // 2. NEW FEATURE: SIGN LANGUAGE VIDEO PLAYER (Floating Window)
          // This shows the sign video for the current translation
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 140,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SignLanguagePlayer(word: _translation),
              ),
            ),
          ),

          // 3. BOTTOM OVERLAY: TEXT TRANSLATION
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "VIBE AI TRANSLATOR",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _translation.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector.close();
    channel.sink.close();
    super.dispose();
  }
}
