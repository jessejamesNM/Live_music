// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
//
// Descripción: Este widget se encarga de mostrar una miniatura de video a partir de una URL proporcionada.
// Utiliza el paquete `video_player` para cargar el video y generar una vista previa del contenido,
// pero en lugar de reproducir el video completo, solo muestra el primer fotograma.
//
// Recomendaciones:
// - Asegurarse de que la URL del video sea válida y accesible antes de usarla en este widget.
// - Considerar implementar un control de errores en caso de que el video no se pueda cargar.
// - Este widget es ideal para mostrar una miniatura de videos en una lista o cuadrícula.
//
// Características:
// - Carga el video desde una URL proporcionada.
// - Muestra un indicador de carga hasta que el video esté listo.
// - El video se muestra como una miniatura sin reproducción continua, solo mostrando el primer fotograma.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnail extends StatefulWidget {
  final String url; // URL del video que se usará para generar la miniatura
  final double width, height; // Dimensiones de la miniatura a mostrar

  const VideoThumbnail({
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  late VideoPlayerController _ctrl; // Controlador para el video

  @override
  void initState() {
    super.initState();
    // Inicializa el controlador con la URL proporcionada, cargando el video
    _ctrl = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(
          () {},
        ); // Redibuja el widget cuando el video se ha inicializado
        _ctrl
            .pause(); // Pausa el video para que solo se muestre la miniatura (primer fotograma)
      });
  }

  @override
  void dispose() {
    // Libera los recursos del controlador cuando ya no se necesiten
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si el controlador no está inicializado, muestra un indicador de carga
    if (!_ctrl.value.isInitialized) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(child: CircularProgressIndicator()), // Indicador de carga
      );
    }
    // Una vez inicializado el video, muestra la miniatura
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FittedBox(
        fit: BoxFit.cover, // Ajusta la miniatura al tamaño sin deformarse
        child: SizedBox(
          width:
              _ctrl
                  .value
                  .size
                  .width, // Usando el tamaño del video para la miniatura
          height: _ctrl.value.size.height,
          child: VideoPlayer(_ctrl), // Muestra el primer fotograma del video
        ),
      ),
    );
  }
}
