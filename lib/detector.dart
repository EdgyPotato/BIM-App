import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'translator.dart'; // Import the translator.dart file
import 'speechtotext.dart'; // Import the speechtotext.dart file
import 'settings.dart'; // Import the settings.dart file

class SignTranslator extends StatefulWidget {
  const SignTranslator({super.key});

  @override
  State<SignTranslator> createState() => _SignTranslatorState();
}

class _SignTranslatorState extends State<SignTranslator> {
  bool _isInverted = false;
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _cameraController = CameraController(
        _cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _toggleButtonState() {
    setState(() {
      _isInverted = !_isInverted;
    });
  }

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
                padding: const EdgeInsets.symmetric(
                  vertical: 40.0,
                  horizontal: 20.0,
                ),
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
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),

              // Divider
              const Divider(color: Colors.white24, thickness: 1, height: 1),

              // Navigation Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    // Detector option (current page)
                    Container(
                      color: Colors.white10,
                      child: ListTile(
                        leading: const Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                        ),
                        title: const Text(
                          'Detector',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const SpeechToText(),
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
                        Navigator.push(
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
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const Settings(),
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
                    ),
                  ],
                ),
              ),

              // Footer section
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 20.0,
                ),
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
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.white70,
                          ),
                          label: const Text(
                            'About',
                            style: TextStyle(color: Colors.white70),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            // Show about dialog or navigate to about page
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(
                            Icons.help_outline,
                            color: Colors.white70,
                          ),
                          label: const Text(
                            'Help',
                            style: TextStyle(color: Colors.white70),
                          ),
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
                      color: Colors.grey[850],
                      child: Stack(
                        children: [
                          // Camera preview with ClipRect to cut off instead of resize
                          if (_isCameraInitialized && _cameraController != null)
                            ClipRect(
                              child: SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _cameraController!.value.previewSize!.height,
                                    height: _cameraController!.value.previewSize!.width,
                                    child: CameraPreview(_cameraController!),
                                  ),
                                ),
                              ),
                            )
                          else
                            const Center(
                              child: Text(
                                'Initializing Camera...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          Positioned(
                            top: 5,
                            left: 10,
                            child: Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(
                                  Icons.menu,
                                  color: Colors.white,
                                  size: 35,
                                ),
                                onPressed: () {
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
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.fromLTRB(
                        20.0,
                        20.0,
                        20.0,
                        10.0,
                      ),
                      child: const Text(
                        'Text will be shown here',
                        style: TextStyle(
                          color: Color(0x809E9E9E), // Barely visible grey
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 30.0,
                    ), // Adjusted padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      // Changed to spaceEvenly for better distribution
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 20,
                            ), // Added padding
                            textStyle: const TextStyle(
                              fontSize: 14,
                            ), // Adjusted text style
                            splashFactory: NoSplash.splashFactory, // Add NoSplash here
                          ),
                          onPressed: () {
                            Navigator.push(
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
                        ElevatedButton(
                          onPressed: _toggleButtonState,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isInverted ? Colors.black : Colors.white,
                            foregroundColor: _isInverted ? Colors.white : Colors.black,
                            elevation: 0.0, // Remove floating effect
                            padding: const EdgeInsets.all(16),
                            minimumSize: const Size(60, 60), // Slightly larger to make it more prominent
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              side: BorderSide(
                                color: _isInverted ? Colors.white : Colors.transparent,
                                width: 3.0,
                              ),
                            ),
                            splashFactory: NoSplash.splashFactory,
                          ),
                          child: const Icon(Icons.camera_alt, size: 35.0), // Slightly larger icon
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 20,
                            ), // Added padding
                            textStyle: const TextStyle(
                              fontSize: 14,
                            ), // Adjusted text style
                            splashFactory: NoSplash.splashFactory, // Add NoSplash here
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
