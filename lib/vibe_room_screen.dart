import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class VibeRoomScreen extends StatefulWidget {
  const VibeRoomScreen({super.key});

  @override
  State<VibeRoomScreen> createState() => _VibeRoomScreenState();
}

class _VibeRoomScreenState extends State<VibeRoomScreen> {
  String roomId = "VIBE-7721"; // Generated ID
  List<String> participants = ["You (Host)", "Eph", "John"];

  void _shareRoom() {
    Share.share("Join my Vibe Room to translate together! ID: $roomId");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Vibe Group Room"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Room Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Room ID",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        roomId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _shareRoom,
                    icon: const Icon(Icons.share, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Participants List
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Connected Participants",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    participants[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.wifi,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
              ),
            ),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () {
                  // Navigate to group translation view
                },
                child: const Text("Launch Group Translation"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
