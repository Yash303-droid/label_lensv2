import 'dart:convert';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:image_picker/image_picker.dart';

import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/dashed_border_painter.dart';

import 'dart:math' as math;
import 'package:label_lensv2/dotted_background.dart';
import 'package:label_lensv2/mock_data_service.dart';
import 'package:label_lensv2/neopop_button.dart';


class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  ScanScreenState createState() => ScanScreenState();
}

class ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  String _scanState = 'idle'; // idle, processing, error, result
  String _activeMode = 'camera'; // 'camera' or 'gallery' (sub-state of idle)
  late final AnimationController _idleScanAnimationController;
  late final AnimationController _processingScanAnimationController;
  late final AnimationController _bounceAnimationController;
  late final AnimationController _pulseAnimationController;
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _idleScanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _processingScanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _bounceAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      reverseDuration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (_activeMode == 'camera') {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // Ensure the previous controller is disposed
    await _cameraController?.dispose();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras found on this device.')));
        }
        return;
      }
      final firstCamera = cameras.first;

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      _initializeControllerFuture = _cameraController!.initialize();
      if (mounted) setState(() {});
    } on CameraException catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error initializing camera: ${e.description}')));
      }
    }
  }

  @override
  void dispose() {
    _idleScanAnimationController.dispose();
    _processingScanAnimationController.dispose();
    _bounceAnimationController.dispose();
    _pulseAnimationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _resetState() {
    setState(() {
      _scanState = 'idle';
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_scanState) {
      case 'processing':
        return _buildProcessingState();
      case 'error':
        return _buildErrorState();
      case 'result':
        return _buildResultState();
      case 'idle':
      default:
        return _buildIdleState(context);
    }
  }

  Widget _buildIdleState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final background = _activeMode == 'camera'
        ? const SizedBox.shrink() // Camera view provides its own background
        : DottedBackground(child: Container());

    return Scaffold(
      backgroundColor: _activeMode == 'camera' ? AppColors.slate900 : (isDarkMode ? AppColors.slate900 : AppColors.slate50),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: background),
          if (_activeMode == 'camera') _buildCameraMode(context, isDarkMode) else _buildGalleryMode(context, isDarkMode),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            child: _buildModeSwitcher(context, isDarkMode),
          ),
        ],
      ),
    );
  }

  Future<void> startProcessing() async {
    if (_scanState == 'processing') return;

    XFile? image;

    if (_activeMode == 'camera') {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera is not ready.')));
        }
        return;
      }

      try {
        if (_cameraController!.value.isTakingPicture) {
          return;
        }
        image = await _cameraController!.takePicture();
        debugPrint('Picture saved to ${image.path}');
      } on CameraException catch (e) {
        debugPrint('Error taking picture: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error taking picture: ${e.description}')));
        }
        return;
      }
    } else { // Gallery Mode
      try {
        final ImagePicker picker = ImagePicker();
        image = await picker.pickImage(source: ImageSource.gallery);
        if (image == null) return; // User canceled picker
        debugPrint('Image picked from gallery: ${image.path}');
      } catch (e) {
        debugPrint('Error picking image from gallery: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick image.')));
        }
        return;
      }
    }

    if (image != null) {
      await _extractTextFromImage(image);

      setState(() => _scanState = 'processing');
      // For demo, switch to result after a few seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _scanState == 'processing') {
          setState(() => math.Random().nextDouble() > 0.8 ? _scanState = 'error' : _scanState = 'result');
        }
      });
    }
  }

  Future<void> _extractTextFromImage(XFile image) async {
    try {
      final textRecognizer = TextRecognizer();
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      String fullText = recognizedText.text.toLowerCase();
      List<String> ingredientsList = [];

      // A simple heuristic to find the ingredients list
      const ingredientsKeyword = 'ingredients';
      int keywordIndex = fullText.indexOf(ingredientsKeyword);

      if (keywordIndex != -1) {
        String ingredientsBlock = fullText.substring(keywordIndex + ingredientsKeyword.length);

        // Clean up the start of the block (remove ':', ' ', etc.)
        ingredientsBlock = ingredientsBlock.trim().replaceFirst(RegExp(r'^[:\s]+'), '');

        // Assume ingredients end with a period.
        int endOfListIndex = ingredientsBlock.indexOf('.');
        if (endOfListIndex != -1) {
          ingredientsBlock = ingredientsBlock.substring(0, endOfListIndex);
        }

        // Remove content in parentheses (like percentages) and other unwanted characters
        ingredientsBlock = ingredientsBlock.replaceAll(RegExp(r'\([^)]*\)'), '');

        ingredientsList =
            ingredientsBlock.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }

      final Map<String, dynamic> jsonOutput = {
        'ingredients': ingredientsList,
      };
      final String jsonString = jsonEncode(jsonOutput);

      debugPrint('--- EXTRACTED TEXT AS JSON ---');
      debugPrint(jsonString);
      debugPrint('------------------------------');
    } catch (e) {
      debugPrint('Error during text recognition: $e');
    }
  }

  Widget _buildModeSwitcher(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.indigo950 : AppColors.slate800,
        borderRadius: BorderRadius.circular(16),
        border: AppStyles.getBorder(true, width: 2), // Always black border
        boxShadow: [AppStyles.getShadow(true, offset: 4)], // Always black shadow
      ),
      child: Row(
        children: [
          _buildModeToggle(context, isDarkMode, 'CAMERA'),
          const SizedBox(width: 8),
          _buildModeToggle(context, isDarkMode, 'GALLERY'),
        ],
      ),
    );
  }

  Widget _buildModeToggle(BuildContext context, bool isDarkMode, String mode) {
    final isActive = _activeMode == mode.toLowerCase();
    return GestureDetector(
      onTap: () {
        final newMode = mode.toLowerCase();
        if (_activeMode == newMode) return;

        setState(() {
          _activeMode = newMode;
          if (newMode == 'camera') {
            _initializeCamera();
          } else {
            _cameraController?.dispose();
            _cameraController = null;
            _initializeControllerFuture = null;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.indigo400 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? AppStyles.getBorder(isDarkMode, width: 2) : null,
          boxShadow: isActive ? [AppStyles.getShadow(isDarkMode, offset: 2)] : [],
        ),
        child: Text(
          mode,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: isActive ? AppColors.slate900 : AppColors.slate300,
          ),
        ),
      ),
    );
  }

  Widget _buildCameraMode(BuildContext context, bool isDarkMode) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !(_cameraController?.value.isInitialized ?? false)) {
          return Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return LayoutBuilder(builder: (context, constraints) {
          final viewFinderSize = const Size(288, 288);
          final center = constraints.biggest.center(Offset.zero);
          final viewFinderRect = Rect.fromCenter(
            center: center,
            width: viewFinderSize.width,
            height: viewFinderSize.height,
          );

          return Stack(
            children: [
              Positioned.fill(child: CameraPreview(_cameraController!)),
              Positioned.fill(
                child: ClipPath(
                  clipper: _InvertedRRectClipper(
                    rect: viewFinderRect,
                    radius: const Radius.circular(24),
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: viewFinderRect,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.indigo400, width: 4),
                    boxShadow: [
                      BoxShadow(color: AppColors.indigo400.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _ScanningLineAnimation(controller: _idleScanAnimationController, fromTop: -1.0, toTop: 1.0),
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildGalleryMode(BuildContext context, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: isDarkMode ? AppColors.slate600 : AppColors.slate300,
            strokeWidth: 4,
            radius: const Radius.circular(32),
            dashWidth: 15,
            dashSpace: 10,
          ),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.slate800 : AppColors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [AppStyles.getShadow(isDarkMode, offset: 8)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: -3 * (math.pi / 180),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.indigo900 : AppColors.indigo300,
                      borderRadius: BorderRadius.circular(16),
                      border: AppStyles.getBorder(isDarkMode, width: 2),
                      boxShadow: [AppStyles.getShadow(isDarkMode, offset: 4)],
                    ),
                    child: Icon(Icons.cloud_upload_outlined, size: 48, color: isDarkMode ? AppColors.slate50 : AppColors.slate900),
                  ),
                ),
                const SizedBox(height: 24),
                Text('IMPORT PHOTO', style: AppStyles.heading1.copyWith(fontSize: 24, color: isDarkMode ? AppColors.white : AppColors.slate900)),
                const SizedBox(height: 8),
                Text(
                  'Upload an image of a food label from your gallery.',
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyBold.copyWith(color: isDarkMode ? AppColors.slate300 : AppColors.slate600),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: NeopopButton(
                    onPressed: startProcessing,
                    color: AppColors.indigo500,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_outlined, color: AppColors.white),
                          const SizedBox(width: 12),
                          Text('Open Gallery', style: AppStyles.buttonText),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
    backgroundColor: isDarkMode ? AppColors.indigo950 : AppColors.indigo50,
    body: DottedBackground(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProcessingCard(isDarkMode),
            const SizedBox(height: 32),
            Text(
              'READING IMAGE',
              style: AppStyles.heading1.copyWith(color: isDarkMode ? AppColors.white : AppColors.slate900),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyzing ingredients and nutritional data...',
              style: AppStyles.bodyBold.copyWith(color: isDarkMode ? AppColors.slate300 : AppColors.slate600),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildResultState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final result = mockScanResult;
    final statusColor = result['overallStatus'] == 'danger' ? AppColors.rose500 : AppColors.emerald500;

    return Scaffold(
    backgroundColor: isDarkMode ? AppColors.slate900 : AppColors.slate50,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : AppColors.slate900),
        onPressed: _resetState,
      ),
      title: Text('SCAN RESULT', style: AppStyles.heading1.copyWith(fontSize: 18)),
      centerTitle: true,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.slate800 : AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: AppStyles.getBorder(isDarkMode, width: 3),
              boxShadow: [AppStyles.getShadow(isDarkMode, offset: 6)],
            ),
            child: Column(
              children: [
                Text(result['productName'] as String, style: AppStyles.heading1.copyWith(fontSize: 24)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                    border: AppStyles.getBorder(true, width: 2),
                  ),
                  child: Text(
                    (result['summary'] as String).toUpperCase(),
                    style: AppStyles.bodyBold.copyWith(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('DIETARY TAGS', style: AppStyles.heading1.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (result['dietaryTags'] as List).map((tag) {
              final color = tag['color'] == 'rose' ? AppColors.rose400 : (tag['color'] == 'amber' ? AppColors.amber300 : AppColors.emerald400);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: AppStyles.getBorder(isDarkMode, width: 2),
                ),
                child: Text(tag['label'], style: AppStyles.bodyBold.copyWith(color: AppColors.slate900, fontSize: 12)),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text('INGREDIENTS ANALYSIS', style: AppStyles.heading1.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          ... (result['ingredients'] as List).map((ing) {
            final ingColor = ing['status'] == 'danger' ? AppColors.rose400 : (ing['status'] == 'warning' ? AppColors.amber300 : AppColors.emerald400);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.slate800 : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ingColor, width: 2),
              ),
              child: Row(
                children: [
                  Icon(ing['isVegan'] ? Icons.eco : Icons.kebab_dining, color: ingColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ing['name'], style: AppStyles.bodyBold),
                        Text(ing['description'], style: AppStyles.bodyBold.copyWith(fontSize: 12, fontWeight: FontWeight.normal)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ),
  );
  }

  Widget _buildProcessingCard(bool isDarkMode) {
    return Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.center,
    children: [
      Container(
        width: 192,
        height: 256,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.slate800 : AppColors.white,
          borderRadius: BorderRadius.circular(32),
          border: AppStyles.getBorder(isDarkMode, width: 4),
          boxShadow: [AppStyles.getShadow(isDarkMode, offset: 8)],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSkeletonLine(isDarkMode, widthFactor: 0.75),
                _buildSkeletonLine(isDarkMode, widthFactor: 1.0),
                _buildSkeletonLine(isDarkMode, widthFactor: 0.85),
                _buildSkeletonLine(isDarkMode, widthFactor: 1.0),
                _buildSkeletonLine(isDarkMode, widthFactor: 0.65),
              ],
            ),
            ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.overlay),
              child: _ScanningLineAnimation(controller: _processingScanAnimationController, fromTop: -0.1, toTop: 1.0),
            ),
          ],
        ),
      ),
      ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _bounceAnimationController, curve: Curves.bounceInOut)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.indigo300,
            shape: BoxShape.circle,
            border: AppStyles.getBorder(isDarkMode, width: 4),
            boxShadow: [AppStyles.getShadow(isDarkMode, offset: 4)],
          ),
          child: const Icon(Icons.search, size: 32, color: AppColors.slate900),
        ),
      ),
    ],
  );
  }

  Widget _buildSkeletonLine(bool isDarkMode, {required double widthFactor}) {
    return FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: 16,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.slate700 : AppColors.slate200,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isDarkMode ? AppColors.black : AppColors.slate900).withOpacity(0.5),
          width: 2,
        ),
      ),
    ),
  );
  }

  Widget _buildErrorState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
    backgroundColor: isDarkMode ? AppColors.rose950 : AppColors.rose50,
    body: DottedBackground(
      dotColor: (isDarkMode ? AppColors.rose300 : AppColors.rose400).withOpacity(0.2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode ? AppColors.rose900 : AppColors.rose200,
                border: AppStyles.getBorder(isDarkMode, width: 8),
                boxShadow: [AppStyles.getShadow(isDarkMode, offset: 4)],
              ),
              child: Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut)),
                  child: Transform.rotate(
                    angle: 12 * (math.pi / 180),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.rose400,
                        borderRadius: BorderRadius.circular(16),
                        border: AppStyles.getBorder(isDarkMode, width: 4),
                        boxShadow: [AppStyles.getShadow(isDarkMode, offset: 4)],
                      ),
                      child: const Icon(Icons.error_outline, color: AppColors.slate900, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('SCAN FAILED', style: AppStyles.heading1.copyWith(color: isDarkMode ? AppColors.white : AppColors.slate900)),
            const SizedBox(height: 8),
            SizedBox(
              width: 250,
              child: Text(
                'Could not read the label. Please try again with a clearer image.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyBold.copyWith(color: isDarkMode ? AppColors.slate300 : AppColors.slate600),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: NeopopButton(
                onPressed: _resetState,
                color: isDarkMode ? AppColors.slate800 : AppColors.slate900,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('Try Again', style: AppStyles.buttonText),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _ScanningLineAnimation extends AnimatedWidget {
  const _ScanningLineAnimation({Key? key, required AnimationController controller, required double fromTop, required double toTop
  })
      : super(key: key, listenable: controller);

  Animation<double> get _progress => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Opacity(
        opacity: math.sin(_progress.value * math.pi),
        child: Align(
          alignment: Alignment(0, -1.0 + (_progress.value * 2 * 0.98)),
          child: Container(
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 20,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _InvertedRRectClipper extends CustomClipper<Path> {
  final Rect rect;
  final Radius radius;

  _InvertedRRectClipper({required this.rect, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, radius))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(covariant _InvertedRRectClipper oldClipper) {
    return oldClipper.rect != rect || oldClipper.radius != radius;
  }
}