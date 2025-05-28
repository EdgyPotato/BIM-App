import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'detector.dart';
import 'speechtotext.dart';
import 'settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set preferred orientations to portrait only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Language Translator',
      theme: ThemeData(
        colorSchemeSeed: Colors.grey,
        useMaterial3: true,
        brightness: Brightness.dark,
        dividerTheme: const DividerThemeData(color: Colors.transparent),
      ),
      home: const SplashScreen(),
    );
  }
}

// Splash screen to load settings
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  late AppSettings _settings;
  String _selectedPage = 'detector';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Add a slight delay to show the splash screen
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Load settings
    final settings = await AppSettings.loadSettings();

    // Update state
    setState(() {
      _settings = settings;
      _selectedPage = settings.defaultPage;
      _isLoading = false;
    });

    // If not first time, navigate to the appropriate page
    if (!_settings.isFirstTime) {
      _navigateToPage();
    }
  }

  void _navigateToPage() {
    if (!mounted) return;

    // Return user - go to their default page
    Widget page;
    switch (_settings.defaultPage) {
      case 'detector':
        page = const SignTranslator();
        break;
      case 'speechtotext':
        page = const SpeechToText();
        break;
      default:
        page = const SignTranslator();
    }

    // Replace MaterialPageRoute with PageRouteBuilder for instant transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child; // Instant transition - no animation
        },
        transitionDuration: Duration.zero, // Ensure zero duration
      ),
    );
  }

  Future<void> _saveSettingsAndNavigate() async {
    setState(() {
      _settings.defaultPage = _selectedPage;
      _settings.isFirstTime = false;
    });

    await _settings.saveSettings();

    if (!mounted) return;
    _navigateToPage();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or app name
              const Text(
                'Sign Language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Translation App',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 30),
              // Loading indicator
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      );
    }

    // First time user - show the setup UI
    if (_settings.isFirstTime) {
      // Define consistent size for choice containers
      final double containerWidth = MediaQuery.of(context).size.width * 0.8;
      final double containerHeight = 170.0;

      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choose your preferred starting feature:',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Detector option
                InkWell(
                  splashFactory:
                      NoSplash.splashFactory, // Remove highlight effect
                  onTap: () {
                    setState(() {
                      _selectedPage = 'detector';
                    });
                  },
                  child: Container(
                    width: containerWidth,
                    height: containerHeight,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            _selectedPage == 'detector'
                                ? Colors.blue
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.camera_alt, color: Colors.white, size: 50),
                        SizedBox(height: 10),
                        Text(
                          'Sign Language Detector',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Use camera to detect sign language',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Speech to text option
                InkWell(
                  splashFactory:
                      NoSplash.splashFactory, // Remove highlight effect
                  onTap: () {
                    setState(() {
                      _selectedPage = 'speechtotext';
                    });
                  },
                  child: Container(
                    width: containerWidth,
                    height: containerHeight,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            _selectedPage == 'speechtotext'
                                ? Colors.blue
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.mic, color: Colors.white, size: 50),
                        SizedBox(height: 10),
                        Text(
                          'Speech to Text',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Convert spoken words to text',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Confirm button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    // Remove splash effect from button
                    splashFactory: NoSplash.splashFactory,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                  ),
                  onPressed: _saveSettingsAndNavigate,
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Navigate to settings page if not first time but we're still here
    return const Settings();
  }
}
