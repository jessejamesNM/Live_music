import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio para interactuar con la API relacionada con trabajos (works)
class ApiServiceForWorks {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://livemusicbucket.onrender.com/', // URL base de la API
      headers: {
        // Aquí se pueden agregar cabeceras comunes, como Authorization
      },
    ),
  );

  /// Sube una imagen al endpoint /upload_work_image
  Future<UploadResponse> uploadImage(File file, String userId) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last, // Nombre del archivo
      ),
      'user_id': userId, // ID del usuario
    });

    final response = await _dio.post('upload_work_image', data: formData);
    return UploadResponse.fromJson(
      response.data,
    ); // Devuelve la respuesta parseada
  }

  /// Sube un video al endpoint /upload_work_video
  Future<UploadResponse> uploadVideo(File file, String userId) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last, // Nombre del archivo
      ),
      'user_id': userId, // ID del usuario
    });

    final response = await _dio.post('upload_work_video', data: formData);
    return UploadResponse.fromJson(
      response.data,
    ); // Devuelve la respuesta parseada
  }

  /// Obtiene todas las URLs de medios (imágenes y videos) del endpoint /get_work_media
  Future<GetWorkMediaResponse> getWorkMedia(String userId) async {
    final response = await _dio.get(
      'get_work_media',
      queryParameters: {
        'user_id': userId,
      }, // Parámetro de consulta con el ID del usuario
    );
    return GetWorkMediaResponse.fromJson(
      response.data,
    ); // Devuelve la respuesta parseada
  }

  /// Elimina un archivo del bucket S3
  Future<DeleteResponse> deleteWorkMedia(String url) async {
    final response = await _dio.delete('delete_work_media', data: {'url': url});
    return DeleteResponse.fromJson(
      response.data,
    ); // Devuelve la respuesta parseada
  }
}

/// Modelo para la respuesta de subida de archivos
class UploadResponse {
  final String? url; // URL del archivo subido
  final String? error; // Mensaje de error, si ocurre

  UploadResponse({this.url, this.error});

  /// Crea una instancia a partir de un JSON
  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      url: json['url'] as String?,
      error: json['error'] as String?,
    );
  }
}

/// Modelo para la respuesta de eliminación de archivos
class DeleteResponse {
  final bool? success; // Indica si la operación fue exitosa
  final String? error; // Mensaje de error, si ocurre

  DeleteResponse({this.success, this.error});

  /// Crea una instancia a partir de un JSON
  factory DeleteResponse.fromJson(Map<String, dynamic> json) {
    return DeleteResponse(
      success: json['success'] as bool?,
      error: json['error'] as String?,
    );
  }
}

/// Modelo para la respuesta de obtención de medios
class GetWorkMediaResponse {
  final List<String>? mediaUrls; // Lista de URLs de medios

  GetWorkMediaResponse({this.mediaUrls});

  /// Crea una instancia a partir de un JSON
  factory GetWorkMediaResponse.fromJson(Map<String, dynamic> json) {
    return GetWorkMediaResponse(
      mediaUrls:
          json['media_urls'] != null
              ? List<String>.from(json['media_urls'])
              : null,
    );
  }
}

/// Singleton para manejar la instancia del servicio API
class RetrofitInstanceForWorks {
  static final RetrofitInstanceForWorks _instance =
      RetrofitInstanceForWorks._internal();
  factory RetrofitInstanceForWorks() => _instance;

  final ApiServiceForWorks apiServiceForWorks;

  RetrofitInstanceForWorks._internal()
    : apiServiceForWorks = ApiServiceForWorks();
}

/// Clase para manejar la lógica de subida y eliminación de medios
class UploadWorkMediaToServer extends ChangeNotifier {
  /// Convierte un [Uri] local en un [File] temporal
  Future<File?> uriToFile(BuildContext context, Uri uri) async {
    final Directory tempDir =
        await getTemporaryDirectory(); // Obtiene el directorio temporal
    final File file = File(
      '${tempDir.path}/${uri.path.split('/').last}',
    ); // Crea un archivo temporal
    final bytes = await context.readAsBytes(uri); // Lee los bytes del URI
    await file.writeAsBytes(bytes); // Escribe los bytes en el archivo
    return file;
  }

  /// Elimina un archivo del bucket S3
  Future<bool> deleteWorkMedia(String url) async {
    try {
      final resp = await RetrofitInstanceForWorks().apiServiceForWorks
          .deleteWorkMedia(url);
      return resp.success == true; // Devuelve true si la operación fue exitosa
    } catch (e) {
      return false; // Devuelve false si ocurre una excepción
    }
  }

  /// Llama al servicio para subir una imagen
  Future<void> uploadWorkImage(String userId, File imageFile) async {
    try {} catch (e) {
      // Manejo de excepciones
    }
  }

  /// Llama al servicio para subir un video
  Future<void> uploadWorkVideo(String userId, File videoFile) async {
    try {} catch (e) {
      // Manejo de excepciones
    }
  }

  /// Recupera todas las URLs de medios del usuario
  Future<List<String>?> getWorkMedia(String userId) async {
    try {
      final resp = await RetrofitInstanceForWorks().apiServiceForWorks
          .getWorkMedia(userId);
      return resp.mediaUrls; // Devuelve la lista de URLs de medios
    } catch (e) {
      return null; // Devuelve null si ocurre una excepción
    }
  }
}

/// Extensión para leer bytes desde un asset/local URI
extension on BuildContext {
  Future<Uint8List> readAsBytes(Uri uri) async {
    final ByteData data = await DefaultAssetBundle.of(
      this,
    ).load(uri.path); // Carga los datos del URI
    return data.buffer.asUint8List(); // Devuelve los datos como Uint8List
  }
}