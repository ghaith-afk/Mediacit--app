// views/admin/media_form_dialog.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediatech/controllers/media_controller.dart';
import 'package:mediatech/models/media_model.dart';
import 'package:mediatech/widgets/confirm_dialog.dart';

class MediaFormDialog extends ConsumerStatefulWidget {
  final MediaModel? media;
  const MediaFormDialog({super.key, this.media});

  @override
  ConsumerState<MediaFormDialog> createState() => _MediaFormDialogState();
}

class _MediaFormDialogState extends ConsumerState<MediaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _coverUrlCtrl;
  late TextEditingController _pagesCtrl;
  late TextEditingController _totalCountCtrl;
  late TextEditingController _isbnCtrl;
  late TextEditingController _genreCtrl;
  late TextEditingController _publisherCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _languageCtrl;
  late TextEditingController _tagsCtrl;
  
  MediaType _type = MediaType.book;
  bool _loading = false;
  bool _featured = false;
  File? _selectedImage;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _titleCtrl = TextEditingController(text: widget.media?.title ?? '');
    _authorCtrl = TextEditingController(text: widget.media?.author ?? '');
    _descriptionCtrl = TextEditingController(text: widget.media?.description ?? '');
    _coverUrlCtrl = TextEditingController(text: widget.media?.coverUrl ?? '');
    _pagesCtrl = TextEditingController(text: widget.media?.pagesOrDuration.toString() ?? '');
    _totalCountCtrl = TextEditingController(text: widget.media?.totalCount.toString() ?? '1');
    _isbnCtrl = TextEditingController(text: widget.media?.isbn ?? '');
    _genreCtrl = TextEditingController(text: widget.media?.genre ?? '');
    _publisherCtrl = TextEditingController(text: widget.media?.publisher ?? '');
    _yearCtrl = TextEditingController(text: widget.media?.publicationYear.toString() ?? DateTime.now().year.toString());
    _languageCtrl = TextEditingController(text: widget.media?.language ?? 'English');
    _tagsCtrl = TextEditingController(text: widget.media?.tags.join(', ') ?? '');
    _type = widget.media?.type ?? MediaType.book;
    _featured = widget.media?.featured ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _descriptionCtrl.dispose();
    _coverUrlCtrl.dispose();
    _pagesCtrl.dispose();
    _totalCountCtrl.dispose();
    _isbnCtrl.dispose();
    _genreCtrl.dispose();
    _publisherCtrl.dispose();
    _yearCtrl.dispose();
    _languageCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
      _coverUrlCtrl.clear();
    }
  }

  Future<String?> _uploadImage(File imageFile, String mediaId) async {
    try {
      return imageFile.path;
    } catch (e) {
      return null;
    }
  }

  void _cancelDialog() {
    if (_loading || _uploadingImage) return;
    
    Navigator.of(context).pop();
  }

  Future<void> _saveMedia() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    final controller = ref.read(mediaControllerProvider.notifier);
    controller.clearMessages();

    String? finalCoverUrl = _coverUrlCtrl.text;
    if (_selectedImage != null) {
      setState(() => _uploadingImage = true);
      final imageUrl = await _uploadImage(_selectedImage!, widget.media?.id ?? DateTime.now().millisecondsSinceEpoch.toString());
      setState(() => _uploadingImage = false);
      if (imageUrl != null) {
        finalCoverUrl = imageUrl;
      }
    }

    final media = MediaModel(
      id: widget.media?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text,
      author: _authorCtrl.text,
      type: _type,
      description: _descriptionCtrl.text,
      coverUrl: finalCoverUrl,
      imageFile: _selectedImage?.path,
      pagesOrDuration: int.tryParse(_pagesCtrl.text) ?? 0,
      totalCount: int.tryParse(_totalCountCtrl.text) ?? 1,
      availableCount: int.tryParse(_totalCountCtrl.text) ?? 1,
      tags: _tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      rating: widget.media?.rating ?? 0.0,
      isbn: _isbnCtrl.text,
      genre: _genreCtrl.text,
      publisher: _publisherCtrl.text,
      publicationYear: int.tryParse(_yearCtrl.text) ?? DateTime.now().year,
      language: _languageCtrl.text,
      featured: _featured,
      createdAt: widget.media?.createdAt ?? Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    final success = widget.media != null 
        ? await controller.updateMedia(media)
        : await controller.addMedia(media);

    setState(() => _loading = false);
    if (success && context.mounted) Navigator.pop(context);
  }

  Future<void> _deleteMedia() async {
    final confirm = await showConfirmDialog(
      context,
      'Delete Media?',
      'This action cannot be undone. All associated data will be permanently deleted.',
    );
    if (!confirm) return;
    
    setState(() => _loading = true);
    final success = await ref.read(mediaControllerProvider.notifier).deleteMedia(widget.media!.id);
    setState(() => _loading = false);
    if (success && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.media != null;
    final state = ref.watch(mediaControllerProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600, 
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header with Close Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6B0E2A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_rounded : Icons.library_add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Media Item' : 'Add New Media',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: _cancelDialog,
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error Message
                      if (state.error != null)
                        _buildMessageCard(state.error!, Colors.red.shade50, Colors.red.shade600, Icons.error_outline),
                      
                      if (state.success != null)
                        _buildMessageCard(state.success!, Colors.green.shade50, Colors.green.shade600, Icons.check_circle),

                      // Image Upload Section
                      _buildImageSection(),
                      const SizedBox(height: 24),

                      // Basic Information
                      _buildSectionHeader('Basic Information'),
                      const SizedBox(height: 16),

                      // Title & Author
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 250,
                            child: _buildTextField(_titleCtrl, 'Title*', 'Enter media title', validator: _requiredValidator),
                          ),
                          SizedBox(
                            width: 250,
                            child: _buildTextField(_authorCtrl, 'Author/Director*', 'Enter creator name', validator: _requiredValidator),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Type & Genre
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 200,
                            child: _buildDropdownField(),
                          ),
                          SizedBox(
                            width: 300,
                            child: _buildTextField(_genreCtrl, 'Genre*', 'e.g., Fiction, Action', validator: _requiredValidator),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Details Section
                      _buildSectionHeader('Details'),
                      const SizedBox(height: 16),

                      // ISBN & Pages/Duration
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 250,
                            child: _buildTextField(_isbnCtrl, 'ISBN/Code', 'Unique identifier'),
                          ),
                          SizedBox(
                            width: 250,
                            child: _buildTextField(_pagesCtrl, _getPagesLabel(), _getPagesHint(), keyboardType: TextInputType.number),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Publisher & Year
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 250,
                            child: _buildTextField(_publisherCtrl, 'Publisher', 'Publication company'),
                          ),
                          SizedBox(
                            width: 250,
                            child: _buildTextField(_yearCtrl, 'Year', 'Publication year', keyboardType: TextInputType.number),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Language & Total Copies
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 250,
                            child: _buildTextField(_languageCtrl, 'Language', 'e.g., English, French'),
                          ),
                          SizedBox(
                            width: 250,
                            child: _buildTextField(_totalCountCtrl, 'Total Copies*', 'Number of copies', 
                              keyboardType: TextInputType.number, validator: _numberValidator),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      _buildTextField(_descriptionCtrl, 'Description', 'Enter media description...', maxLines: 3),
                      const SizedBox(height: 16),

                      // Tags
                      _buildTextField(_tagsCtrl, 'Tags', 'Separate with commas (fiction, adventure, bestseller)'),
                      const SizedBox(height: 20),

                      // Featured Toggle
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: _featured ? Colors.orange : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Featured Media',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    Text(
                                      'Show this item in featured section',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _featured,
                                onChanged: (v) => setState(() => _featured = v),
                                activeColor: const Color(0xFF6B0E2A),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Actions
                      Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _loading || _uploadingImage ? null : _cancelDialog,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Delete Button (Edit mode only)
                          if (isEdit) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _loading || _uploadingImage ? null : _deleteMedia,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text('Delete'),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],

                          // Save Button
                          Expanded(
                            flex: isEdit ? 2 : 1,
                            child: FilledButton(
                              onPressed: (_loading || _uploadingImage) ? null : _saveMedia,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6B0E2A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: (_loading || _uploadingImage)
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(isEdit ? 'Update Media' : 'Add Media'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(String message, Color backgroundColor, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cover Image',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Preview
                Container(
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: _buildImagePreview(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.upload, size: 18),
                        label: const Text('Upload Image'),
                        onPressed: _uploadingImage ? null : _pickImage,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF001F3F),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Or enter image URL',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _coverUrlCtrl,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/image.jpg',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_uploadingImage) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text('Uploading image...', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      );
    } else if (widget.media?.coverUrl.isNotEmpty == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.media!.coverUrl, 
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
        ),
      );
    } else {
      return _buildPlaceholderIcon();
    }
  }

  Widget _buildPlaceholderIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo_library, size: 32, color: Colors.grey.shade400),
        const SizedBox(height: 4),
        Text('No Image', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF001F3F),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media Type*',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MediaType>(
              value: _type,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: MediaType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    _getTypeDisplayName(type),
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (t) => setState(() => _type = t!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, 
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    if (int.tryParse(value) == null) return 'Enter a valid number';
    return null;
  }

  String _getTypeDisplayName(MediaType type) {
    switch (type) {
      case MediaType.book: return '📚 Book';
      case MediaType.movie: return '🎬 Movie';
      case MediaType.magazine: return '📰 Magazine';
      case MediaType.music: return '🎵 Music';
      case MediaType.game: return '🎮 Game';
    }
  }

  String _getPagesLabel() {
    switch (_type) {
      case MediaType.book: return 'Pages';
      case MediaType.magazine: return 'Pages';
      case MediaType.movie: return 'Duration (min)';
      case MediaType.music: return 'Tracks';
      case MediaType.game: return 'Play Time (hrs)';
    }
  }

  String _getPagesHint() {
    switch (_type) {
      case MediaType.book: return 'Number of pages';
      case MediaType.magazine: return 'Number of pages';
      case MediaType.movie: return 'Duration in minutes';
      case MediaType.music: return 'Number of tracks';
      case MediaType.game: return 'Average play time';
    }
  }
}