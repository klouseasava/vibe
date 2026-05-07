import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'country_selection_screen.dart';
import 'sign_translator_view.dart'; // REQUIRED: Import the translator screen
import 'package:vibe_app/main.dart'; // Unified main import

class PersonaSelectionScreen extends StatelessWidget {
  const PersonaSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the provider for user data
    final authProvider = Provider.of<UserAccountProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep dark background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome, ${authProvider.userName.split(' ')[0]}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Choose your mode to begin.",
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- FAIL-SAFE AI VISION ACTIVATION BUTTON ---
              // If the provider method doesn't render, this hard-coded one will.
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignTranslatorView(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.deepPurpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_enhance, color: Colors.white, size: 28),
                      SizedBox(width: 15),
                      Text(
                        "ACTIVATE VIBE VISION",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white10, thickness: 1),
              const SizedBox(height: 20),

              // Persona Cards
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildPersonaCard(
                      context,
                      title: "Deaf / Hard of Hearing",
                      subtitle: "I use sign language to communicate.",
                      icon: Icons.hearing_disabled,
                      color: Colors.blueAccent,
                      onTap: () => _navigateToSetup(context, "deaf"),
                    ),
                    _buildPersonaCard(
                      context,
                      title: "Non-Verbal",
                      subtitle: "I prefer text or signs over speaking.",
                      icon: Icons.speaker_notes_off,
                      color: Colors.purpleAccent,
                      onTap: () => _navigateToSetup(context, "non-verbal"),
                    ),
                    _buildPersonaCard(
                      context,
                      title: "Hearing",
                      subtitle: "I want to translate speech into signs.",
                      icon: Icons.record_voice_over,
                      color: Colors.greenAccent,
                      onTap: () => _navigateToSetup(context, "hearing"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSetup(BuildContext context, String persona) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CountrySelectionScreen(persona: persona),
      ),
    );
  }
}
