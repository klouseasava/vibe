import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:sqflite/sqflite.dart'; // Required for databaseFactory
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Required for Web DB compatibility

import 'persona_screen.dart';
import 'login_screen.dart';
import 'sign_translator_view.dart'; // IMPORTED: Your new AI Vision screen

void main() async {
  // Ensure Flutter bindings are initialized before calling native/web plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database Factory for Web/Chrome
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(
    // Wrap the app in a Provider to manage User Account data globally
    ChangeNotifierProvider(
      create: (context) => UserAccountProvider(),
      child: const VibeApp(),
    ),
  );
}

/// Helper class for Adaptive UI Scaling
class VibeResponsive {
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isTablet(BuildContext context) => width(context) > 600;
  static bool isDesktop(BuildContext context) => width(context) > 1024;

  // Calculates percentage based sizing
  static double pW(BuildContext context, double percent) =>
      width(context) * (percent / 100);
  static double pH(BuildContext context, double percent) =>
      height(context) * (percent / 100);
}

class VibeApp extends StatelessWidget {
  const VibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.blueAccent,
        // Material 3 ensures modern, adaptive components
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        // Adaptive Typography: Scales slightly based on screen size
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: VibeResponsive.isTablet(context) ? 42 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: const TextStyle(fontSize: 16, color: Colors.white70),
          bodyMedium: const TextStyle(fontSize: 14, color: Colors.white60),
        ),
        // Adaptive Button Themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
      // Auth Guard: Directs to Login or Persona Selection based on state
      home: Consumer<UserAccountProvider>(
        builder: (context, auth, _) {
          return auth.isLoggedIn
              ? const PersonaSelectionScreen()
              : const LoginScreen();
        },
      ),
      // LayoutBuilder allows the app to rebuild gracefully if window is resized
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return MediaQuery(
              // Clamps text scale factor to prevent UI breaking on system settings
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
        );
      },
    );
  }
}

/// A Classy State Manager for the User Account & Global Profile
class UserAccountProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userName = "Klouse Asava";
  int _points = 450;
  String? _profilePicPath;

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  int get points => _points;
  String? get profilePicPath => _profilePicPath;

  // Actions
  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void addPoints(int amount) {
    _points += amount;
    notifyListeners();
  }

  void updateProfilePic(String path) {
    _profilePicPath = path;
    notifyListeners();
  }

  void updateUserName(String newName) {
    _userName = newName;
    notifyListeners();
  }

  /// HELPER: UI Button to launch the AI Vision
  /// You can call this from your PersonaSelectionScreen
  Widget buildAILauncher(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignTranslatorView()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.deepPurpleAccent],
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
    );
  }
}
