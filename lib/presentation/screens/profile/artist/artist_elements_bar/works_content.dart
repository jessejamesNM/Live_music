// =====================================================================
// Fecha de creación: 2025-04-26
// Autor: KingdomOfJames
//
// Descripción:
// Pantalla para mostrar y cargar imágenes o videos de un usuario,
// relacionada con sus "trabajos" o contenido multimedia.
// Permite ver y cargar imágenes y videos desde la galería y visualizarlos
// en una vista previa. Utiliza un GridView para mostrar los elementos y
// permite añadir nuevos elementos al contenido mediante un botón de
// acción flotante.
//
// Recomendaciones:
// - Asegúrate de manejar bien las excepciones al cargar imágenes o videos
//   para que la aplicación no falle en caso de errores inesperados.
// - Este componente está diseñado para ser reutilizable con diferentes
//   tipos de contenido multimedia, por lo que es conveniente mantener el
//   código modular.
//
// Características:
// - Subida de imágenes y videos con retroalimentación mediante SnackBars.
// - Vista previa de imágenes y videos seleccionados.
// - Soporte para varios formatos de video (mp4, mov, avi, mkv, webm).
// =====================================================================

import 'package:flutter/material.dart';
import 'package:live_music/data/widgets/cut_and_upload_images.dart';
import 'package:live_music/data/widgets/media_upload_event.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/media/media_previewer_for_works.dart';
import 'package:live_music/presentation/widgets/media/videp_tumb_nail_for_works.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';
import 'dart:async';
import '../../../../../data/provider_logics/user/user_provider.dart';
import '../../../../../data/repositories/render_http_client/images/upload_work_image.dart';
import 'package:live_music/presentation/resources/colors.dart';

class WorksContent extends StatefulWidget {
  static const double addButtonBorderRadius = 12.0;

  const WorksContent({Key? key}) : super(key: key);

  @override
  WorksContentState createState() => WorksContentState();
}

class WorksContentState extends State<WorksContent> {
  final ApiServiceForWorks _api = RetrofitInstanceForWorks().apiServiceForWorks;
  List<String> mediaUrls = [];
  late final String currentUserId;
  late final EventBus _eventBus;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    currentUserId = userProvider.currentUserId;
    _eventBus = EventBus();
    
    _eventBus.subscribe<MediaUploadEvent>(_handleMediaUpload);
    fetchMedia();
  }

  @override
  void dispose() {
    _eventBus.unsubscribe<MediaUploadEvent>(_handleMediaUpload);
    super.dispose();
  }

  void _handleMediaUpload(MediaUploadEvent event) {
    if (!mounted) return;
    setState(() => mediaUrls.insert(0, event.mediaUrl));
  }

  Future<void> fetchMedia() async {
    try {
      final resp = await _api.getWorkMedia(currentUserId);
      if (resp.mediaUrls != null) {
        setState(() => mediaUrls = resp.mediaUrls!);
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    await ProfileImageHandler.handle(
      context: context,
      imageType: 'works',
      userProvider: Provider.of<UserProvider>(context, listen: false),
      onImageUploaded: (url) {
        setState(() => mediaUrls.insert(0, url));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MediaPreviewer(mediaUrls: mediaUrls, initialIndex: 0),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.imageUploadSuccess)),
        );
      },
    );
  }

  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;
    final file = File(pickedFile.path);
    try {
      final resp = await _api.uploadVideo(file, currentUserId);
      if (resp.url != null) {
        setState(() => mediaUrls.insert(0, resp.url!));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MediaPreviewer(mediaUrls: mediaUrls, initialIndex: 0),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.videoUploadSuccess)),
        );
      } else {
        throw Exception(resp.error ?? AppStrings.unknownError);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.videoUploadError} $e')),
      );
    }
  }

  void _onAddPressed() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text(AppStrings.uploadImage),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text(AppStrings.uploadVideo),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isVideo(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext));
  }

  Widget _buildMediaItem(String url, int index, Map<String, Color> colorScheme) {
    final isVideo = _isVideo(url);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MediaPreviewer(mediaUrls: mediaUrls, initialIndex: index),
          ),
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isVideo
                ? VideoThumbnail(
                    url: url,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Image.network(
                    url,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: colorScheme['primaryColorLight']!,
                      child: Icon(
                        Icons.broken_image,
                        color: colorScheme['secondaryColor'],
                      ),
                    ),
                  ),
          ),
          if (isVideo)
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 60,
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Container(
      color: colorScheme['primaryColor'],
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: mediaUrls.length + 1,
        itemBuilder: (context, idx) {
          if (idx < mediaUrls.length) {
            return _buildMediaItem(mediaUrls[idx], idx, colorScheme);
          } else {
            return GestureDetector(
              onTap: _onAddPressed,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme['primaryColorLight'],
                  borderRadius: BorderRadius.circular(
                    WorksContent.addButtonBorderRadius,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: 48,
                    color: colorScheme['secondaryColor'],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
