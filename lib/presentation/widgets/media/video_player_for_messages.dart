// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
//
// Descripción: Este widget muestra un reproductor de video para reproducir un archivo de video desde el dispositivo del usuario.
// Se utiliza el paquete `video_player` para cargar y reproducir el video. Mientras se carga el video, se muestra un indicador de progreso.
//
// Recomendaciones:
// - Verificar la compatibilidad de archivos de video antes de intentar reproducirlos.
// - Se puede mejorar la experiencia del usuario agregando controles de reproducción (pausar, detener, avanzar, etc.).
//
// Características:
// - Permite la reproducción de videos locales (en este caso, desde un archivo específico).
// - Muestra un indicador de carga mientras el video se inicializa.
// - Reproduce automáticamente el video una vez que se ha inicializado correctamente.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final File file; // El archivo de video a reproducir

  VideoPlayerWidget({required this.file});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController
  _controller; // Controlador para el reproductor de video

  @override
  void initState() {
    super.initState();
    // Inicializa el controlador con el archivo de video proporcionado y comienza la reproducción
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(
          () {},
        ); // Redibuja el widget cuando el video se ha inicializado
        _controller.play(); // Reproduce el video automáticamente
      });
  }

  @override
  void dispose() {
    // Libera los recursos del controlador cuando el widget ya no está en uso
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verifica si el controlador está inicializado antes de mostrar el reproductor de video
    return _controller.value.isInitialized
        ? AspectRatio(
          aspectRatio:
              _controller
                  .value
                  .aspectRatio, // Ajusta la relación de aspecto del video
          child: VideoPlayer(_controller), // Muestra el reproductor de video
        )
        : Center(
          child: CircularProgressIndicator(),
        ); // Muestra el indicador de carga mientras se inicializa
  }
}
