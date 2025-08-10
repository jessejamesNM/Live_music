/*
  Fecha de creación: 26 de abril de 2025
  Autor: KingdomOfJames

  Descripción:
  Esta pantalla es una vista previa de medios en un chat, diseñada para mostrar imágenes o reproducir videos de forma elegante.
  Permite que el usuario vea contenido multimedia recibido o enviado en una conversación.

  Características:
  - Permite previsualizar imágenes con zoom usando `InteractiveViewer`.
  - Permite reproducir videos directamente desde una URL usando `video_player`.
  - Reproduce los videos en bucle automático.
  - Fondo negro para dar mayor protagonismo al contenido multimedia.
  - Permite pausar/reanudar el video con un simple toque.

  Recomendaciones:
  - Considerar agregar manejo de errores por si la URL del video o imagen falla.
  - Agregar controles de volumen o barra de progreso para mejorar la experiencia de usuario.
  - Agregar un botón para descargar el medio o compartirlo si se desea más funcionalidad.
  - Optimizar la carga del video mostrando una miniatura previa mientras carga.
  - Usar `CachedNetworkImage` para optimizar la carga de imágenes.

  Comentarios generales del código:
  - La estructura es clara y separa correctamente las responsabilidades (`StatelessWidget` para la pantalla general y `StatefulWidget` para el video).
  - Se maneja correctamente el ciclo de vida del `VideoPlayerController` (se inicializa y se libera memoria en `dispose`).
  - El uso de `GestureDetector` hace que la interacción para pausar/reanudar sea intuitiva para el usuario.
*/

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// Pantalla principal que muestra una imagen o un video según el tipo de medio.
class MediaPreviewPageChat extends StatelessWidget {
  final String mediaUrl; // URL del medio a mostrar.
  final bool isVideo; // Indica si el medio es un video o una imagen.

  const MediaPreviewPageChat({
    Key? key,
    required this.mediaUrl,
    required this.isVideo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro para resaltar el contenido.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Iconos en blanco.
        elevation: 0, // Sin sombra en el AppBar.
      ),
      body: Center(
        // Según el tipo de medio, muestra un video o una imagen.
        child:
            isVideo
                ? FullVideoPlayerChat(url: mediaUrl)
                : InteractiveViewer(
                  child: Image.network(mediaUrl),
                ), // Permite hacer zoom en imágenes.
      ),
    );
  }
}

// Widget que se encarga de reproducir un video completo.
class FullVideoPlayerChat extends StatefulWidget {
  final String url; // URL del video.

  const FullVideoPlayerChat({required this.url});

  @override
  State<FullVideoPlayerChat> createState() => FullVideoPlayerState();
}

// Estado que maneja el reproductor de video.
class FullVideoPlayerState extends State<FullVideoPlayerChat> {
  late VideoPlayerController _controller; // Controlador del video.

  @override
  void initState() {
    super.initState();
    // Inicializa el controlador con la URL del video.
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {}); // Actualiza el estado cuando el video está listo.
        _controller.setLooping(
          true,
        ); // Configura el video para que se repita en bucle.
        _controller.play(); // Inicia automáticamente la reproducción.
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // Libera los recursos del controlador al salir.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mientras el video no esté inicializado, muestra un indicador de carga.
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause(); // Si el video está reproduciéndose, lo pausa.
          } else {
            _controller.play(); // Si está pausado, lo reproduce.
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Muestra el video respetando su relación de aspecto original.
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          // Si el video está pausado, muestra un ícono de reproducción en el centro.
          if (!_controller.value.isPlaying)
            Icon(
              Icons.play_circle_fill,
              size: 64,
              color: Colors.white.withOpacity(0.7),
            ),
        ],
      ),
    );
  }
}
