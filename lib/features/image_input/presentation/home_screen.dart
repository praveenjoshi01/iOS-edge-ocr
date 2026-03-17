import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../data/pdf_renderer_service.dart';
import '../data/permission_service.dart';

/// Main input selection screen with three large buttons for image sources.
///
/// The user arrives here after model download is complete. Each button
/// navigates to a different input flow:
/// - Camera: live capture via /camera route (INPUT-01)
/// - Photo Library: picks from device gallery (INPUT-02)
/// - Import File: picks from Files app with PDF support (INPUT-03)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PermissionService _permissionService = PermissionService();
  final PdfRendererService _pdfRendererService = PdfRendererService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  /// Pick an image from the photo library (INPUT-02).
  ///
  /// Requests photo library permission, opens the iOS gallery picker,
  /// and navigates to PreviewScreen with the selected image path.
  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    try {
      // Request photo library permission
      final granted = await _permissionService.requestPhotos();
      if (!granted) {
        final permanentlyDenied = await _permissionService.isPermanentlyDenied(
          _permissionService.photosPermission,
        );

        if (!mounted) return;

        if (permanentlyDenied) {
          _showPermissionDeniedDialog(
            title: 'Photo Library Access Required',
            message:
                'Photo library access is permanently denied. '
                'Please enable it in Settings to select photos.',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Photo library permission is required to select images.',
              ),
            ),
          );
        }
        return;
      }

      // Open gallery picker -- do NOT set maxWidth/maxHeight
      // ImagePreprocessor handles resize with proper aspect ratio and RGB conversion
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      // User cancelled picker
      if (pickedFile == null) return;

      if (!mounted) return;

      // Navigate to preview with the picked image path
      context.push('/preview?path=${Uri.encodeComponent(pickedFile.path)}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  /// Pick a file from the Files app (INPUT-03).
  ///
  /// Opens iOS Files app picker for images and PDFs. If a PDF is selected,
  /// renders the first page to a temp image via PdfRendererService.
  /// Navigates to PreviewScreen with the resulting image path.
  Future<void> _pickFromFiles() async {
    if (_isProcessing) return;

    try {
      // Files app import does NOT require photo library permission
      // file_picker uses UIDocumentPickerViewController which has its own access
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'webp', 'pdf'],
      );

      // User cancelled picker
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to access the selected file.')),
        );
        return;
      }

      // Check if PDF -- needs rendering to image first
      final extension = file.extension?.toLowerCase();
      if (extension == 'pdf') {
        if (!mounted) return;

        setState(() {
          _isProcessing = true;
        });

        // Show loading indicator while rendering PDF
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Rendering PDF page...'),
              ],
            ),
            duration: Duration(seconds: 30), // Will be dismissed on success
          ),
        );

        try {
          final renderedPath =
              await _pdfRendererService.renderFirstPage(filePath);

          if (!mounted) return;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          setState(() {
            _isProcessing = false;
          });

          context.push(
            '/preview?path=${Uri.encodeComponent(renderedPath)}',
          );
        } catch (e) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          setState(() {
            _isProcessing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to render PDF: $e')),
          );
        }
      } else {
        // Image file -- navigate directly
        if (!mounted) return;

        context.push('/preview?path=${Uri.encodeComponent(filePath)}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  /// Show a dialog for permanently denied permissions with Open Settings button.
  void _showPermissionDeniedDialog({
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _permissionService.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // App title
              Icon(
                Icons.document_scanner_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Edge OCR',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Extract text from images, entirely on-device',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Input source buttons
              _InputSourceCard(
                icon: Icons.camera_alt,
                title: 'Camera',
                subtitle: 'Capture a document or photo',
                onTap: () => context.push('/camera'),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _InputSourceCard(
                icon: Icons.photo_library,
                title: 'Photo Library',
                subtitle: 'Select from your photos',
                onTap: _pickFromGallery,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _InputSourceCard(
                icon: Icons.file_open,
                title: 'Import File',
                subtitle: 'Pick from Files app (images & PDFs)',
                onTap: _pickFromFiles,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A large card-style button for an input source.
class _InputSourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ThemeData theme;

  const _InputSourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
