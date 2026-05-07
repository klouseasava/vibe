// lib/widgets/sign_player.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignLanguagePlayer extends StatefulWidget {
  final String word;
  const SignLanguagePlayer({super.key, required this.word});

  @override
  State<SignLanguagePlayer> createState() => _SignLanguagePlayerState();
}

class _SignLanguagePlayerState extends State<SignLanguagePlayer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSignVideo();
  }

  @override
  void didUpdateWidget(SignLanguagePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word) {
      _loadSignVideo();
    }
  }

  Future<void> _loadSignVideo() async {
    if (widget.word.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Using your Wi-Fi IP
      final response = await http.get(
        Uri.parse(
          'http://192.168.63.245:8000/dictionary?search=${widget.word.toLowerCase()}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final videoUrl = "http://192.168.63.245:8000${data[0]['video_url']}";

          await _controller?.dispose();
          _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

          await _controller!.initialize();
          setState(() {
            _isLoading = false;
            _controller!.play();
            _controller!.setLooping(true);
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Video Load Error: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    if (_hasError) {
      return Container(
        color: Colors.black26,
        child: const Center(
          child: Text(
            "Sign not found",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
