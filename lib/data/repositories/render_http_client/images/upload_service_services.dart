import 'dart:io';
import 'package:dio/dio.dart';

/// Modelo de respuesta al subir un archivo.
/// Contiene la URL o un mensaje de error detallado.
class UploadResponse {
  final String? url;
  final String? error;
  final String?
  details; // Para detalles adicionales del error (ej. Rekognition)

  UploadResponse({this.url, this.error, this.details});

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      url: json['url'],
      error: json['error'],
      details: json['details'],
    );
  }
}

/// Servicio encargado de subir imágenes para los servicios de los usuarios.
class ApiServiceServices {
  final Dio _dio = Dio(
    // Asegúrate que esta sea la URL base de tu servidor Flask
    BaseOptions(baseUrl: 'https://livemusicbucket.onrender.com/'),
  );

  /// Sube la imagen de un servicio al backend.
  ///
  /// Devuelve una instancia de [UploadResponse] con la URL o un error.
  Future<UploadResponse> uploadServiceImage(File file, String userId) async {
    try {
      final String fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'user_id': userId,
      });

      final response = await _dio.post(
        '/upload_service_image', // El nuevo endpoint del servidor
        data: formData,
        options: Options(
          // Permite recibir el cuerpo de la respuesta incluso en códigos de error
          receiveDataWhenStatusError: true,
        ),
      );

      return UploadResponse.fromJson(response.data);
    } on DioError catch (e) {
      // Maneja errores de Dio, incluyendo respuestas 4xx y 5xx
      if (e.response?.data is Map<String, dynamic>) {
        return UploadResponse.fromJson(e.response!.data);
      }
      return UploadResponse(error: 'Error de conexión. Inténtalo de nuevo.');
    } catch (e) {
      return UploadResponse(
        error: 'Ocurrió un error inesperado al subir la imagen.',
      );
    }
  }
}

/// Singleton para acceder fácilmente a la instancia de ApiServiceServices.
class RetrofitClientServices {
  static final RetrofitClientServices _instance =
      RetrofitClientServices._internal();
  factory RetrofitClientServices() => _instance;
  final ApiServiceServices apiServiceServices;
  RetrofitClientServices._internal()
    : apiServiceServices = ApiServiceServices();
}
