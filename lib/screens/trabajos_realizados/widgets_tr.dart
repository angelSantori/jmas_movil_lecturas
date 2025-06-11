import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

Widget buildInfoItem(String title, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$title:',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(value, overflow: TextOverflow.ellipsis, maxLines: 2),
      ),
    ],
  );
}

Widget buildInfoCard(String title, String? value, {Widget? trailing}) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          Text(value ?? 'N/A', style: const TextStyle(fontSize: 15)),
        ],
      ),
    ),
  );
}

Widget buildSectionCard(String title, List<Widget> children) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

Widget buildPhotoSection(
  String title,
  String? imagePath,
  VoidCallback? onTap, {
  bool isEditable = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: isEditable ? onTap : null,
        child: Container(
          height: 200,
          width: 150,
          decoration: BoxDecoration(
            border: Border.all(
              color: isEditable ? Colors.grey : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
            color: !isEditable ? Colors.grey.shade100 : Colors.grey.shade50,
          ),
          child:
              imagePath == null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 50,
                          color:
                              isEditable ? Colors.grey : Colors.grey.shade400,
                        ),
                        Text(
                          isEditable ? 'Toca para tomar foto' : 'Sin foto',
                          style: TextStyle(
                            color:
                                isEditable ? Colors.grey : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                  : FutureBuilder<Size>(
                    future: _getImageSize(imagePath),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final size = snapshot.data!;
                      final aspectRatio = size.width / size.height;

                      return Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: aspectRatio,
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (!isEditable)
                            Container(
                              color: Colors.black.withOpacity(0.3),
                              child: const Center(
                                child: Icon(
                                  Icons.lock_outline,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
        ),
      ),
    ],
  );
}

Future<Size> _getImageSize(String imagePath) async {
  final completer = Completer<Size>();
  final file = File(imagePath);
  final bytes = await file.readAsBytes();

  Image image = Image.memory(bytes);
  image.image
      .resolve(const ImageConfiguration())
      .addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()),
          );
        }),
      );

  return completer.future;
}
