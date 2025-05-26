import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'translator.dart'; // Import the translator.dart file
import 'speechtotext.dart'; // Import the speechtotext.dart file
import 'settings.dart'; // Import the settings.dart file

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
      title: 'Minimalist UI',
      theme: ThemeData(
        colorSchemeSeed: Colors.grey,
        useMaterial3: true,
        brightness: Brightness.dark,
        dividerTheme: const DividerThemeData(
          color: Colors.transparent,
        ), // remove bottom line in drawerheader
      ),
      home: const SignTranslator(),
    );
  }
}

class SignTranslator extends StatelessWidget {
  const SignTranslator({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          true, // Allow app to close when back button is pressed on this screen
      child: Scaffold(
        backgroundColor: Colors.black,
        // change sidebar width size
        drawer: Drawer(
          backgroundColor: Colors.black,
          width: 0.8 * MediaQuery.of(context).size.width,
          child: Column(
            children: [
              // App Header with logo/branding
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                width: double.infinity,
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Sign Language',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Translation App',
                      style: TextStyle(
                        color: Colors.white70, 
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Divider
              const Divider(
                color: Colors.white24,
                thickness: 1,
                height: 1,
              ),
              
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    // Detector option (current page)
                    Container(
                      color: Colors.white10,
                      child: ListTile(
                        leading: const Icon(Icons.camera_alt, color: Colors.blue),
                        title: const Text(
                          'Detector',
                          style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Already on Detector page, just close drawer
                        },
                      ),
                    ),
                    
                    // Speech To Text option
                    ListTile(
                      leading: const Icon(Icons.mic, color: Colors.white),
                      title: const Text(
                        'Speech To Text',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const SpeechToText(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return child; // Instant transition
                            },
                          ),
                        );
                      },
                    ),
                    
                    // Translator option
                    ListTile(
                      leading: const Icon(Icons.translate, color: Colors.white),
                      title: const Text(
                        'Translator',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const TextTranslator(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return child; // Instant transition
                            },
                          ),
                        );
                      },
                    ),
                    
                    // Settings option
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.white),
                      title: const Text(
                        'Settings',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const Settings(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return child; // Instant transition
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Footer section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                child: Column(
                  children: [
                    const Divider(
                      color: Colors.white24,
                      thickness: 1,
                      height: 1,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.info_outline, color: Colors.white70),
                          label: const Text('About', style: TextStyle(color: Colors.white70)),
                          onPressed: () {
                            Navigator.pop(context);
                            // Show about dialog or navigate to about page
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.help_outline, color: Colors.white70),
                          label: const Text('Help', style: TextStyle(color: Colors.white70)),
                          onPressed: () {
                            Navigator.pop(context);
                            // Show help dialog or navigate to help page
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        drawerEnableOpenDragGesture: true, // Explicitly enable drag gesture
        drawerEdgeDragWidth:
            MediaQuery.of(context)
                .size
                .width, // Allow dragging from anywhere for the default gesture
        body: Builder(
          // Wrap body with Builder to get context for Scaffold.of
          builder: (BuildContext scaffoldContext) {
            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                Scaffold.of(scaffoldContext).openDrawer();
              },
              behavior:
                  HitTestBehavior.translucent, // Capture taps on the whole area
              child: Column(
                children: [
                  Container(color: Colors.black, height: 35.0),
                  Expanded(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.grey[850], // Added dark grey background
                      child: Stack(
                        // Added Stack to position the icon
                        children: [
                          const Center(
                            child: Text(
                              'Camera Placeholder',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ), // Slightly larger font
                            ),
                          ),
                          Positioned(
                            // Positioned the icon button
                            top: 5,
                            left: 10,
                            child: Builder(
                              builder:
                                  (context) => IconButton(
                                    // This context is for the icon button's Scaffold.of
                                    icon: const Icon(
                                      Icons.menu,
                                      color: Colors.white,
                                      size: 35,
                                    ),
                                    onPressed: () {
                                      // Use scaffoldContext from the Builder above for opening the main drawer
                                      Scaffold.of(scaffoldContext).openDrawer();
                                    },
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Output Text',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ), // Slightly larger font
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 30.0,
                    ), // Adjusted padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      spacing: 13.0, // Adjusted spacing
                      // Changed to spaceEvenly for better distribution
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 20,
                            ), // Added padding
                            textStyle: const TextStyle(
                              fontSize: 14,
                            ), // Adjusted text style
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const TextTranslator(),
                                transitionsBuilder: (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return child; // Instant transition
                                },
                              ),
                            );
                          },
                          child: const Text(
                            'Translate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ), // Adjusted text style
                          ),
                        ),
                        FloatingActionButton(
                          onPressed: () {},
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          child: const Icon(Icons.camera_alt, size: 30.0),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 20,
                            ), // Added padding
                            textStyle: const TextStyle(
                              fontSize: 14,
                            ), // Adjusted text style
                          ),
                          onPressed: () {},
                          child: const Text(
                            'Clear text',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ), // Adjusted text style
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
