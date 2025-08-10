/*
 * Fecha de creación: 2025-04-26
 * Autor: KingdomOfJames
 * Descripción: 
 *  Esta función muestra un cuadro de diálogo que permite previsualizar un archivo multimedia (imagen o video) antes de enviarlo. 
 *  Dependiendo de la extensión del archivo (`.mp4` para videos o cualquier otra extensión para imágenes), se muestra un widget adecuado para cada tipo de medio.
 * 
 * Recomendaciones:
 *  - Asegúrate de manejar adecuadamente los errores en caso de que el archivo no se pueda cargar o tenga un formato incorrecto.
 *  - Puedes considerar añadir un indicador de carga si el archivo tarda mucho en mostrarse, especialmente en redes lentas.
 * 
 * Características:
 *  - Previsualiza imágenes o videos antes de enviarlos.
 *  - Botones para cancelar o enviar el archivo.
 *  - Utiliza un `AlertDialog` para mostrar la vista previa en una interfaz modal.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/media/video_player_for_messages.dart';

// Función para mostrar el cuadro de diálogo de previsualización de medios.
void showMediaPreviewDialog(
  BuildContext context,
  File mediaFile, // El archivo multimedia a previsualizar (imagen o video).
  VoidCallback onCancel, // Acción a ejecutar al cancelar.
  VoidCallback onSend, // Acción a ejecutar al enviar.
) {
  // Se muestra un cuadro de diálogo (AlertDialog).
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          content: Column(
            mainAxisSize:
                MainAxisSize
                    .min, // Tamaño de la columna ajustado a su contenido.
            children: [
              // Verifica si el archivo es un video (con extensión .mp4).
              mediaFile.path.endsWith('.mp4')
                  ? AspectRatio(
                    aspectRatio: 16 / 9, // Relación de aspecto para videos.
                    child: VideoPlayerWidget(
                      file: mediaFile,
                    ), // Widget para mostrar el video.
                  )
                  : Image.file(
                    mediaFile,
                  ), // Si no es un video, muestra la imagen.
              SizedBox(
                height: 16,
              ), // Espaciado entre la previsualización y los botones.
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceEvenly, // Distribuye los botones de manera equidistante.
                children: [
                  // Botón para cancelar la previsualización.
                  TextButton(
                    onPressed:
                        onCancel, // Acción que se ejecuta al presionar "Cancelar".
                    child: Text(
                      AppStrings.cancel,
                    ), // Texto del botón "Cancelar".
                  ),
                  // Botón para enviar el archivo multimedia.
                  TextButton(
                    onPressed:
                        onSend, // Acción que se ejecuta al presionar "Enviar".
                    child: Text(AppStrings.send), // Texto del botón "Enviar".
                  ),
                ],
              ),
            ],
          ),
        ),
  );
}
