import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/neopop_button.dart';

class CropScreen extends StatefulWidget {
  final String imagePath;

  const CropScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final TransformationController _transformationController = TransformationController();
  late File _imageFile;
  ui.Image? _decodedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await _imageFile.readAsBytes();
    final image = await decodeImageFromList(data);
    if (mounted) {
      setState(() {
        _decodedImage = image;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_decodedImage == null) return;

    final Size screenSize = MediaQuery.of(context).size;
    final double cropWidth = screenSize.width * 0.8;
    final double cropHeight = cropWidth; // Square crop area
    
    // Calculate crop box position on screen
    final double cropL = (screenSize.width - cropWidth) / 2;
    final double cropT = (screenSize.height - cropHeight) / 2;

    // Calculate dimensions of the image as rendered in the viewer (at scale 1.0)
    final double imgAspect = _decodedImage!.width / _decodedImage!.height;
    final double fittedWidth = screenSize.width;
    final double fittedHeight = fittedWidth / imgAspect;
    
    // Calculate the inverse transform to map screen coordinates back to image coordinates
    Matrix4 inverse = Matrix4.inverted(_transformationController.value);
    
    // Map Top-Left of crop box
    Vector3 tlScreen = Vector3(cropL, cropT, 0);
    Vector3 tlLocal = inverse.transform3(tlScreen);
    
    // Map Bottom-Right of crop box
    Vector3 brScreen = Vector3(cropL + cropWidth, cropT + cropHeight, 0);
    Vector3 brLocal = inverse.transform3(brScreen);
    
    // Normalize coordinates (0.0 to 1.0)
    double left = tlLocal.x / fittedWidth;
    double top = tlLocal.y / fittedHeight;
    double right = brLocal.x / fittedWidth;
    double bottom = brLocal.y / fittedHeight;
    
    // Clamp to ensure we don't go outside the image
    left = left.clamp(0.0, 1.0);
    top = top.clamp(0.0, 1.0);
    right = right.clamp(0.0, 1.0);
    bottom = bottom.clamp(0.0, 1.0);
    
    Navigator.pop(context, Rect.fromLTRB(left, top, right, bottom));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final double imgAspect = _decodedImage!.width / _decodedImage!.height;
    final double fittedWidth = size.width;
    final double fittedHeight = fittedWidth / imgAspect;

    final double cropWidth = size.width * 0.8;
    final double cropHeight = cropWidth;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('ADJUST AREA', style: AppStyles.heading1.copyWith(fontSize: 18, color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              constrained: false,
              child: SizedBox(
                width: fittedWidth,
                height: fittedHeight,
                child: Image.file(_imageFile, fit: BoxFit.fill),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
                child: Stack(
                  children: [
                    Container(decoration: const BoxDecoration(color: Colors.transparent, backgroundBlendMode: BlendMode.dstOut)),
                    Center(
                      child: Container(
                        width: cropWidth,
                        height: cropHeight,
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: cropWidth,
              height: cropHeight,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.emerald400, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: SizedBox(
              height: 56,
              child: NeopopButton(
                onPressed: _onConfirm,
                color: AppColors.emerald400,
                child: Center(child: Text('SCAN AREA', style: AppStyles.buttonText.copyWith(color: AppColors.slate900))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}