import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../data/services/image_upload_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialImageUrl;
  final String folder;
  final Function(String url) onImageUploaded;
  final Function() onImageCleared;
  final double width;
  final double height;
  final String label;

  const ImagePickerWidget({
    super.key,
    this.initialImageUrl,
    required this.folder,
    required this.onImageUploaded,
    required this.onImageCleared,
    this.width = 180,
    this.height = 180,
    this.label = 'Chọn ảnh',
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImageUploadService _uploadService = ImageUploadService();
  String? _imageUrl;
  Uint8List? _localBytes;
  bool _isUploading = false;
  String? _errorMessage;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }

  @override
  void didUpdateWidget(covariant ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImageUrl != oldWidget.initialImageUrl) {
      setState(() {
        _imageUrl = widget.initialImageUrl;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        final name = file.name;

        if (bytes != null) {
          setState(() {
            _localBytes = bytes;
            _isUploading = true;
          });

          final uploadedUrl = await _uploadService.uploadImage(
            bytes: bytes,
            fileName: name,
            folder: widget.folder,
          );

          setState(() {
            _imageUrl = uploadedUrl;
            _isUploading = false;
          });

          widget.onImageUploaded(uploadedUrl);
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString();
        _localBytes = null;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _imageUrl = null;
      _localBytes = null;
      _errorMessage = null;
    });
    widget.onImageCleared();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _errorMessage != null
                    ? Colors.red
                    : _isHovering
                        ? const Color(0xFFFF6B35)
                        : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: _isHovering
                  ? [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  // Image preview
                  if (_localBytes != null)
                    Image.memory(_localBytes!, width: widget.width, height: widget.height, fit: BoxFit.cover)
                  else if (_imageUrl != null && _imageUrl!.isNotEmpty)
                    Image.network(
                      _imageUrl!,
                      width: widget.width,
                      height: widget.height,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40),
                        );
                      },
                    ),

                  // Placeholder when empty
                  if (_localBytes == null && (_imageUrl == null || _imageUrl!.isEmpty))
                    InkWell(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[400], size: 40),
                            const SizedBox(height: 8),
                            Text(
                              widget.label,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Uploading overlay
                  if (_isUploading)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                        ),
                      ),
                    ),

                  // Hover action buttons (Edit / Delete)
                  if (!_isUploading && (_localBytes != null || (_imageUrl != null && _imageUrl!.isNotEmpty)))
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _isHovering ? 1.0 : 0.0,
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF6B35), size: 20),
                                  onPressed: _pickAndUploadImage,
                                ),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: _clearImage,
                                ),
                              ),
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
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}