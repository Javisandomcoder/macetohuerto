import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/care_log.dart';
import '../models/plant.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PlantGalleryPage extends StatefulWidget {
  final Plant plant;

  const PlantGalleryPage({super.key, required this.plant});

  @override
  State<PlantGalleryPage> createState() => _PlantGalleryPageState();
}

class _PlantGalleryPageState extends State<PlantGalleryPage> {
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  List<PlantImage> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _loading = true);
    final images = await _db.getPlantImages(widget.plant.id);
    setState(() {
      _images = images;
      _loading = false;
    });
  }

  Future<void> _addImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    // Save image to app directory
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'plant_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName = '${const Uuid().v4()}${path.extension(pickedFile.path)}';
    final savedPath = path.join(imagesDir.path, fileName);
    await File(pickedFile.path).copy(savedPath);

    // Save to database
    final image = PlantImage(
      plantId: widget.plant.id,
      imagePath: savedPath,
      takenAt: DateTime.now(),
    );

    await _db.insertPlantImage(image);
    await _loadImages();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen añadida')),
      );
    }
  }

  Future<void> _deleteImage(PlantImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar imagen'),
        content: const Text('¿Seguro que quieres eliminar esta imagen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete file
    final file = File(image.imagePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Delete from database
    await _db.deletePlantImage(image.id!);
    await _loadImages();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen eliminada')),
      );
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _addImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(ctx);
                _addImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewImage(PlantImage image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _ImageViewerPage(
          image: image,
          onDelete: () async {
            await _deleteImage(image);
            if (ctx.mounted) {
              Navigator.pop(ctx);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Galería de ${widget.plant.name}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay imágenes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Añade fotos para ver la evolución de tu planta',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final image = _images[index];
                    return GestureDetector(
                      onTap: () => _viewImage(image),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(image.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, error, stack) => Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImageOptions,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class _ImageViewerPage extends StatelessWidget {
  final PlantImage image;
  final VoidCallback onDelete;

  const _ImageViewerPage({
    required this.image,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(image.imagePath),
                  errorBuilder: (ctx, error, stack) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFmt.format(image.takenAt),
                  style: const TextStyle(color: Colors.white70),
                ),
                if (image.caption != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    image.caption!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
