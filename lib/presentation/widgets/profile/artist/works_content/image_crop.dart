/*
 * Fecha de creación: 2025-04-26
 * Autor: KingdomOfJames
 * Descripción: 
 *  Esta pantalla permite al usuario recortar una imagen. Al recibir la URI de la imagen, se utiliza la librería `image_cropper` para abrir una interfaz de recorte con un aspecto cuadrado. 
 *  Una vez que el usuario recorta la imagen, el resultado es devuelto a través de la función `onImageCropped`.
 * 
 * Recomendaciones:
 *  - Verifica que el archivo recibido sea una imagen válida antes de intentar recortarla.
 *  - Agrega un manejo de errores adecuado en caso de que el proceso de recorte falle o el archivo no sea accesible.
 *  - Considera agregar un indicador de carga para mejorar la experiencia del usuario si el recorte tarda más tiempo.
 * 
 * Características:
 *  - Recorta imágenes con una relación de aspecto cuadrada.
 *  - Proporciona una interfaz sencilla para recortar imágenes con botones personalizables.
 *  - Usa la librería `image_cropper` para la funcionalidad de recorte.
 */

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:live_music/presentation/resources/strings.dart';

class ImageCropScreen extends StatelessWidget {
  final Uri imageUri; // URI de la imagen que será recortada.
  final Function(Uri)
  onImageCropped; // Función que se ejecutará cuando la imagen sea recortada.

  ImageCropScreen({required this.imageUri, required this.onImageCropped});

  @override
  Widget build(BuildContext context) {
    // Inicia el proceso de recorte de imagen una vez que la pantalla ha sido construida.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Llamada a la librería `image_cropper` para recortar la imagen.
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageUri.path, // Ruta de la imagen original.
        aspectRatio: const CropAspectRatio(
          ratioX: 1.0,
          ratioY: 1.0,
        ), // Relación de aspecto cuadrada.
        compressFormat:
            ImageCompressFormat.jpg, // Formato de compresión (JPEG).
        compressQuality: 100, // Calidad de la imagen recortada.
        uiSettings: [
          // Configuración de la interfaz de usuario para Android.
          AndroidUiSettings(
            toolbarTitle:
                AppStrings
                    .cropImageTitle, // Título de la barra de herramientas.
            toolbarColor:
                Colors.deepOrange, // Color de la barra de herramientas.
            toolbarWidgetColor:
                Colors.white, // Color de los iconos en la barra.
            initAspectRatio:
                CropAspectRatioPreset
                    .square, // Relación de aspecto inicial (cuadrada).
            lockAspectRatio: true, // Bloqueo de la relación de aspecto.
          ),
          // Configuración de la interfaz de usuario para iOS.
          IOSUiSettings(title: AppStrings.cropImageTitle),
        ],
      );

      // Si la imagen fue recortada exitosamente, se llama a la función `onImageCropped`.
      if (croppedFile != null) {
        onImageCropped(
          Uri.parse(croppedFile.path),
        ); // Llamada con la nueva URI de la imagen recortada.
      }
    });

    // Estructura de la pantalla con un indicador de carga mientras se recorta la imagen.
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.cropImageTitle),
      ), // Título de la pantalla.
      body: const Center(
        child: CircularProgressIndicator(),
      ), // Indicador de progreso en el centro de la pantalla.
    );
  }
}
