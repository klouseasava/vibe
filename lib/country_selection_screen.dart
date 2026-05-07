import 'package:flutter/material.dart';
import 'translation_screen.dart'; // Added this import to link the camera screen

class CountrySelectionScreen extends StatefulWidget {
  final String persona;
  const CountrySelectionScreen({super.key, required this.persona});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  final List<Map<String, String>> countries = [
    {"name": "Kenya", "flag": "🇰🇪", "lang": "Kenyan Sign Language"},
    {"name": "United States", "flag": "🇺🇸", "lang": "ASL"},
    {"name": "United Kingdom", "flag": "🇬🇧", "lang": "BSL"},
    {"name": "France", "flag": "🇫🇷", "lang": "LSF"},
    {"name": "China", "flag": "🇨🇳", "lang": "CSL"},
    {"name": "Portugal", "flag": "🇵🇹", "lang": "LGP"},
    {"name": "Tanzania", "flag": "🇹🇿", "lang": "TSL"},
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    var filteredCountries = countries
        .where(
          (c) => c['name']!.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Select Country"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search your country...",
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCountries.length,
              itemBuilder: (context, index) {
                final country = filteredCountries[index];
                return ListTile(
                  leading: Text(
                    country['flag']!,
                    style: const TextStyle(fontSize: 30),
                  ),
                  title: Text(
                    country['name']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    country['lang']!,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: const Icon(
                    Icons.download_rounded,
                    color: Colors.blueAccent,
                  ),
                  onTap: () => _confirmSelection(context, country['name']!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSelection(BuildContext context, String countryName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 250,
        child: Column(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 40),
            const SizedBox(height: 16),
            Text(
              "Optimizing Vibe for $countryName",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We are downloading the local AI dictionary for high-speed translation.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () {
                  // Navigate to the live camera translation interface
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TranslationScreen(persona: widget.persona),
                    ),
                  );
                  print("Loading Main Interface for $countryName");
                },
                child: const Text(
                  "Start Translating",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
