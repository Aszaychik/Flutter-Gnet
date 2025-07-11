import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;
  final String? authToken;

  const FullScreenImageScreen({
    Key? key,
    required this.imageUrl,
    this.authToken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(
            imageUrl,
            headers: authToken != null
                ? {'Authorization': 'Bearer $authToken'}
                : {},
          ),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          loadingBuilder: (context, event) => Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.error,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }
}