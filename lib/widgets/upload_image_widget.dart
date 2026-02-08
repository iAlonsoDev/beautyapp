import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UploadImageWidget extends StatefulWidget {
  final void Function(String imageUrl) onUploaded;

  const UploadImageWidget({super.key, required this.onUploaded});

  @override
  State<UploadImageWidget> createState() => _UploadImageWidgetState();
}

class _UploadImageWidgetState extends State<UploadImageWidget> {
  String? uploadedImageUrl;
  bool isUploading = false;

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ninguna imagen')),
        );
      }
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final uploadUrl =
          Uri.parse('https://api.cloudinary.com/v1_1/decwc31n0/image/upload');
      final request = http.MultipartRequest('POST', uploadUrl)
        ..fields['upload_preset'] = 'BeautySalonDemo';

      if (kIsWeb) {
        // En la web, usamos los bytes de la imagen
        final bytes = await pickedFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'image.jpg',
        ));
      } else {
        // En móviles, usamos el archivo
        final file = await pickedFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file,
          filename: 'image.jpg',
        ));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final resData = jsonDecode(resStr);
        setState(() {
          uploadedImageUrl = resData['secure_url'];
          isUploading = false;
        });
        widget.onUploaded(uploadedImageUrl!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen subida correctamente')),
          );
        }
      } else {
        throw Exception('Error al subir la imagen: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en pickAndUploadImage: $e');
      setState(() {
        isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUploading)
          const Center(child: CircularProgressIndicator())
        else if (uploadedImageUrl != null)
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  uploadedImageUrl!,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Imagen subida',
                style: TextStyle(color: Colors.green, fontSize: 14),
              ),
            ],
          )
        else
          const Text(
            'No se ha seleccionado ninguna imagen',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: isUploading ? null : pickAndUploadImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 68, 139, 85),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Seleccionar Imagen'),
        ),
      ],
    );
  }
}