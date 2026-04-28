import 'package:flutter/material.dart';

void showFullScreenImage(BuildContext context, String imageUrl) {
  final isNetworkImage =
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) {
      return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: isNetworkImage
                      ? Image.network(imageUrl, fit: BoxFit.contain)
                      : Image.asset(imageUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
