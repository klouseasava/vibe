import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  List _signs = [];
  bool _isLoading = true;
  String _selectedCategory = "All";
  final TextEditingController _searchController = TextEditingController();

  // Ensure this matches your ipconfig IPv4 address
  String get backendUrl =>
      kIsWeb ? "http://localhost:8000" : "http://10.0.0.3:8000";

  @override
  void initState() {
    super.initState();
    _fetchSigns();
  }

  Future<void> _fetchSigns({String? search}) async {
    setState(() => _isLoading = true);
    try {
      String url = '$backendUrl/dictionary';
      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _signs = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Dictionary Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("KSL Dictionary"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: (val) => _fetchSigns(search: val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search signs (e.g. 'Hello')",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ["All", "Greetings", "Family", "Health", "Emergency"]
                  .map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (selected) =>
                            setState(() => _selectedCategory = cat),
                        backgroundColor: const Color(0xFF1E1E1E),
                        selectedColor: Colors.blueAccent,
                        labelStyle: TextStyle(
                          color: _selectedCategory == cat
                              ? Colors.white
                              : Colors.white60,
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Sign Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _signs.isEmpty
                ? const Center(
                    child: Text(
                      "No signs found",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: _signs.length,
                    itemBuilder: (context, index) {
                      final sign = _signs[index];
                      return _buildSignCard(sign);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignCard(Map sign) {
    return InkWell(
      onTap: () => _showVideoDialog(sign['sign_name'], sign['video_url']),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, color: Colors.blueAccent, size: 30),
            const SizedBox(height: 10),
            Text(
              sign['sign_name'].toString().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              sign['category'] ?? "General",
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoDialog(String name, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          name.toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
        content: DictionaryVideoPlayer(
          url: url.startsWith('http') ? url : '$backendUrl$url',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CLOSE",
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class DictionaryVideoPlayer extends StatefulWidget {
  final String url;
  const DictionaryVideoPlayer({super.key, required this.url});

  @override
  State<DictionaryVideoPlayer> createState() => _DictionaryVideoPlayerState();
}

class _DictionaryVideoPlayerState extends State<DictionaryVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
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
