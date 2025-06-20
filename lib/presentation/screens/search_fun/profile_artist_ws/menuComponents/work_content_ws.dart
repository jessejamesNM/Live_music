// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
//
// Descripción:
// Esta pantalla es parte de una aplicación que maneja y presenta contenido multimedia de los trabajos de un usuario.
// Se carga el contenido de los trabajos, ya sea imágenes o videos, y se presentan en una cuadrícula. Al tocar uno de los elementos,
// se muestra una vista previa en detalle del medio (ya sea imagen o video).
//
// Recomendaciones:
// 1. Asegúrate de que el `ApiServiceForWorks` esté correctamente configurado y esté devolviendo URLs de medios válidas.
// 2. Si se presentan errores al cargar el contenido, revisa la lógica de manejo de errores y asegúrate de que la API esté funcionando correctamente.
// 3. Considera agregar un control de acceso o validación para verificar si el usuario tiene permisos para ver el contenido.
// 4. Podrías optimizar el manejo de imágenes, especialmente si se manejan archivos grandes, utilizando carga diferida o cacheo de imágenes.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';

import 'package:live_music/presentation/widgets/media/video_player_for_works.dart';
import 'package:live_music/presentation/widgets/media/videp_tumb_nail_for_works.dart';

import 'package:provider/provider.dart';

import '../../../../../data/provider_logics/user/user_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../../../data/repositories/render_http_client/images/upload_work_image.dart';

class WorksContentWS extends StatefulWidget {
  const WorksContentWS({Key? key}) : super(key: key);

  @override
  _WorksContentStateWS createState() => _WorksContentStateWS();
}

class _WorksContentStateWS extends State<WorksContentWS> {
  final ApiServiceForWorks _api = RetrofitInstanceForWorks().apiServiceForWorks;
  List<String> _mediaUrls = []; // Lista de URLs de medios a mostrar
  late final String otherUserId;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    otherUserId = userProvider.otherUserId; // Obtiene el ID del usuario
    _fetchMedia(); // Carga el contenido multimedia cuando la pantalla se inicializa
  }

  // Función que obtiene el contenido multimedia del servidor
  Future<void> _fetchMedia() async {
    try {
      final resp = await _api.getWorkMedia(
        otherUserId,
      ); // Solicita el contenido multimedia para el usuario
      if (resp.mediaUrls != null) {
        setState(
          () => _mediaUrls = resp.mediaUrls!,
        ); // Si hay URLs, se almacenan en la lista
      }
    } catch (e) {
      debugPrint(' $e'); // Manejo de errores en la carga de medios
    }
  }

  // Verifica si una URL corresponde a un video basado en su extensión
  bool _isVideo(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any(
      (ext) => lowerUrl.endsWith(ext),
    ); // Retorna verdadero si es video
  }

  // Función para construir cada ítem de la cuadrícula
  Widget _buildMediaItem(
    String url,
    int index,
    Map<String, Color> colorScheme,
  ) {
    final isVideo = _isVideo(url); // Verifica si es un video

    return GestureDetector(
      onTap: () {
        // Al hacer clic, se navega a una vista previa de medios
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    MediaPreviewer(mediaUrls: _mediaUrls, initialIndex: index),
          ),
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(
              12,
            ), // Redondea las esquinas de las imágenes
            child:
                isVideo
                    ? VideoThumbnail(
                      url: url,
                      width: double.infinity,
                      height: double.infinity,
                    ) // Si es un video, muestra el thumbnail del video
                    : Image.network(
                      url,
                      width: double.infinity,
                      height: double.infinity,
                      fit:
                          BoxFit
                              .cover, // Ajusta la imagen para cubrir el área del contenedor
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null)
                          return child; // Muestra la imagen directamente si no está cargando
                        return const Center(
                          child: SizedBox.shrink(), // Sin loader interno
                        );
                      },
                      errorBuilder:
                          (_, __, ___) => Container(
                            color:
                                colorScheme['primaryColorLight']!, // Color de fondo si hay un error
                            child: Icon(
                              Icons.broken_image,
                              color:
                                  colorScheme['secondaryColor'], // Icono de error si la imagen no carga
                            ),
                          ),
                    ),
          ),
          if (isVideo)
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons
                      .play_circle_fill, // Icono de reproducción si es un video
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
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene el esquema de colores

    return Container(
      color: colorScheme['primaryColor'], // Color de fondo de la pantalla
      constraints: BoxConstraints(
        minHeight:
            MediaQuery.of(
              context,
            ).size.height, // Ajusta el tamaño mínimo de la pantalla
      ),
      child:
          _mediaUrls.isEmpty
              ? Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    AppStrings
                        .noContentMessage, // Mensaje si no hay contenido multimedia
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme['secondaryColor'], // Color del mensaje
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Deshabilita el desplazamiento de la cuadrícula
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: _mediaUrls.length,
                itemBuilder:
                    (context, idx) =>
                        _buildMediaItem(_mediaUrls[idx], idx, colorScheme),
              ),
    );
  }
}

// Widget para mostrar una vista previa de los medios seleccionados
class MediaPreviewer extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const MediaPreviewer({
    required this.mediaUrls,
    this.initialIndex = 0,
    Key? key,
  }) : super(key: key);

  @override
  _MediaPreviewerState createState() => _MediaPreviewerState();
}

class _MediaPreviewerState extends State<MediaPreviewer> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialIndex,
    ); // Controlador de página para la vista previa
  }

  @override
  void dispose() {
    _pageController
        .dispose(); // Limpia el controlador cuando el widget se destruya
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene el esquema de colores

    return Scaffold(
      backgroundColor:
          colorScheme[AppStrings.primaryColor] ??
          Colors.black, // Fondo oscuro para la vista previa
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaUrls.length,
            itemBuilder: (context, index) {
              final url = widget.mediaUrls[index];
              if (url.toLowerCase().endsWith('.mp4')) {
                return VideoPlayerWidget(
                  url: url,
                ); // Muestra el video si es un archivo de video
              } else {
                return Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                    ), // Muestra la imagen si no es un video
                  ),
                );
              }
            },
          ),
          Positioned(
            top: 40,
            right: 16,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color:
                      colorScheme[AppStrings
                          .secondaryColor], // Icono para cerrar la vista previa
                  size: 30,
                ),
                onPressed:
                    () => Navigator.pop(
                      context,
                    ), // Cierra la vista previa al presionar el icono
              ),
            ),
          ),
        ],
      ),
    );
  }
}
