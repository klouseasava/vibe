import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb

class CommunityReviewScreen extends StatefulWidget {
  const CommunityReviewScreen({super.key});

  @override
  State<CommunityReviewScreen> createState() => _CommunityReviewScreenState();
}

class _CommunityReviewScreenState extends State<CommunityReviewScreen> {
  List pendingSigns = [];
  bool isLoading = true;
  int userPoints = 0;

  // Uses localhost for Web/Chrome and local IP for physical mobile devices
  String get backendUrl =>
      kIsWeb ? "http://localhost:8000" : "http://192.168.1.100:8000";

  @override
  void initState() {
    super.initState();
    _fetchPendingSigns();
    _fetchUserStats();
  }

  Future<void> _fetchUserStats() async {
    // Simulated fetch
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return; // Prevent crash if user navigated away
    setState(() {
      userPoints = 450;
    });
  }

  Future<void> _fetchPendingSigns() async {
    final url = Uri.parse('$backendUrl/pending_signs');
    try {
      final response = await http.get(url);
      if (!mounted) return; // Safety check

      if (response.statusCode == 200) {
        setState(() {
          pendingSigns = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching signs: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _verifySign(String signId) async {
    final url = Uri.parse('$backendUrl/verify/$signId?verifier_id=user_456');
    try {
      final response = await http.post(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!kIsWeb && await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(
            pattern: [0, 100, 50, 100],
            intensities: [0, 128, 0, 255],
          );
        }

        setState(() {
          userPoints += 10;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${data['message']} +10 Vibe Points!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchPendingSigns();
      }
    } catch (e) {
      debugPrint("Verification failed: $e");
    }
  }

  void _showSignVideo(String videoUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Verify Gesture",
          style: TextStyle(color: Colors.white),
        ),
        content: SignVideoPlayer(url: videoUrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Community Review"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingSigns,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$userPoints Vibe Points",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      "Earn 50 more to unlock a new AI voice",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  )
                : pendingSigns.isEmpty
                ? const Center(
                    child: Text(
                      "No signs pending review!",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: pendingSigns.length,
                    itemBuilder: (context, index) {
                      final sign = pendingSigns[index];
                      int count = sign['verification_count'] ?? 0;
                      double progress = (count / 100).clamp(0.0, 1.0);

                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  sign['sign_name'].toString().toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "Dialect: ${sign['country']}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                trailing: Text(
                                  "$count/100",
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.white10,
                                  color: progress >= 1.0
                                      ? Colors.greenAccent
                                      : Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      _showSignVideo(
                                        sign['video_url'] ??
                                            "https://example.com/demo.mp4",
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.orange,
                                    ),
                                    label: const Text(
                                      "Watch Sign",
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _verifySign(sign['_id']),
                                    child: const Text("Legible (Verify)"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

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
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
