import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemChannels
import 'package:flutter/gestures.dart'; // Added for DragStartBehavior
import 'main.dart'; // Import the main.dart file to access SignTranslator
import 'speechtotext.dart'; // Import the speechtotext.dart file
import 'settings.dart'; // Import the settings.dart file

class TextTranslator extends StatefulWidget {
  const TextTranslator({super.key});

  @override
  State<TextTranslator> createState() => _TextTranslatorState();
}

class _TextTranslatorState extends State<TextTranslator> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTextEmpty = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpening = false;
  bool _preventTextInput = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        // Prevent focus when drawer is opening
        if (_isDrawerOpening && _focusNode.hasFocus) {
          _focusNode.unfocus();
        }
      });
    });
    _textController.addListener(() {
      setState(() {
        _isTextEmpty = _textController.text.isEmpty;
      });
    });
  }

  // Simplified drawer opening function
  void _handleDrawerOpen(BuildContext context) {
    // Hide keyboard and unfocus
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _preventTextInput = true);

    // Open drawer
    Scaffold.of(context).openDrawer();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
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
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset:
            false, // Prevent keyboard from pushing content up
        backgroundColor: Colors.black,
        onDrawerChanged: (isOpened) {
          // Force keyboard to stay closed
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          FocusManager.instance.primaryFocus?.unfocus();

          if (isOpened) {
            setState(() => _preventTextInput = true);
          } else {
            // When drawer closes, maintain prevention briefly
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _isDrawerOpening = false;
                  _preventTextInput = false;
                });
              }
            });
          }
        },
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
                            pageBuilder: (context, animation, secondaryAnimation) => const SignTranslator(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                            pageBuilder: (context, animation, secondaryAnimation) => const SpeechToText(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return child; // Instant transition
                            },
                          ),
                        );
                      },
                    ),
                    
                    // Translator option (current page)
                    Container(
                      color: Colors.white10,
                      child: ListTile(
                        leading: const Icon(Icons.translate, color: Colors.blue),
                        title: const Text(
                          'Translator',
                          style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Already on Translator page, just close drawer
                        },
                      ),
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
        // Enable default drag & allow dragging from anywhere
        drawerEnableOpenDragGesture: true,
        drawerEdgeDragWidth: MediaQuery.of(context).size.width,
        body: Builder(
          // Wrap body with Builder to get context for Scaffold.of
          builder: (BuildContext scaffoldContext) {
            return GestureDetector(
              // Trigger drag callbacks at pointer-down, not after slop
              dragStartBehavior: DragStartBehavior.down,
              // Hide keyboard immediately if touch down near left edge
              onPanDown: (details) {
                if (details.globalPosition.dx < 50) {
                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                  setState(() => _preventTextInput = true);
                }
              },
              onTap: () {
                // Dismiss keyboard, unfocus, and prevent text input when tapping outside
                FocusScope.of(context).unfocus();
                SystemChannels.textInput.invokeMethod('TextInput.hide');
                setState(() => _preventTextInput = true);
              },
              // Add horizontal drag handler to match other files
              onHorizontalDragUpdate: (details) {
                  // Hide keyboard and prevent text input
                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                  FocusScope.of(context).unfocus();
                  setState(() => _preventTextInput = true);

                  // Open drawer
                  Scaffold.of(scaffoldContext).openDrawer();
              },
              behavior:
                  HitTestBehavior.translucent, // Capture taps on the whole area
              child: Column(
                children: [
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
                          // Use the simplified drawer opening
                          _handleDrawerOpen(scaffoldContext);
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        // Only allow focus if we're not in a drawer operation
                        if (!_isDrawerOpening) {
                          // Enable text input when tapping inside the text area
                          setState(() => _preventTextInput = false);
                          FocusScope.of(context).requestFocus(_focusNode);
                        } else {
                          // Ensure keyboard stays hidden
                          FocusScope.of(context).unfocus();
                        }
                      },
                      // Make the hit test area exactly match the container bounds
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.topLeft,
                        color: Colors.black,
                        padding: const EdgeInsets.fromLTRB(
                          20.0,
                          20.0,
                          20.0,
                          10.0,
                        ),
                        child: Stack(
                          fit: StackFit.passthrough,
                          children: [
                            if (_isTextEmpty && !_focusNode.hasFocus)
                              const Text(
                                'Original Text Here...',
                                style: TextStyle(
                                  color: Color(0x809E9E9E),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            IgnorePointer(
                              // Completely disable text field interaction during drawer operations
                              ignoring: _preventTextInput,
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                textAlign: TextAlign.left,
                                textAlignVertical: TextAlignVertical.top,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                enableInteractiveSelection: !_preventTextInput,
                                readOnly: _preventTextInput,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      height: 3.0, // Thicker line
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(
                          160,
                          160,
                          160,
                          0.5,
                        ), // Same grey color
                        borderRadius: BorderRadius.circular(
                          1.5,
                        ), // Curved edges
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
                        'Translated Text Here...',
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
                          ),
                          onPressed: () {},
                          child: const Text(
                            'Translate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ), // Adjusted text style
                          ),
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
                          ),
                          onPressed: () {
                            // Clear the text input and unfocus
                            _textController.clear();
                            FocusScope.of(context).unfocus();
                          },
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
