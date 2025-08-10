// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: Este widget es un reproductor de video personalizable que se adapta al contenido de un URL proporcionado.
//              Permite controlar la reproducción, pausar y reanudar el video mediante un ícono interactivo. Además, muestra
//              el progreso del video con un control deslizante para avanzar o retroceder en el video. Ideal para implementar
//              en aplicaciones que necesiten mostrar contenido de video en streaming.
// Recomendaciones: Asegúrate de proporcionar un URL válido para el video. Este widget usa el paquete `video_player`
//                  de Flutter, por lo que es necesario agregarlo a las dependencias de tu proyecto.
// Características:
//   - Control de reproducción y pausa mediante íconos interactivos.
//   - Muestra el progreso de la duración del video con un slider.
//   - Funciona con videos en streaming desde una URL.
//   - El video se reproduce en bucle por defecto.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({required this.url, Key? key}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller; // Controlador para el video.
  late Future<void>
  _initializeVideoPlayerFuture; // Futuro para la inicialización del controlador.
  bool _showPlayIcon = false; // Estado para mostrar o no el ícono de play.

  @override
  void initState() {
    super.initState();
    // Inicialización del controlador de video con la URL proporcionada.
    _controller =
        VideoPlayerController.network(widget.url)
          ..setLooping(true) // Habilitar el bucle del video.
          ..setVolume(1.0); // Configuración del volumen al máximo.

    _initializeVideoPlayerFuture =
        _controller.initialize(); // Esperar la inicialización del controlador.

    _controller.addListener(() {
      if (mounted)
        setState(() {}); // Actualizar la UI cuando cambie el estado del video.
    });
  }

  @override
  void dispose() {
    _controller
        .dispose(); // Liberar el controlador cuando el widget se destruya.
    super.dispose();
  }

  // Función para cambiar entre reproducción y pausa.
  void _togglePlayback() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause(); // Pausar el video si está en reproducción.
        _showPlayIcon = true; // Mostrar el ícono de play.
      } else {
        _controller.play(); // Reproducir el video si está pausado.
        _showPlayIcon = false; // Ocultar el ícono de play.
      }
    });
  }

  // Función para formatear la duración del video (minutos:segundos).
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future:
          _initializeVideoPlayerFuture, // Esperar la inicialización del video.
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final videoAspectRatio =
              _controller
                  .value
                  .aspectRatio; // Obtener el ratio de aspecto del video.
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reproductor de video que ocupa el espacio disponible.
                Flexible(
                  child: GestureDetector(
                    onTap:
                        _togglePlayback, // Cambiar entre reproducción y pausa al tocar.
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio:
                              videoAspectRatio, // Mantener el ratio de aspecto del video.
                          child: VideoPlayer(_controller), // Mostrar el video.
                        ),
                        // Mostrar el ícono de play si el video está pausado.
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
                        // Mostrar la posición actual del video.
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
                              min: 0, // Mínimo valor del slider.
                              max:
                                  _controller.value.duration.inMilliseconds
                                      .toDouble(), // Duración total del video.
                              value:
                                  _controller.value.position.inMilliseconds
                                      .clamp(
                                        0,
                                        _controller
                                            .value
                                            .duration
                                            .inMilliseconds,
                                      )
                                      .toDouble(), // Valor actual del slider.
                              onChanged: (value) {
                                _controller.seekTo(
                                  Duration(
                                    milliseconds: value.toInt(),
                                  ), // Mover el video al valor del slider.
                                );
                              },
                              activeColor:
                                  Colors.redAccent, // Color activo del slider.
                              inactiveColor:
                                  Colors.grey, // Color inactivo del slider.
                            ),
                          ),
                        ),
                        // Mostrar la duración total del video.
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
          // Mostrar un indicador de carga mientras se inicializa el video.
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
