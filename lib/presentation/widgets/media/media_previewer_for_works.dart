/*
 * Fecha de creación: 26/04/2025
 * Autor: KingdomOfJames
 * Descripción: Este widget permite la visualización de una lista de medios (videos o imágenes) en un visor de página. 
 * Los usuarios pueden navegar entre los medios, ver videos o imágenes y eliminar archivos seleccionados mediante un diálogo de confirmación.
 * 
 * Características:
 * - Permite la visualización de imágenes y videos en un visor de página.
 * - Soporta el desplazamiento entre los elementos con un control de página.
 * - Los usuarios pueden eliminar archivos mediante un diálogo de confirmación.
 * - Soporte para la visualización interactiva de imágenes (acercamiento y desplazamiento).
 * 
 * Recomendaciones:
 * - Para una mejor experiencia, asegúrate de que las URLs de los medios sean accesibles y válidas.
 * - El código está diseñado para usar un servicio backend para la eliminación de archivos; asegúrate de tener configurado el servicio correctamente para evitar errores en la eliminación.
 */

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:live_music/data/repositories/render_http_client/images/upload_work_image.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class MediaPreviewer extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;
  final Function(String)? onMediaDeleted;

  const MediaPreviewer({
    required this.mediaUrls,
    this.initialIndex = 0,
    this.onMediaDeleted,
    Key? key,
  }) : super(key: key);

  @override
  _MediaPreviewerState createState() => _MediaPreviewerState();
}

class _MediaPreviewerState extends State<MediaPreviewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deleteMedia(String url) async {
    try {
      final response = await RetrofitInstanceForWorks().apiServiceForWorks
          .deleteWorkMedia(url);
      if (response.success == true) {
        if (widget.onMediaDeleted != null) {
          widget.onMediaDeleted!(url);
        }

        setState(() {
          final newMediaUrls = List<String>.from(widget.mediaUrls)..remove(url);
          widget.mediaUrls.clear();
          widget.mediaUrls.addAll(newMediaUrls);

          if (_currentIndex >= widget.mediaUrls.length) {
            _currentIndex =
                widget.mediaUrls.isNotEmpty ? widget.mediaUrls.length - 1 : 0;
          }

          if (widget.mediaUrls.isEmpty) {
            Navigator.of(context).pop();
          } else {
            _pageController.jumpToPage(_currentIndex);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El archivo se eliminó correctamente'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error del servidor al eliminar el archivo: ${response.error ?? "Sin mensaje específico"}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Excepción al eliminar archivo: $e');
      print('Stack trace:\n$stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excepción al eliminar el archivo: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(String url) {
    final colorScheme = ColorPalette.getPalette(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme[AppStrings.primaryColor],
            title: Text(
              'Confirmar eliminación',
              style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
            ),
            content: Text(
              url.toLowerCase().endsWith('.mp4')
                  ? '¿Estás seguro de que quieres eliminar este video?'
                  : '¿Estás seguro de que quieres eliminar esta imagen?',
              style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteMedia(url);
                },
                child: Text(
                  'Eliminar',
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
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

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaUrls.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final url = widget.mediaUrls[index];
              if (url.toLowerCase().endsWith('.mp4')) {
                return VideoPlayerWidget(url: url);
              } else {
                return Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                );
              }
            },
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: colorScheme[AppStrings.secondaryColor],
                      size: 30,
                    ),
                    onPressed:
                        () => _showDeleteConfirmationDialog(
                          widget.mediaUrls[_currentIndex],
                        ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme[AppStrings.secondaryColor],
                          size: 30,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        '${_currentIndex + 1}/${widget.mediaUrls.length}',
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({Key? key, required this.url}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _showPlayIcon = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.network(widget.url)
          ..setLooping(true)
          ..setVolume(1.0);

    _initializeVideoPlayerFuture = _controller.initialize();

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _showPlayIcon = true;
      } else {
        _controller.play();
        _showPlayIcon = false;
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final videoAspectRatio = _controller.value.aspectRatio;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: _togglePlayback,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: videoAspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        if (!_controller.value.isPlaying || _showPlayIcon)
                          const Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 80,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDuration(_controller.value.position),
                          style: const TextStyle(color: Colors.white),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Slider(
                              min: 0,
                              max:
                                  _controller.value.duration.inMilliseconds
                                      .toDouble(),
                              value:
                                  _controller.value.position.inMilliseconds
                                      .clamp(
                                        0,
                                        _controller
                                            .value
                                            .duration
                                            .inMilliseconds,
                                      )
                                      .toDouble(),
                              onChanged: (value) {
                                _controller.seekTo(
                                  Duration(milliseconds: value.toInt()),
                                );
                              },
                              activeColor: Colors.redAccent,
                              inactiveColor: Colors.grey,
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(_controller.value.duration),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
