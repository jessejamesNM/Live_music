/*
  Fecha de creación: 26 de abril de 2025
  Autor: KingdomOfJames

  Descripción:
  Esta pantalla permite previsualizar una imagen o video seleccionado. El archivo seleccionado puede ser una imagen o video que el usuario ha seleccionado, y se muestra en la pantalla para su revisión antes de enviarlo. La pantalla también permite al usuario cambiar el archivo (imagen o video) si lo desea, y ofrece la opción de enviar el archivo.

  Recomendaciones:
  - Asegúrate de que el archivo no exceda los límites de duración si es un video (5 minutos).
  - Utiliza esta pantalla como parte de una funcionalidad de chat para enviar imágenes y videos.
  - Considera mostrar un mensaje de error si el archivo no se puede cargar correctamente.

  Características:
  - Muestra una imagen o video en una interfaz limpia y atractiva.
  - Ofrece la opción de cambiar el archivo seleccionado.
  - Permite reproducir videos con controles de pausa y reproducción.
  - Permite enviar archivos a un chat y manejar posibles errores de forma amigable.

  Comentarios del código:
  - El código está estructurado para mostrar la previsualización del archivo seleccionado.
  - Si el archivo es un video, se utiliza un controlador de `VideoPlayerController` para mostrarlo.
  - Si el archivo es una imagen, se utiliza un widget `Image.file` para mostrarla.
  - Se incluye la funcionalidad para enviar el archivo y manejar posibles errores.
*/

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:video_player/video_player.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/messages/messages_provider.dart';
import '../../../data/provider_logics/user/user_provider.dart';

class ImagePreviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Obtener los datos del proveedor de mensajes y del proveedor de usuario
    final messagesProvider = Provider.of<MessagesProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    // Obtener el archivo seleccionado para previsualizar
    final selectedMediaFile = messagesProvider.selectedImageFile.value;

    // Obtener los ID del usuario actual y el otro usuario
    final currentUserId =  FirebaseAuth.instance.currentUser?.uid;
    final otherUserId = userProvider.otherUserId;

    // Obtener la paleta de colores para la interfaz
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColorLight],
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 35.0, bottom: 20.0),
        child: selectedMediaFile != null
            ? Stack(
                children: [
                  // Mostrar la imagen o el video seleccionado en el centro
                  Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: ClipRect(
                        child: selectedMediaFile.path.toLowerCase().endsWith('.mp4') ||
                                selectedMediaFile.path.toLowerCase().endsWith('.mov')
                            ? _VideoPreview(file: selectedMediaFile)
                            : Image.file(
                                selectedMediaFile,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Manejar error de imagen inválida
                                  return Center(
                                    child: Text(
                                      'Error al cargar el archivo',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                  // Botón para cerrar la pantalla de previsualización
                  Positioned(
                    top: 0,
                    left: 16,
                    child: IconButton(
                      onPressed: () {
                        messagesProvider.clearSelectedImageFile();
                        context.pop();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: CircleBorder(),
                      ),
                      icon: Icon(
                        Icons.close,
                        color: colorScheme[AppStrings.primaryColorLight],
                      ),
                    ),
                  ),
                  // Texto en la parte superior para indicar el tipo de archivo
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        selectedMediaFile.path.toLowerCase().endsWith('.mp4') ||
                                selectedMediaFile.path.toLowerCase().endsWith('.mov')
                            ? AppStrings.sendVideo
                            : AppStrings.sendImage,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  // Botón para enviar el archivo
                  Positioned(
                    bottom: 0,
                    right: 16,
                    child: IconButton(
                      onPressed: () async {
                        // Mostrar mensaje de "enviando"
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.sendingMessage),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        // Navegar inmediatamente
                        messagesProvider.clearSelectedImageFile();
                        context.pop();

                        // Verificar si el archivo es un video y tiene una duración válida
                        if (selectedMediaFile.path.toLowerCase().endsWith('.mp4') ||
                            selectedMediaFile.path.toLowerCase().endsWith('.mov')) {
                          final controller = VideoPlayerController.file(
                            selectedMediaFile,
                          );
                          try {
                            await controller.initialize();
                            final duration = controller.value.duration;
                            if (duration > Duration(minutes: 5)) {
                              // Mostrar error si el video excede los 5 minutos
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppStrings.videoDurationLimit,
                                    ),
                                  ),
                                );
                              });
                              return;
                            }
                          } catch (e) {
                            // Manejar error de video inválido
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'El video no es válido o no se puede reproducir',
                                  ),
                                ),
                              );
                            });
                            return;
                          } finally {
                            controller.dispose();
                          }
                        }

                        // Enviar el mensaje en segundo plano
                        messagesProvider
                            .sendMessage(
                              context,
                              "",
                              selectedMediaFile,
                              currentUserId?? '',
                              otherUserId,
                            )
                            .catchError((error) {
                          // Manejar errores durante el envío
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppStrings.messageSendError,
                                ),
                              ),
                            );
                          });
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: CircleBorder(),
                      ),
                      icon: Icon(
                        Icons.send,
                        color: colorScheme[AppStrings.primaryColorLight],
                        size: 24,
                      ),
                    ),
                  ),
                  // Botón para cambiar el archivo seleccionado
                  Positioned(
                    bottom: 34,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          if (selectedMediaFile.path.toLowerCase().endsWith('.mp4') ||
                              selectedMediaFile.path.toLowerCase().endsWith('.mov')) {
                            final pickedVideo = await picker.pickVideo(
                              source: ImageSource.gallery,
                            );
                            if (pickedVideo != null) {
                              messagesProvider.updateSelectedImageFile(
                                File(pickedVideo.path),
                              );
                            }
                          } else {
                            final pickedImage = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedImage != null) {
                              messagesProvider.updateSelectedImageFile(
                                File(pickedImage.path),
                              );
                            }
                          }
                        },
                        child: Text(
                          AppStrings.changeFile,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(child: Text(AppStrings.noFileSelected)),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final File file;
  const _VideoPreview({required this.file});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;
  bool _isPlaying = true;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized || _hasError) return;
    
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Text(
          'Error al cargar el video',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (!_isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Usamos AspectRatio para mantener la proporción correcta del video
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (!_isPlaying)
            Icon(Icons.play_arrow, size: 64, color: Colors.white70),
        ],
      ),
    );
  }
}