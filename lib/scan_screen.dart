import 'dart:convert';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:label_lensv2/auth_service.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/dashed_border_painter.dart';
import 'dart:math' as math;
import 'package:label_lensv2/dotted_background.dart';
import 'package:label_lensv2/neopop_button.dart';
import 'package:label_lensv2/scan_result.dart';
import 'package:label_lensv2/scan_result_view.dart';
import 'package:label_lensv2/crop_screen.dart';



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
  ScanResult? _scanResult;
  bool _isSaving = false;

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
      // Navigate to Crop Screen to adjust ROI
      if (!mounted) return;
      final Rect? cropRect = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CropScreen(imagePath: image!.path)),
      );

      if (cropRect == null) return; // User cancelled crop

      setState(() => _scanState = 'processing'); // Show loading UI first

      try {
        // 1. Get image dimensions to define ROI (Region of Interest)
        final data = await image.readAsBytes();
        final decodedImage = await decodeImageFromList(data);
        final double width = decodedImage.width.toDouble();
        final double height = decodedImage.height.toDouble();

        // 2. Extract text
        final textRecognizer = TextRecognizer();
        final inputImage = InputImage.fromFilePath(image.path);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        textRecognizer.close();

        // 3. Filter text inside the user-defined ROI
        // cropRect is normalized (0.0 to 1.0), so we multiply by actual image dimensions
        final Rect roi = Rect.fromLTRB(
          cropRect.left * width,
          cropRect.top * height,
          cropRect.right * width,
          cropRect.bottom * height,
        );

        List<TextBlock> validBlocks = [];
        for (var block in recognizedText.blocks) {
          // Check if the block's center intersects with our ROI
          if (roi.contains(block.boundingBox.center)) {
            validBlocks.add(block);
          }
        }

        // Fallback: If ROI filtering removes everything, use all blocks
        if (validBlocks.isEmpty) {
          validBlocks = recognizedText.blocks;
        }

        // Sort blocks: Top-to-bottom, then Left-to-right
        validBlocks.sort((a, b) {
          final double dy = a.boundingBox.top - b.boundingBox.top;
          if (dy.abs() > 20) return dy.compareTo(0); // Significant vertical difference
          return a.boundingBox.left.compareTo(b.boundingBox.left);
        });

        // 4. Construct JSON-ready data
        String fullText = validBlocks.map((b) => b.text).join('\n');
        String productName = validBlocks.isNotEmpty ? validBlocks.first.text.split('\n').first : "Scanned Product";
        
        // Extract ingredients section
        String lowerText = fullText.toLowerCase();
        int keywordIndex = lowerText.indexOf('ingredients');
        String ingredientsText = keywordIndex != -1 
            ? fullText.substring(keywordIndex + 11).trim().replaceFirst(RegExp(r'^[:\s]+'), '') 
            : fullText;

        // Clean and split into list
        List<String> ingredientsList = ingredientsText
            .split(RegExp(r'[,.]')) // Split by comma or dot
            .map((e) => e.trim().replaceAll(RegExp(r'\s+'), ' '))
            .where((e) => e.length > 2) // Filter out noise
            .toList();

        // 3. Call API
        final authService = AuthService();
        final result = await authService.scanIngredients(ingredientsList, productName: productName);

        if (mounted) {
          setState(() {
            _scanResult = result;
            _scanState = 'result';
          });
        }
      } catch (e) {
        debugPrint('Error during processing or API call: $e');
        if (mounted) {
          setState(() => _scanState = 'error');
        }
      }
    }
  }

  Widget _buildModeSwitcher(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.slate900.withOpacity(0.8) : AppColors.slate800.withOpacity(0.8),
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
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        children: [
          CustomPaint(
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
        ],
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
    if (_scanResult == null) return _buildErrorState();
    return ScanResultView(onBackPressed: _resetState, result: _scanResult!);
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
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          children: [
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

class SafeStatusWidget extends StatelessWidget {
  final bool isSafe;
  final bool isDarkMode;

  const SafeStatusWidget(
      {Key? key, required this.isSafe, required this.isDarkMode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isSafe ? AppColors.emerald500 : AppColors.rose500;
    final icon =
        isSafe ? Icons.check_circle_outline : Icons.dangerous_outlined;
    final text = isSafe ? 'Considered Safe' : 'Potential Risks';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.slate800 : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
        boxShadow: [AppStyles.getShadow(isDarkMode)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(text, style: AppStyles.bodyBold.copyWith(color: color)),
        ],
      ),
    );
  }
}

class RiskScorePieChart extends StatelessWidget {
  final int riskScore;
  final bool isDarkMode;

  const RiskScorePieChart(
      {Key? key, required this.riskScore, required this.isDarkMode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    if (riskScore <= 30) {
      scoreColor = AppColors.emerald500;
    } else if (riskScore <= 70) {
      scoreColor = AppColors.amber300;
    } else {
      scoreColor = AppColors.rose500;
    }

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CustomPaint(
              painter: _PieChartPainter(
                percentage: riskScore,
                color: scoreColor,
                backgroundColor:
                    isDarkMode ? AppColors.slate700 : AppColors.slate200,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$riskScore',
                  style: AppStyles.heading1.copyWith(fontSize: 28, color: scoreColor)),
              Text('Risk Score',
                  style: AppStyles.body.copyWith(fontSize: 12,
                      color: isDarkMode ? AppColors.slate300 : AppColors.slate600)),
            ],
          ),
        ],
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

class _PieChartPainter extends CustomPainter {
  final int percentage;
  final Color color;
  final Color backgroundColor;

  _PieChartPainter(
      {required this.percentage,
      required this.color,
      required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Foreground arc
    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * (percentage / 100);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
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