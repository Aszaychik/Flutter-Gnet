import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gnet_app/services/api_service.dart';
import 'package:gnet_app/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;
  bool _isPickingImage = false;

  Future<void> _pickImage() async {
    try {
      setState(() => _isPickingImage = true);

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        // Add options that might resolve channel issues
        requestFullMetadata: false,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = image.name;
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _apiService.createActivity(
        imageBytes: _imageBytes!,
        imageName: _imageName!,
        title: _titleController.text,
        description: _descriptionController.text,
      );

      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Activity created successfully!'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        );
        // Clear form
        _formKey.currentState!.reset();
        setState(() {
          _imageBytes = null;
          _imageName = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create activity'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Activity'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _submitForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.lightTheme.colorScheme.surface,
                ),
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.lightTheme.colorScheme.surface,
                ),
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create Activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _isPickingImage
            ? Center(
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        )
            : _imageBytes != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.cover,
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add an image',
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}