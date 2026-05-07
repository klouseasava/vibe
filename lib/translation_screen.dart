import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // NEW: AI Speech
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:video_player/video_player.dart'; // NEW: To see signs

import 'community_review_screen.dart';
import 'sync_db.dart';
import 'sync_manager.dart';
import 'vibe_room_screen.dart';

class TranslationScreen extends StatefulWidget {
  final String persona;
  const TranslationScreen({super.key, required this.persona});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  // Existing state variables
  List<CameraDescription>? cameras;
  CameraController? controller;
  bool isFrontCamera = true;
  String translatedText = "Waiting for signs...";
  int _selectedIndex = 0;
  bool _isOffline = false;
  int _vibePoints = 0;
  bool _isListening = false;

  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VibeSyncManager _syncManager = VibeSyncManager();

  // UPDATED: Using your local Wi-Fi IP address
  String get backendUrl =>
      kIsWeb ? "http://localhost:8000" : "http://10.0.0.3:8000";

  @override
  void initState() {
    super.initState();
    _initWebDatabase();
    _setupCamera();
    _initTTS();
    _initConnectivity();
    _loadUserPoints();
  }

  // --- NEW: AI VOICE PROCESSING & READY SOUND ---

  Future<void> _playReadySound() async {
    // Set pitch to 0.1 for a deep, bassy tone
    await flutterTts.setPitch(0.1);
    await flutterTts.setSpeechRate(0.8);
    // "Ohm" or "Uhm" at low pitch creates a resonant deep sound
    await flutterTts.speak("Ohm");

    _triggerHapticFeedback(isHeavy: true);

    // Brief delay to allow sound to finish before resetting for normal speech
    await Future.delayed(const Duration(milliseconds: 600));
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  void _startListening() async {
    // Play the deep sound cue before starting the mic
    await _playReadySound();

    bool available = await _speech.initialize();
    if (available) {
      if (!mounted) return;
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          if (!mounted) return;
          setState(() {
            translatedText = val.recognizedWords;
            if (val.finalResult) {
              _isListening = false;
              _processVoiceInput(val.recognizedWords); // Trigger AI Search
            }
          });
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _processVoiceInput(String text) async {
    if (text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/translate/text-to-sign'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text, "country": "Kenya"}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // SAFETY: Check if the user is still on the screen before proceeding
        if (!mounted) return;

        if (data['found'] && data['videos'].isNotEmpty) {
          // Show the AI-mapped sign video
          _showSignResponse(
            data['videos'][0],
            data['interpretation'].join(" "),
          );
        }
      }
    } catch (e) {
      debugPrint("AI Search Error: $e");
    }
  }

  void _showSignResponse(String videoUrl, String interpretation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          "Vibe Sign: $interpretation",
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          height: 250,
          child: SignVideoPlayer(url: '$backendUrl$videoUrl'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // --- CAMERA & SYSTEM LOGIC (UNTOUCHED) ---

  Future<void> _initWebDatabase() async {
    if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  void _triggerHapticFeedback({bool isHeavy = false}) async {
    if (kIsWeb) return;
    if (await Vibration.hasVibrator() ?? false) {
      isHeavy
          ? Vibration.vibrate(duration: 150)
          : Vibration.vibrate(duration: 50);
    }
  }

  void _loadUserPoints() {
    setState(() => _vibePoints = 450);
  }

  void _initConnectivity() {
    _syncManager.startListening(backendUrl);
    Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(
        () => _isOffline =
            results.isEmpty || results.contains(ConnectivityResult.none),
      );
    });
  }

  Future<void> _setupCamera() async {
    try {
      if (!kIsWeb) await Permission.camera.request();
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) _initializeBestCamera();
    } catch (e) {
      debugPrint("Camera Setup Error: $e");
    }
  }

  void _initializeBestCamera() {
    CameraDescription selected = cameras!.firstWhere(
      (cam) =>
          cam.lensDirection ==
          (isFrontCamera
              ? CameraLensDirection.front
              : CameraLensDirection.back),
      orElse: () => cameras![0],
    );
    _initController(selected);
  }

  void _initController(CameraDescription camera) async {
    if (controller != null) await controller!.dispose();
    controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller!.initialize();
    if (mounted) setState(() {});
  }

  void _toggleCamera() {
    setState(() {
      isFrontCamera = !isFrontCamera;
      _initializeBestCamera();
    });
    _triggerHapticFeedback();
  }

  // --- ACTIONS ---

  Future<void> _handleSpeak() async {
    if (translatedText.isNotEmpty && translatedText != "Waiting for signs...") {
      _triggerHapticFeedback(isHeavy: true);
      await flutterTts.speak(translatedText);
    }
  }

  void _handleClear() {
    _triggerHapticFeedback();
    setState(() => translatedText = "Waiting for signs...");
  }

  Future<void> _handleEducate() async {
    _triggerHapticFeedback();
    String signName = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Educate Vibe",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Word for this sign",
            hintStyle: TextStyle(color: Colors.white54),
          ),
          onChanged: (value) => signName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processEducateSubmission(signName);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  Future<void> _processEducateSubmission(String name) async {
    if (name.isEmpty) return;
    final landmarks = [
      {"x": 0.5, "y": 0.5, "z": 0.0},
    ];
    if (_isOffline) {
      await SyncDatabase.instance.queueSign({
        "sign_name": name,
        "country": "Kenya",
        "landmarks_json": jsonEncode(landmarks),
        "created_at": DateTime.now().toIso8601String(),
      });
      _showVibeSnackBar("Offline: Queued.", Colors.orange);
    } else {
      _submitToBackend(name, landmarks);
    }
  }

  Future<void> _submitToBackend(String name, List landmarks) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/educate'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": "vibe_user_001",
          "sign_name": name,
          "country": "Kenya",
          "landmarks": landmarks,
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() => _vibePoints += 50);
        _showVibeSnackBar("Success! +50 pts.", Colors.green);
      }
    } catch (e) {
      _showVibeSnackBar("Server error.", Colors.redAccent);
    }
  }

  void _showVibeSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    flutterTts.stop();
    super.dispose();
  }

  // --- UI BUILDING ---

  Widget _buildCameraInterface(BoxConstraints constraints) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    bool isTablet = constraints.maxWidth > 600;

    return Stack(
      children: [
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller!.value.previewSize!.height,
              height: controller!.value.previewSize!.width,
              child: CameraPreview(controller!),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                        ),
                        onPressed: _toggleCamera,
                      ),
                    ),
                    _buildPointsIndicator(),
                    _buildConnectionStatus(isTablet),
                  ],
                ),
              ),
              _buildTranslationOverlay(isTablet, constraints),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPointsIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 18),
          const SizedBox(width: 6),
          Text(
            "$_vibePoints pts",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(bool isTablet) {
    return Icon(
      _isOffline ? Icons.cloud_off : Icons.cloud_done,
      color: _isOffline ? Colors.orange : Colors.green,
      size: 24,
    );
  }

  Widget _buildTranslationOverlay(bool isTablet, BoxConstraints constraints) {
    return Center(
      child: Container(
        width: isTablet
            ? constraints.maxWidth * 0.6
            : constraints.maxWidth * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              translatedText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isListening ? Colors.blueAccent : Colors.white,
                fontSize: isTablet ? 34 : 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(
                  Icons.edit,
                  "Educate",
                  Colors.orange,
                  _handleEducate,
                  isTablet,
                ),
                _actionButton(
                  _isListening ? Icons.mic : Icons.mic_none,
                  _isListening ? "Listening" : "Listen",
                  _isListening ? Colors.redAccent : Colors.blueAccent,
                  _isListening ? _stopListening : _startListening,
                  isTablet,
                ),
                _actionButton(
                  Icons.volume_up,
                  "Speak",
                  Colors.green,
                  _handleSpeak,
                  isTablet,
                ),
                _actionButton(
                  Icons.refresh,
                  "Clear",
                  Colors.grey,
                  _handleClear,
                  isTablet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final List<Widget> pages = [
          _buildCameraInterface(constraints),
          const CommunityReviewScreen(),
          const VibeRoomScreen(),
        ];
        return Scaffold(
          backgroundColor: Colors.black,
          body: pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF1E1E1E),
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.white54,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              _triggerHapticFeedback();
              setState(() => _selectedIndex = index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.translate),
                label: 'Translate',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.hub_outlined),
                label: 'Room',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    bool isTablet,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: isTablet ? 40 : 30,
            child: Icon(icon, color: Colors.white, size: isTablet ? 36 : 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: isTablet ? 16 : 12),
          ),
        ],
      ),
    );
  }
}

// Helper to play the response video
class SignVideoPlayer extends StatefulWidget {
  final String url;
  const SignVideoPlayer({super.key, required this.url});
  @override
  State<SignVideoPlayer> createState() => _SignVideoPlayerState();
}

class _SignVideoPlayerState extends State<SignVideoPlayer> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) => _controller.value.isInitialized
      ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
      : const Center(child: CircularProgressIndicator());
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
