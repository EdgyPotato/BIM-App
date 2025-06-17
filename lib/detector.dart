import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ultralytics_yolo/yolo_result.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:ultralytics_yolo/yolo_streaming_config.dart';
import 'backend/model_type.dart';
import 'backend/detector_backend.dart';
import 'backend/api_controller.dart'; // Add this import
import 'translator.dart';
import 'speechtotext.dart';
import 'settings.dart';

class SignTranslator extends StatefulWidget {
  const SignTranslator({super.key});

  @override
  State<SignTranslator> createState() => _SignTranslatorState();
}

class _SignTranslatorState extends State<SignTranslator> {
  bool _isInferenceMode = false; // Changed from _isInverted
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // YOLO Detection variables
  final _yoloController = YOLOViewController();
  final _yoloViewKey = GlobalKey<YOLOViewState>(); // Add key for YOLOView
  String? _modelPath;
  bool _isModelLoading = false;
  final ModelType _selectedModel = ModelType.detect;
  String _detectedText = 'Text will be shown here';
  late final ModelManager _modelManager;

  // Detection confirmation system
  final List<String> _confirmedDetections = [];
  String? _currentDetection;
  DateTime? _detectionStartTime;
  DateTime? _lastDetectionTime;
  bool _isWaitingForConfirmation = false;
  bool _isInEmptyPeriod = false;

  // Preset thresholds (no sliders needed)
  final double _confidenceThreshold = 0.7;
  final double _iouThreshold = 0.9;
  final int _numItemsThreshold = 2;

  bool _isReconstructing = false; // Add this variable

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    _modelManager = ModelManager(
      onDownloadProgress: (progress) {
        // Handle progress if needed
      },
      onStatusUpdate: (message) {
        // Handle status updates if needed
      },
    );

    // Preload model
    _loadModel();
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
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _loadModel() async {
    setState(() {
      _isModelLoading = true;
    });

    try {
      final modelPath = await _modelManager.getModelPath(_selectedModel);

      if (mounted) {
        setState(() {
          _modelPath = modelPath;
          _isModelLoading = false;
        });

        if (modelPath != null) {
          debugPrint('Model loaded successfully: $modelPath');

          // Apply preset thresholds to controller
          _yoloController.setThresholds(
            confidenceThreshold: _confidenceThreshold,
            iouThreshold: _iouThreshold,
            numItemsThreshold: _numItemsThreshold,
          );
        } else {
          debugPrint('Failed to load model');
        }
      }
    } catch (e) {
      debugPrint('Error loading model: $e');
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    }
  }

  Future<void> _toggleInferenceMode() async {
    if (_modelPath == null && !_isModelLoading) {
      _loadModel();
      return;
    }

    if (_isInferenceMode) {
      // Switching from YOLOView to Camera
      // Stop YOLOView and reinitialize camera
      await _stopInferenceAndStartCamera();
    } else {
      // Switching from Camera to YOLOView
      // Stop camera and start inference
      await _stopCameraAndStartInference();
    }
  }

  Future<void> _stopCameraAndStartInference() async {
    // Dispose current camera controller
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

    setState(() {
      _isCameraInitialized = false;
      _isInferenceMode = true;
      // Reset detection state when starting inference
      _resetDetectionState();
    });
  }

  Future<void> _stopInferenceAndStartCamera() async {
    setState(() {
      _isInferenceMode = false;
      // If we have detections, show that we're processing them
      if (_confirmedDetections.isNotEmpty) {
        _isReconstructing = true;
      }
    });

    // Only call API if we have confirmed detections
    if (_confirmedDetections.isNotEmpty) {
      // Get the current text from confirmed detections
      final currentText = _confirmedDetections.join(', ');

      // Call API to reconstruct text
      final reconstructedText = await ApiController.reconstructText(
        currentText,
      );

      if (mounted) {
        setState(() {
          // Use reconstructed text if available, otherwise use original text
          _detectedText = reconstructedText ?? currentText;
          _isReconstructing = false;
        });
      }
    } else {
      // If no detections, just update the text as before
      _updateDetectedText();
    }

    // Reinitialize camera
    await _initializeCamera();
  }

  void _resetDetectionState() {
    _currentDetection = null;
    _detectionStartTime = null;
    _lastDetectionTime = null;
    _isWaitingForConfirmation = false;
    _isInEmptyPeriod = false;
  }

  void _updateDetectedText() {
    if (_confirmedDetections.isEmpty) {
      _detectedText = 'Text will be shown here';
    } else {
      _detectedText = _confirmedDetections.join(', ');
    }
  }

  void _onDetectionResults(List<YOLOResult> results) {
    if (!mounted) return;

    final now = DateTime.now();

    if (results.isNotEmpty) {
      // Get the highest confidence detection
      final bestResult = results.reduce(
        (a, b) => a.confidence > b.confidence ? a : b,
      );
      final detectedClass = bestResult.className;

      _lastDetectionTime = now;

      if (_currentDetection == detectedClass) {
        // Same detection continues
        if (!_isWaitingForConfirmation && _detectionStartTime != null) {
          // Check if 2 seconds have passed for confirmation
          if (now.difference(_detectionStartTime!).inSeconds >= 2) {
            _isWaitingForConfirmation = true;

            // Add to confirmed detections (always add, even if duplicate)
            setState(() {
              _confirmedDetections.add(detectedClass);
              _updateDetectedText();
            });
          }
        }
      } else {
        // New detection - start timing immediately for any new class
        _currentDetection = detectedClass;
        _detectionStartTime = now;
        _isWaitingForConfirmation = false;
        _isInEmptyPeriod = false;
      }
    } else {
      // No detection
      if (_lastDetectionTime != null && !_isInEmptyPeriod) {
        // Check if 2 seconds have passed since last detection
        if (now.difference(_lastDetectionTime!).inMilliseconds >= 2500) {
          _isInEmptyPeriod = true;
          _currentDetection = null;
          _detectionStartTime = null;
          _isWaitingForConfirmation = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        drawer: Drawer(
          backgroundColor: Colors.black,
          width: 0.8 * MediaQuery.of(context).size.width,
          child: Column(
            children: [
              // App Header
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
                              return child;
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
                              return child;
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
                              return child;
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
                  Container(color: Colors.black, height: 35.0),
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: Colors.grey[850],
                      child: Stack(
                        children: [
                          // Conditional rendering based on inference mode
                          if (_isInferenceMode &&
                              _modelPath != null &&
                              !_isModelLoading)
                            // YOLOView for inference
                            YOLOView(
                              key: _yoloViewKey,
                              modelPath: _modelPath!,
                              task: _selectedModel.task,
                              controller: _yoloController,
                              onResult: _onDetectionResults,
                              streamingConfig: YOLOStreamingConfig.throttled(
                                maxFPS: 30,
                                includeMasks: false,
                                includeOriginalImage: false,
                              ),
                            )
                          else if (!_isInferenceMode &&
                              _isCameraInitialized &&
                              _cameraController != null)
                            // Regular camera preview
                            ClipRect(
                              child: SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width:
                                        _cameraController!
                                            .value
                                            .previewSize!
                                            .height,
                                    height:
                                        _cameraController!
                                            .value
                                            .previewSize!
                                            .width,
                                    child: CameraPreview(_cameraController!),
                                  ),
                                ),
                              ),
                            )
                          else
                            Center(
                              child: Text(
                                _isModelLoading
                                    ? 'Loading Model...'
                                    : 'Initializing Camera...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),

                          // Loading indicator
                          if (_isModelLoading)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),

                          Positioned(
                            top: 5,
                            left: 10,
                            child: Builder(
                              builder:
                                  (context) => IconButton(
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
                      child:
                          _isReconstructing
                              ? const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reconstructing text...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 20,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ],
                              )
                              : Text(
                                _detectedText,
                                style: TextStyle(
                                  color:
                                      _detectedText != 'Text will be shown here'
                                          ? Colors.white
                                          : const Color(0x809E9E9E),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                              ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
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
                            ),
                            textStyle: const TextStyle(fontSize: 14),
                            splashFactory: NoSplash.splashFactory,
                          ),
                          onPressed: () {
                            // Only pass non-empty text to translator
                            final textToTranslate =
                                _detectedText != 'Text will be shown here'
                                    ? _detectedText
                                    : '';

                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        TextTranslator(
                                          initialText: textToTranslate,
                                        ),
                                transitionsBuilder: (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return child;
                                },
                              ),
                            );
                          },
                          child: const Text(
                            'Translate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _toggleInferenceMode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isInferenceMode ? Colors.black : Colors.white,
                            foregroundColor:
                                _isInferenceMode ? Colors.white : Colors.black,
                            elevation: 0.0,
                            padding: const EdgeInsets.all(16),
                            minimumSize: const Size(60, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              side: BorderSide(
                                color:
                                    _isInferenceMode
                                        ? Colors.white
                                        : Colors.transparent,
                                width: 3.0,
                              ),
                            ),
                            splashFactory: NoSplash.splashFactory,
                          ),
                          child: const Icon(Icons.camera_alt, size: 35.0),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 20,
                            ),
                            textStyle: const TextStyle(fontSize: 14),
                            splashFactory: NoSplash.splashFactory,
                          ),
                          onPressed: () {
                            setState(() {
                              _detectedText = 'Text will be shown here';
                              _confirmedDetections.clear();
                              _resetDetectionState();
                            });
                          },
                          child: const Text(
                            'Clear text',
                            style: TextStyle(
                              fontSize: 16,
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
}
