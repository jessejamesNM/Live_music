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
import 'package:live_music/data/repositories/render_http_client/images/upload_work_image.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/media/video_player_for_works.dart';

class MediaPreviewer extends StatefulWidget {
  final List<String>
  mediaUrls; // Lista de URLs de los medios (imágenes o videos).
  final int initialIndex; // Índice inicial para mostrar el primer medio.

  const MediaPreviewer({
    required this.mediaUrls,
    this.initialIndex = 0,
    Key? key,
  }) : super(key: key);

  @override
  _MediaPreviewerState createState() => _MediaPreviewerState();
}

class _MediaPreviewerState extends State<MediaPreviewer> {
  late PageController
  _pageController; // Controlador para el desplazamiento entre páginas.
  late int _currentIndex; // Índice de la página actual.

  // Función que maneja la eliminación de un archivo.
  Future<void> _deleteMedia(String url) async {
    final success = await RetrofitInstanceForWorks().apiServiceForWorks
        .deleteWorkMedia(url); // Llamada al servicio para eliminar el archivo.
    if (success.success == true) {
      setState(() {
        widget.mediaUrls.remove(url); // Elimina el archivo de la lista.
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.fileDeletedSuccessfully),
        ), // Mensaje de éxito.
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.fileDeleteError}: ${success.error}',
          ), // Mensaje de error.
        ),
      );
    }
  }

  // Función que muestra el diálogo de confirmación para la eliminación de un archivo.
  void _showDeleteConfirmationDialog(String url) {
    final colorScheme = ColorPalette.getPalette(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                colorScheme[AppStrings.primaryColor], // Fondo del diálogo
            title: Text(
              AppStrings.deleteConfirmationTitle,
              style: TextStyle(
                color: colorScheme[AppStrings.secondaryColor],
              ), // Título en color secundario
            ),
            content: Text(
              url.toLowerCase().endsWith('.mp4')
                  ? AppStrings.deleteVideoConfirmation
                  : AppStrings.deleteImageConfirmation,
              style: TextStyle(
                color: colorScheme[AppStrings.secondaryColor],
              ), // Contenido en color secundario
            ),
            actions: [
              // Botones de acción en el diálogo
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo.
                },
                child: Text(
                  AppStrings.cancel,
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ), // Botón cancelar en color secundario.
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo.
                  _deleteMedia(
                    url,
                  ); // Llama a la función para eliminar el archivo.
                },
                child: Text(
                  AppStrings.delete,
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ), // Botón eliminar en color secundario.
                ),
              ),
            ],
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // Establece el índice inicial.
    _pageController = PageController(
      initialPage: widget.initialIndex,
    ); // Configura el controlador de la página.
  }

  @override
  void dispose() {
    _pageController
        .dispose(); // Libera los recursos del controlador cuando ya no se necesita.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor:
          colorScheme[AppStrings.primaryColor] ??
          Colors.black, // Fondo de la pantalla.
      body: Stack(
        children: [
          // Visor de páginas para mostrar imágenes o videos.
          PageView.builder(
            controller: _pageController, // Controlador de la página.
            itemCount: widget.mediaUrls.length, // Número total de elementos.
            onPageChanged: (index) {
              setState(() {
                _currentIndex =
                    index; // Actualiza el índice cuando se cambia la página.
              });
            },
            itemBuilder: (context, index) {
              final url = widget.mediaUrls[index];
              // Verifica si la URL corresponde a un video o una imagen.
              if (url.toLowerCase().endsWith('.mp4')) {
                return VideoPlayerWidget(url: url); // Muestra el video.
              } else {
                return Center(
                  child: InteractiveViewer(
                    panEnabled: true, // Permite desplazarse por la imagen.
                    minScale: 0.8, // Escala mínima.
                    maxScale: 4.0, // Escala máxima.
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                    ), // Muestra la imagen.
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
                children: [
                  // Botón para eliminar el archivo actual.
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
                  // Botón para cerrar la vista previa.
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme[AppStrings.secondaryColor],
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context), // Cierra la vista.
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
