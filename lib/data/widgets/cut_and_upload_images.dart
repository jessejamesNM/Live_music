/*
  Fecha de creación: 26 de abril de 2025
  Autor: KingdomOfJames
  Descripción:
    Clase encargada de gestionar la selección, recorte y carga de imágenes de perfil o trabajos
    (works) de los usuarios en la aplicación. Permite al usuario elegir una imagen de su galería,
    recortarla en formato cuadrado, y luego cargarla al servidor correspondiente.
    
    Recomendaciones:
    - Agregar validaciones adicionales para formatos o tamaños máximos permitidos de imágenes.
    - Manejar mejor los errores para casos como red lenta o interrupciones al subir.
    - Considerar mostrar un 'loader' o indicador de progreso durante la subida.
    
    Características:
    - Permite seleccionar imágenes desde la galería.
    - Recorta imágenes en proporción 1:1 antes de subirlas.
    - Carga imágenes a diferentes endpoints según el tipo ('profiles' o 'works').
    - Usa `UserProvider` para actualizar el estado de la imagen de perfil automáticamente.
*/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/data/repositories/render_http_client/images/upload_profile_image.dart';
import 'package:live_music/data/repositories/render_http_client/images/upload_work_image.dart';
import 'package:live_music/presentation/resources/colors.dart';

/// Clase que maneja la selección, recorte y carga de imágenes de perfil o trabajos
class ProfileImageHandler {
  /// Método principal para manejar el flujo de imagen
  ///
  /// [imageType]: 'profiles' para imagen de perfil, 'works' para imágenes de trabajos.
  /// [userProvider]: Proveedor de usuario para actualizar y obtener la nueva imagen.
  /// [onImageUploaded]: Callback que se ejecuta cuando la imagen fue subida exitosamente.
  static Future<void> handle({
    required BuildContext context,
    required String imageType,
    required UserProvider userProvider,
    required void Function(String imageUrl) onImageUploaded,
  }) async {
    // Obtener esquema de colores para los componentes de recorte
    final colorScheme = ColorPalette.getPalette(context);

    // Inicializar selector de imágenes
    final picker = ImagePicker();

    // Abrir galería y permitir al usuario seleccionar una imagen
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    // Si el usuario no seleccionó imagen, cancelar
    if (pickedFile == null) return;

    // Recortar la imagen seleccionada con proporción 1:1 (cuadrado)
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar imagen',
          toolbarColor: colorScheme['primaryColor'],
          toolbarWidgetColor: colorScheme['secondaryColor'],
          activeControlsWidgetColor: colorScheme['essentialColor'],
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          backgroundColor: colorScheme['primaryColor'],
        ),
        IOSUiSettings(title: 'Recortar imagen', aspectRatioLockEnabled: true),
      ],
    );

    // Si el usuario cancela el recorte, cancelar
    if (croppedFile == null) return;

    try {
      // Convertir archivo recortado en objeto File
      final file = File(croppedFile.path);
      final currentUserId = userProvider.currentUserId;

      // Según el tipo de imagen, proceder diferente
      if (imageType == 'profiles') {
        // Subir imagen de perfil
        final profileUploader = UploadProfileImagesToServer();
        await profileUploader.uploadProfileImage(currentUserId, file);

        // Actualizar la información del usuario localmente
        userProvider.loadUserData(currentUserId);

        // Obtener nueva URL de la imagen
        final String? newImageUrl = userProvider.profileImageUrl;

        // Verificar que la URL no sea nula ni vacía y ejecutar callback
        if (newImageUrl != null && newImageUrl.isNotEmpty) {
          onImageUploaded(newImageUrl);
        } else {
          throw Exception("La URL de la imagen de perfil no está disponible.");
        }
      } else if (imageType == 'works') {
        // Subir imagen de trabajo
        final worksUploader = RetrofitInstanceForWorks().apiServiceForWorks;
        final resp = await worksUploader.uploadImage(file, currentUserId);

        // Verificar que la respuesta contenga URL y ejecutar callback
        if (resp.url != null && resp.url!.isNotEmpty) {
          onImageUploaded(resp.url!);
        } else {
          throw Exception(
            "Error al subir imagen de work: ${resp.error ?? 'Desconocido'}",
          );
        }
      } else {
        // Tipo de imagen no soportado
        throw Exception("Tipo de imagen no soportado: $imageType");
      }
    } catch (e) {
      // Mostrar error de manera segura en la UI
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al subir la imagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
