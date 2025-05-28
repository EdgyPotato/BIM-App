import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'detector.dart';
import 'translator.dart';
import 'speechtotext.dart';
import 'main.dart'; // Add import for SplashScreen
import 'api_controller.dart'; // Add import for API controller

// Settings model class to handle JSON operations
class AppSettings {
  bool isFirstTime;
  String defaultPage;

  AppSettings({this.isFirstTime = true, this.defaultPage = 'detector'});

  // Create from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isFirstTime: json['isFirstTime'] ?? true,
      defaultPage: json['defaultPage'] ?? 'detector',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {'isFirstTime': isFirstTime, 'defaultPage': defaultPage};
  }

  // Get settings file path
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Get settings file
  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/settings.json');
  }

  // Save settings to file
  Future<File> saveSettings() async {
    final file = await _localFile;
    return file.writeAsString(jsonEncode(toJson()));
  }

  // Load settings from file
  static Future<AppSettings> loadSettings() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        return AppSettings.fromJson(jsonDecode(contents));
      } else {
        // First time - create default settings
        final defaultSettings = AppSettings();
        await defaultSettings.saveSettings();
        return defaultSettings;
      }
    } catch (e) {
      // If there's an error, return default settings
      return AppSettings();
    }
  }
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  String _selectedPage = 'detector';
  bool _hasChanges = false;
  bool _showAdvancedSettings = false; // Added to control dropdown visibility

  // API Status variables
  bool _isApiConnected = false;
  bool _isCheckingApi = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkApiStatus(); // Check API status when page loads
  }

  // Load settings from file
  Future<void> _loadSettings() async {
    final loadedSettings = await AppSettings.loadSettings();
    setState(() {
      _settings = loadedSettings;
      _selectedPage = _settings.defaultPage;
      _isLoading = false;
    });
  }

  // Save settings to file
  Future<void> _saveSettings() async {
    // Store if we're in reset mode before saving
    final bool resetToFirstTime = _settings.isFirstTime;

    setState(() {
      _settings.defaultPage = _selectedPage;
    });

    await _settings.saveSettings();

    // Check if widget is still mounted before using context
    if (!mounted) return;

    setState(() {
      _hasChanges = false;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // If app was reset to first-time state, immediately navigate to SplashScreen
    if (resetToFirstTime) {
      // Navigate to SplashScreen to show first-time experience
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SplashScreen()),
          );
        }
      });
    }
  }

  // Reset settings to current values from file
  void _resetSettings() {
    setState(() {
      _selectedPage = _settings.defaultPage;
      _hasChanges = false;
    });
  }

  // Reset app to first-time state
  void _resetAppToFirstTime() async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Reset App State',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will reset the app to behave as if it was newly installed. The first-time setup screen will appear immediately. Continue?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancelled
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed
              },
              child: const Text(
                'Yes, Reset',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );

    // If user confirmed, perform the reset immediately
    if (confirmed == true) {
      // Set first-time flag
      _settings.isFirstTime = true;

      // Save settings immediately
      await _settings.saveSettings();

      // Check if still mounted
      if (!mounted) return;

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App reset to first launch state'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait briefly for snackbar to be visible
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to SplashScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    }
  }

  // Check API status
  Future<void> _checkApiStatus() async {
    setState(() {
      _isCheckingApi = true;
    });

    final isConnected = await ApiController.checkApiStatus();

    setState(() {
      _isApiConnected = isConnected;
      _isCheckingApi = false;
    });
  }

  // Navigate to the appropriate page
  void _navigateToPage(BuildContext context) {
    Widget page;

    // Determine which page to navigate to
    switch (_selectedPage) {
      case 'detector':
        page = const SignTranslator();
        break;
      case 'speechtotext':
        page = const SpeechToText();
        break;
      default:
        page = const SignTranslator();
    }

    // Navigate to the selected page
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child; // Instant transition
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          _navigateToPage(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        drawer: _buildDrawer(context),
        drawerEnableOpenDragGesture: true,
        drawerEdgeDragWidth: MediaQuery.of(context).size.width,
        body: Builder(
          builder: (BuildContext scaffoldContext) {
            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                Scaffold.of(scaffoldContext).openDrawer();
              },
              behavior: HitTestBehavior.translucent,
              child: Column(
                children: [
                  // App bar with menu button
                  Container(
                    color: Colors.black,
                    height: 35.0,
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(top: 40.0, bottom: 10.0),
                    padding: const EdgeInsets.only(left: 10.0),
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

                  // Page title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Settings content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Default Page',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Radio buttons for default page selection
                          RadioListTile<String>(
                            title: const Text(
                              'Detector',
                              style: TextStyle(color: Colors.white),
                            ),
                            value: 'detector',
                            groupValue: _selectedPage,
                            activeColor: Colors.blue,
                            onChanged: (value) {
                              setState(() {
                                _selectedPage = value!;
                                _hasChanges =
                                    _selectedPage != _settings.defaultPage;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text(
                              'Speech To Text',
                              style: TextStyle(color: Colors.white),
                            ),
                            value: 'speechtotext',
                            groupValue: _selectedPage,
                            activeColor: Colors.blue,
                            onChanged: (value) {
                              setState(() {
                                _selectedPage = value!;
                                _hasChanges =
                                    _selectedPage != _settings.defaultPage;
                              });
                            },
                          ),

                          const SizedBox(height: 20),
                          const Text(
                            'When the app starts, it will open the selected page by default.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 30),

                          // API Status Section
                          Row(
                            children: [
                              const Text(
                                'API Status: ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _isApiConnected ? 'Connected' : 'Disconnected',
                                style: TextStyle(
                                  color: _isApiConnected ? Colors.green : Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: _isCheckingApi
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.refresh, color: Colors.white),
                                onPressed: _isCheckingApi ? null : _checkApiStatus,
                                tooltip: 'Refresh API status',
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Divider(color: Colors.white24, thickness: 1),
                          const SizedBox(height: 10),

                          // Advanced Settings Section
                          InkWell(
                            splashFactory:
                                NoSplash.splashFactory, // Remove highlight effect
                            onTap: () {
                              setState(() {
                                _showAdvancedSettings = !_showAdvancedSettings;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Advanced Settings',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    _showAdvancedSettings
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Expandable advanced settings content
                          if (_showAdvancedSettings)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Debug Options',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        const Text(
                                          'These options are for development and troubleshooting purposes.',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 15),

                                        // Reset to first-time state button
                                        ElevatedButton.icon(
                                          onPressed: _resetAppToFirstTime,
                                          icon: const Icon(Icons.restart_alt),
                                          label: const Text(
                                            'Reset App to First Launch State',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[800],
                                            foregroundColor: Colors.white,
                                            splashFactory:
                                                NoSplash.splashFactory, // Remove splash effect
                                            shadowColor: Colors.transparent,
                                            elevation: 0,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'This will reset the app to behave as if it was newly installed. The first-time setup screen will appear on next launch.',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Buttons for Save and Reset
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 30.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _hasChanges ? Colors.blue : Colors.white,
                            foregroundColor:
                                _hasChanges ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 20,
                            ),
                          ),
                          onPressed: _hasChanges ? _saveSettings : null,
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasChanges
                                ? Colors.white
                                : Colors.grey.shade800,
                            foregroundColor:
                                _hasChanges ? Colors.black : Colors.grey,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 20,
                            ),
                          ),
                          onPressed: _hasChanges ? _resetSettings : null,
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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

  // Drawer widget
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
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
                // Detector option
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text(
                    'Detector',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                const SignTranslator(),
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
                ),

                // Settings option (current page)
                Container(
                  color: Colors.white10,
                  child: ListTile(
                    leading: const Icon(Icons.settings, color: Colors.blue),
                    title: const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Already on Settings page, just close drawer
                    },
                  ),
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
                const Divider(color: Colors.white24, thickness: 1, height: 1),
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
    );
  }
}
