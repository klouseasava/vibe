import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  final picker = ImagePicker();
  int vibePoints = 450;
  String userName = "Klouse Asava"; // Placeholder

  Future<void> _updatePhoto() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      // Logic for FastAPI /upload-avatar would go here
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen dimensions for adaptivity
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          // On a large screen (PC/Tablet), we constrain the width to keep it "classy"
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 500 : double.infinity,
          ),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: isLargeScreen ? 400 : 300,
                backgroundColor: Colors.black,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Profile Photo with Glow
                      GestureDetector(
                        onTap: _updatePhoto,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blueAccent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: isLargeScreen ? 100 : 80,
                            backgroundColor: Colors.grey[900],
                            backgroundImage: _image != null
                                ? FileImage(_image!)
                                : null,
                            child: _image == null
                                ? Icon(
                                    Icons.camera_alt,
                                    color: Colors.white54,
                                    size: isLargeScreen ? 50 : 40,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLargeScreen ? 34 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Technical Architect",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Points & Level Card
                      _buildGlassCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem(
                              "Points",
                              vibePoints.toString(),
                              Icons.stars,
                            ),
                            _statItem("Level", "Gold", Icons.workspace_premium),
                            _statItem("Rank", "#12", Icons.leaderboard),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      _buildSettingsTile(
                        Icons.person_outline,
                        "Account Details",
                      ),
                      _buildSettingsTile(
                        Icons.record_voice_over,
                        "Voice Shop",
                        trailing: "3 Available",
                      ),
                      _buildSettingsTile(Icons.history, "Translation History"),
                      _buildSettingsTile(
                        Icons.logout,
                        "Logout",
                        color: Colors.redAccent,
                      ),
                      // Extra padding for the bottom on long screens
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title, {
    String? trailing,
    Color color = Colors.white,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing: trailing != null
          ? Text(trailing, style: const TextStyle(color: Colors.blueAccent))
          : const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: () {
        // Handle settings navigation
      },
    );
  }
}
