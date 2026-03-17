import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/permission_service.dart';

/// Live camera viewfinder screen with capture button and lifecycle management.
///
/// Implements INPUT-01: user sees a live camera preview (back camera, 720p),
/// taps a capture button, and navigates to PreviewScreen with the photo path.
///
/// Key behaviors:
/// - Requests camera permission at point of use via [PermissionService]
/// - Permanently-denied permission shows dialog with "Open Settings" button
/// - Lifecycle observer disposes camera on background, re-inits on resume
///   (prevents documented iOS memory leak -- Flutter issues #29586, #97941)
/// - Guard against double-tap capture with [_isTakingPicture] flag
/// - Resolution set to high (720p) -- ImagePreprocessor resizes to 1024px anyway
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isTakingPicture = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;

  final PermissionService _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lifecycle management (CRITICAL -- Pitfall 1 from research):
    // Dispose on inactive to prevent iOS camera memory leak.
    // Re-initialize on resumed.
    final controller = _controller;

    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    // Request camera permission first
    final granted = await _permissionService.requestCamera();
    if (!granted) {
      // Check if permanently denied
      final permanentlyDenied = await _permissionService.isPermanentlyDenied(
        _permissionService.cameraPermission,
      );

      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _permissionPermanentlyDenied = permanentlyDenied;
          _errorMessage = permanentlyDenied
              ? 'Camera access is permanently denied. Please enable it in Settings.'
              : 'Camera permission is required to capture photos.';
        });
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No cameras found on this device.';
          });
        }
        return;
      }

      // Pick back camera (first in list)
      final camera = cameras.first;
      _controller = CameraController(
        camera,
        ResolutionPreset.high, // 720p -- saves memory
        enableAudio: false, // OCR app, no microphone needed
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
          _permissionDenied = false;
          _permissionPermanentlyDenied = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isTakingPicture) return; // Guard against double-tap

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final xFile = await controller.takePicture();

      if (mounted) {
        context.push('/preview?path=${Uri.encodeComponent(xFile.path)}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    // Permission denied state
    if (_permissionDenied) {
      return _PermissionDeniedView(
        message: _errorMessage ?? 'Camera permission denied.',
        isPermanentlyDenied: _permissionPermanentlyDenied,
        onOpenSettings: () async {
          await _permissionService.openSettings();
        },
        onRetry: _initCamera,
        theme: theme,
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _initCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Camera viewfinder with capture button
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen camera preview
        CameraPreview(_controller!),

        // Capture button at bottom center
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: _isTakingPicture
                ? const SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : FloatingActionButton.large(
                    onPressed: _takePicture,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    child: const Icon(Icons.camera_alt, size: 36),
                  ),
          ),
        ),
      ],
    );
  }
}

/// View shown when camera permission is denied.
class _PermissionDeniedView extends StatelessWidget {
  final String message;
  final bool isPermanentlyDenied;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;
  final ThemeData theme;

  const _PermissionDeniedView({
    required this.message,
    required this.isPermanentlyDenied,
    required this.onOpenSettings,
    required this.onRetry,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Access Required',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isPermanentlyDenied)
              FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              )
            else
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
