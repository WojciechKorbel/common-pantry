import 'dart:io';

import 'package:camera/camera.dart';
import 'package:common_pantry/core/utils/expiry_date_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:material_ui/material_ui.dart';

class ExpiryDateScannerScreen extends StatefulWidget {
  const ExpiryDateScannerScreen({super.key});

  @override
  State<ExpiryDateScannerScreen> createState() => _ExpiryDateScannerScreenState();
}

class _ExpiryDateScannerScreenState extends State<ExpiryDateScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;
  bool _isTorchOn = false;
  bool _isInitializing = true;
  String? _errorMessage;

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _isAnalyzingFrame = false;
  DateTime? _lastProcessedAt;
  List<DateTime> _detectedDates = const [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera([int cameraIndex = 0]) async {
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'No camera available on this device.';
          });
        }
        return;
      }

      await _cameraController?.stopImageStream();
      await _cameraController?.dispose();

      final camera = _cameras[cameraIndex];
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      await controller.startImageStream(_processCameraImage);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _selectedCameraIndex = cameraIndex;
        _isTorchOn = false;
        _isInitializing = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final now = DateTime.now();
    if (_isAnalyzingFrame) return;
    if (_lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < const Duration(milliseconds: 450)) {
      return;
    }

    final inputImage = _buildInputImage(image);
    if (inputImage == null) return;

    _isAnalyzingFrame = true;
    _lastProcessedAt = now;

    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final candidates = ExpiryDateParser.extractDates(recognizedText.text);

      if (mounted && candidates.isNotEmpty) {
        setState(() => _detectedDates = candidates);
      }
    } catch (_) {
      // Ignore transient frame errors and continue scanning
    } finally {
      _isAnalyzingFrame = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null) return null;

    final camera = _cameras[_selectedCameraIndex];
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final rawFormat = image.format.raw;
    if (rawFormat is! int) return null;
    final format = InputImageFormatValue.fromRawValue(rawFormat);
    if (format == null) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final Uint8List bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final next = !_isTorchOn;
    await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() => _isTorchOn = next);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _isInitializing = true);
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCamera(nextIndex);
  }

  Future<void> _selectDate(DateTime date) async {
    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop(date);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final scanWindowWidth = size.width * 0.8;
    const scanWindowHeight = 110.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan expiry date'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleTorch,
          ),
          if (_cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                if (_cameraController != null && _cameraController!.value.isInitialized)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!.value.previewSize!.height,
                        height: _cameraController!.value.previewSize!.width,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  ),
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.65),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(color: Colors.transparent),
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: scanWindowWidth,
                          height: scanWindowHeight,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: scanWindowWidth,
                  height: scanWindowHeight,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _detectedDates.isNotEmpty
                          ? Colors.greenAccent
                          : theme.colorScheme.primary,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_detectedDates.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Tap detected expiry date:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  for (final date in _detectedDates)
                                    FilledButton.icon(
                                      onPressed: () => _selectDate(date),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: Text(_formatDate(date)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Point camera at the expiry date on packaging',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
