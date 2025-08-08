/// -----------------------------------------------------------------------------
/// Fecha de creación: 26 de abril de 2025
/// Autor: KingdomOfJames
///
/// Descripción:
/// Este módulo permite subir imágenes de perfil de los usuarios al servidor.
/// Utiliza la librería Dio para enviar solicitudes HTTP tipo `multipart/form-data`.
/// También convierte URIs locales a archivos temporales y maneja las respuestas del backend.
///
/// Características:
/// - Subida de imágenes de perfil con userId vinculado.
/// - Conversión de URIs a archivos físicos en almacenamiento temporal.
/// - Patrón Singleton para evitar múltiples instancias del cliente.
/// - Modelo de respuesta genérico para manejar la URL o errores de carga.
///
/// Recomendaciones:
/// - Manejar errores de red de forma más robusta para entornos productivos.
/// - Evitar uso de `print` para logs en producción y usar sistemas de logs seguros.
/// - Validar tipo, tamaño y formato de imagen antes de la subida.
/// - Agregar feedback visual al usuario durante la carga.
///
/// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Clase que maneja las solicitudes HTTP relacionadas con la subida de imágenes.
class ApiService {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: 'https://livemusicbucket.onrender.com/'),
  );

  /// Método para subir una imagen de perfil al servidor.
  /// Recibe un archivo [//file] y el identificador del usuario [//userId].
  /// Devuelve una instancia de [//UploadResponse] con la URL de la imagen o un error.
  Future<UploadResponse> uploadProfileImage(File file, String userId) async {
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      'user_id': userId,
    });

    final response = await _dio.post('upload_profile_image', data: formData);
    return UploadResponse.fromJson(response.data);
  }
}

/// Modelo de respuesta para la subida de imágenes.
/// Contiene la URL de la imagen subida o un mensaje de error.
class UploadResponse {
  final String? url;
  final String? error;

  UploadResponse({this.url, this.error});

  /// Método de fábrica para crear una instancia de [//UploadResponse] desde un JSON.
  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(url: json['url'], error: json['error']);
  }
}

/// Modelo de respuesta para obtener imágenes de trabajos.
/// Contiene una lista de URLs de imágenes.
class GetWorkImagesResponse {
  final List<String>? imageUrls;

  GetWorkImagesResponse({this.imageUrls});

  /// Método de fábrica para crear una instancia de [//GetWorkImagesResponse] desde un JSON.
  factory GetWorkImagesResponse.fromJson(Map<String, dynamic> json) {
    return GetWorkImagesResponse(
      imageUrls: List<String>.from(json['image_urls']),
    );
  }
}

/// Cliente Singleton que proporciona acceso a la instancia de [ApiService].
class RetrofitClient {
  static final RetrofitClient _instance = RetrofitClient._internal();
  factory RetrofitClient() => _instance;

  final ApiService apiService;

  RetrofitClient._internal() : apiService = ApiService();
}

/// Clase que maneja la lógica para subir imágenes de perfil al servidor.
/// También convierte URIs a archivos temporales.
class UploadProfileImagesToServer extends ChangeNotifier {
  /// Convierte un [7/Uri] a un archivo físico en almacenamiento temporal.
  /// Devuelve un [//File] o null si ocurre un error.
  Future<File?> uriToFile(BuildContext context, Uri uri) async {
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File('${tempDir.path}/temp_image.jpg');
    final bytes = await context.readAsBytes(uri);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Sube una imagen de perfil al servidor.
  /// Recibe el identificador del usuario [userId] y el archivo de imagen [imageFile].
  Future<void> uploadProfileImage(String userId, File imageFile) async {
    try {
      final uploadResponse = await RetrofitClient().apiService
          .uploadProfileImage(imageFile, userId);
      if (uploadResponse.url != null) {
        // Imagen subida exitosamente.
      } else {
        // Manejo de error en la respuesta.
      }
    } catch (e) {
      // Manejo de errores en la solicitud.
    }
  }
}

/// Extensión para agregar funcionalidad adicional al [BuildContext].
extension on BuildContext {
  /// Lee un [//Uri] y devuelve los bytes como [//Uint8List].
  Future<Uint8List> readAsBytes(Uri uri) async {
    final ByteData data = await DefaultAssetBundle.of(this).load(uri.path);
    return data.buffer.asUint8List();
  }
}
