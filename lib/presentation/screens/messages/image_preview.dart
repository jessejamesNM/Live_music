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
    final messagesProvider = Provider.of<MessagesProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final selectedMediaFile = messagesProvider.selectedImageFile.value;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final otherUserId = userProvider.otherUserId;
    final colorScheme = ColorPalette.getPalette(context);

    // Tamaños adaptativos
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = screenHeight * 0.05;
    final bottomPadding = screenHeight * 0.03;
    final iconSize = screenWidth * 0.08;
    final textSize = screenWidth * 0.05;
    final sendButtonSize = screenWidth * 0.1;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColorLight],
      body: SafeArea(
        minimum: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: selectedMediaFile != null
            ? Stack(
                children: [
                  // Imagen o video central
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.7,
                        maxWidth: screenWidth * 0.9,
                      ),
                      child: ClipRect(
                        child: selectedMediaFile.path.toLowerCase().endsWith('.mp4') ||
                                selectedMediaFile.path.toLowerCase().endsWith('.mov')
                            ? _VideoPreview(file: selectedMediaFile)
                            : Image.file(
                                selectedMediaFile,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: iconSize,
                                      color: Colors.white70,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                  // Botón cerrar
                  Positioned(
                    top: 0,
                    left: screenWidth * 0.04,
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
                        size: iconSize,
                      ),
                    ),
                  ),
                  // Tipo de archivo
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          selectedMediaFile.path.toLowerCase().endsWith('.mp4') ||
                                  selectedMediaFile.path.toLowerCase().endsWith('.mov')
                              ? AppStrings.sendVideo
                              : AppStrings.sendImage,
                          style: TextStyle(
                            fontSize: textSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Botón enviar
                  Positioned(
                    bottom: 0,
                    right: screenWidth * 0.04,
                    child: IconButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.sendingMessage),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        messagesProvider.clearSelectedImageFile();
                        context.pop();

                        if (selectedMediaFile.path.toLowerCase().endsWith('.mp4') ||
                            selectedMediaFile.path.toLowerCase().endsWith('.mov')) {
                          final controller = VideoPlayerController.file(selectedMediaFile);
                          try {
                            await controller.initialize();
                            if (controller.value.duration > Duration(minutes: 5)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppStrings.videoDurationLimit)),
                                );
                              });
                              return;
                            }
                          } catch (e) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('El video no es válido')),
                              );
                            });
                            return;
                          } finally {
                            controller.dispose();
                          }
                        }

                        messagesProvider
                            .sendMessage(
                              context,
                              "",
                              selectedMediaFile,
                              currentUserId ?? '',
                              otherUserId,
                            )
                            .catchError((_) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppStrings.messageSendError)),
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
                        size: sendButtonSize,
                      ),
                    ),
                  ),
                  // Cambiar archivo
                  Positioned(
                    bottom: screenHeight * 0.08,
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
                              messagesProvider.updateSelectedImageFile(File(pickedVideo.path));
                            }
                          } else {
                            final pickedImage = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedImage != null) {
                              messagesProvider.updateSelectedImageFile(File(pickedImage.path));
                            }
                          }
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppStrings.changeFile,
                            style: TextStyle(
                              fontSize: textSize * 0.9,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppStrings.noFileSelected,
                    style: TextStyle(fontSize: textSize),
                  ),
                ),
              ),
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
          setState(() => _isInitialized = true);
          _controller.setLooping(true);
          _controller.play();
        }
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
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
      return Center(child: Text('Error al cargar el video', style: TextStyle(color: Colors.white)));
    }
    if (!_isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (!_isPlaying)
            Icon(Icons.play_arrow, size: MediaQuery.of(context).size.width * 0.15, color: Colors.white70),
        ],
      ),
    );
  }
}