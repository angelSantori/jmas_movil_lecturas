import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
  String? imageData,
  VoidCallback? onTap, {
  bool isEditable = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
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
              imageData == null
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
                  : _buildImageWidget(imageData, isEditable),
        ),
      ),
    ],
  );
}

Widget _buildImageWidget(String imageData, bool isEditable) {
  try {
    // Verificar si es base64 válido
    if (!RegExp(r'^[a-zA-Z0-9+/]+={0,2}$').hasMatch(imageData)) {
      throw 'Formato de imagen no válido';
    }

    final bytes = base64Decode(imageData);
    return FutureBuilder<Size>(
      future: _getImageSizeFromBytes(bytes),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Icon(Icons.error, color: Colors.red));
        }

        final size = snapshot.data ?? const Size(100, 100);
        // ignore: unused_local_variable
        final aspectRatio = size.width / size.height;

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
            if (!isEditable)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
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
    );
  } catch (e) {
    print('Error al mostrar imagen: $e');
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 40),
          SizedBox(height: 8),
          Text('Error al cargar imagen', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

Future<Size> _getImageSizeFromBytes(Uint8List bytes) async {
  final Completer<Size> completer = Completer();
  final image = Image.memory(bytes);
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

//  Estrellas
class StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onRatingChanged;
  final double starSize;
  final bool interactive;

  const StarRating({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.starSize = 32.0,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap:
              interactive && onRatingChanged != null
                  ? () => onRatingChanged!(index + 1)
                  : null,
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: starSize,
          ),
        );
      }),
    );
  }
}
