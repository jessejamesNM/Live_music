/*
  ============================================================================
  Archivo: image_repository.dart
  Fecha de creación: 26 de abril de 2025
  Autor: KingdomOfJames

  Descripción:
    Esta clase gestiona las operaciones relacionadas con imágenes de usuario, 
    tanto en la base de datos local como en un bucket de almacenamiento en la nube (S3).
    Permite obtener, guardar, eliminar y subir imágenes de manera centralizada
    para mantener sincronizados los datos locales y remotos.

  Características:
    - Integración local con base de datos interna usando DAOs (Data Access Objects).
    - Sincronización de imágenes almacenadas en Amazon S3.
    - Uso de Retrofit para comunicaciones API.
    - Conversión de URIs a archivos para permitir la subida a la nube.
    - Subida de imágenes utilizando la librería Dio.

  Recomendaciones:
    - Implementar manejo de errores más robusto (mostrar mensajes al usuario).
    - Mejorar validaciones antes de eliminar o insertar datos.
    - Optimizar la subida de imágenes agregando compresión.
    - Reemplazar todos los `print()` por logs seguros en producción.
  ============================================================================
*/

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:live_music/data/sources/local/internal_data_base.dart';
import 'package:path_provider/path_provider.dart';
import '../render_http_client/images/upload_work_image.dart';

/// Repositorio que gestiona imágenes tanto en almacenamiento local como en la nube.
class ImageRepository {
  late final ImageDao imageDao; // DAO para operaciones de base de datos local
  final BuildContext
  context; // Contexto de la app, en caso de necesitar UI feedback

  /// Constructor que recibe el DAO y el contexto de la app.
  ImageRepository({required this.imageDao, required this.context});

  /// Elimina todas las imágenes locales asociadas a un usuario.
  Future<void> deleteImagesByUser(String userId) async {
    await imageDao.deleteImagesByUser(userId);
  }

  /// Obtiene imágenes desde el bucket S3 y las guarda en la base de datos local.
  Future<void> fetchAndSaveImages(String userId) async {
    await deleteImagesByUser(
      userId,
    ); // Limpia imágenes locales antes de actualizar

    final imagesFromS3 = await getWorkImagesFromS3(
      userId,
    ); // Trae imágenes desde S3
    if (imagesFromS3 != null) {
      for (var imageUrl in imagesFromS3) {
        final imageEntity = ImageEntity(
          id: imageUrl, // Usa la URL como ID
          userId: userId,
          imageUrl: imageUrl,
          timestamp:
              DateTime.now().millisecondsSinceEpoch, // Fecha de inserción
        );
        await imageDao.insert(imageEntity); // Inserta imagen localmente
      }
    }
  }

  /// Obtiene imágenes locales asociadas a un usuario.
  Future<List<ImageEntity>> getLocalImages(String userId) async {
    return await imageDao.getImagesByUser(userId);
  }

  /// Sube una imagen al bucket S3 y devuelve la URL pública resultante.
  Future<String?> uploadImageToS3(Uri uri, String userId) async {
    return await uploadWorkImage(uri, userId);
  }

  /// Obtiene las URLs de imágenes de un usuario almacenadas en S3.
  Future<List<String>?> getWorkImagesFromS3(String userId) async {
    try {
      final response = await RetrofitInstanceForWorks().apiServiceForWorks
          .getWorkMedia(userId);

      if (response.mediaUrls != null) {
        return response.mediaUrls;
      } else {
        // Se podría agregar un manejo de error visual o reporte aquí
        return null;
      }
    } catch (e) {
      // Se podría enviar el error a un sistema de monitoreo en producción
      return null;
    }
  }

  /// Convierte un URI en un archivo físico temporal.
  Future<File?> uriToFile(Uri uri) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/temp_image.jpg');

      final bytes = await File.fromUri(uri).readAsBytes();
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      return null;
    }
  }

  /// Sube una imagen de trabajo a S3 usando Dio manualmente.
  Future<String?> uploadWorkImage(Uri uri, String userId) async {
    final file = await uriToFile(uri);
    if (file == null) return null;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      'user_id': userId,
    });

    try {
      final response = await Dio().post(
        'https://livemusicbucket.onrender.com/upload_work_image',
        data: formData,
      );
      return response.data['url'];
    } catch (e) {
      return null;
    }
  }
}
