// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
//
// Descripción:
// Este widget muestra una miniatura (thumbnail) de un video dentro del chat.
// Carga el video desde una URL de red, lo inicializa, y muestra el primer frame pausado.
//
// Características:
// - Carga el video de forma remota mediante URL.
// - Muestra un loader mientras se inicializa.
// - Ajusta el video para que cubra completamente el área asignada.
// - Detiene el video automáticamente (solo muestra un frame congelado).
//
// Recomendaciones:
// - Asegurarse que la URL del video sea accesible y tenga soporte para streaming.
// - Manejar errores de carga o caídas de red para mejorar la robustez.
// - Optimizar el peso del video para no afectar la experiencia del usuario en chats.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnailChat extends StatefulWidget {
  // Propiedades del widget: URL del video, ancho y alto deseado.
  final String url;
  final double width, height;

  const VideoThumbnailChat({
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  State<VideoThumbnailChat> createState() => VideoThumbnailState();
}

class VideoThumbnailState extends State<VideoThumbnailChat> {
  // Controlador del video player.
  late VideoPlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    // Inicializa el controlador con la URL proporcionada.
    _ctrl = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {}); // Refresca el widget una vez inicializado.
        _ctrl.pause(); // Pausa el video para que solo se vea como miniatura.
      });
  }

  @override
  void dispose() {
    // Libera los recursos del controlador de video al destruir el widget.
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ctrl.value.isInitialized) {
      // Mientras el video no esté listo, muestra un indicador de carga.
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    // Una vez inicializado, muestra el primer frame del video cubriendo el espacio asignado.
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FittedBox(
        fit:
            BoxFit
                .cover, // Ajusta el video para cubrir todo el espacio disponible.
        child: SizedBox(
          width: _ctrl.value.size.width,
          height: _ctrl.value.size.height,
          child: VideoPlayer(_ctrl),
        ),
      ),
    );
  }
}
