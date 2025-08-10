/// -----------------------------------------------------------------------------
/// Fecha de creación: 26 de abril de 2025
/// Autor: KingdomOfJames
///
/// Descripción:
/// Este conjunto de clases permite la subida de archivos multimedia (imágenes o videos)
/// en los mensajes de una app de música, conectándose a un backend alojado en Render.
/// Usa la biblioteca Dio para realizar solicitudes HTTP y determina automáticamente
/// el tipo de archivo para enviarlo al endpoint correspondiente.
///
/// Características:
/// - Detección automática del tipo de archivo (imagen o video).
/// - Envío de archivos usando `multipart/form-data`.
/// - Gestión sencilla de respuestas mediante una clase modelo (`UploadResponse`).
/// - Singleton para instanciar el cliente de Retrofit y mantener una única instancia.
///
/// Recomendaciones:
/// - Validar el archivo antes de enviarlo para asegurarse de que esté en buen estado.
/// - Agregar un sistema de logs seguro o manejo de errores más robusto en producción.
/// - Considerar implementar reintentos automáticos en caso de error de red.
/// -----------------------------------------------------------------------------
///

import 'dart:io';
import 'package:dio/dio.dart';

/// Servicio encargado de subir archivos multimedia relacionados a los mensajes.
class ApiServiceMessages {
  // Instancia de Dio con la base URL del backend.
  final Dio _dio = Dio(
    BaseOptions(baseUrl: 'https://livemusicbucket.onrender.com/'),
  );

  /// Sube un archivo multimedia (imagen o video) al backend.
  ///
  /// [//file] es el archivo que se desea subir.
  /// [//userId] es el identificador del usuario que sube el archivo.
  ///
  /// Devuelve una instancia de [//UploadResponse] con la URL del archivo subido
  /// o un mensaje de error si ocurre algún fallo.
  Future<UploadResponse> uploadMessageMedia(File file, String userId) async {
    try {
      // Se obtiene la extensión del archivo en minúsculas.
      final extension = file.path.toLowerCase().split('.').last;

      // Se determina si es un video según la extensión.
      final isVideo = ['mp4', 'mov', 'avi'].contains(extension);

      // Se define el endpoint dependiendo del tipo de archivo.
      final endpoint =
          isVideo ? '/upload_message_video' : '/upload_message_image';

      // Se arma el formulario con el archivo y el userId.
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'user_id': userId,
      });

      // Se envía la solicitud POST al backend.
      final response = await _dio.post(endpoint, data: formData);

      // Se interpreta la respuesta como un objeto UploadResponse.
      return UploadResponse.fromJson(response.data);
    } catch (_) {
      // Manejo simple de errores, se puede mejorar en producción.
      return UploadResponse(error: 'No se pudo subir el archivo');
    }
  }
}

/// Modelo de respuesta al subir un archivo.
///
/// Contiene la URL del archivo subido o un mensaje de error.
class UploadResponse {
  final String? url;
  final String? error;

  UploadResponse({this.url, this.error});

  // Crea una instancia a partir de un JSON recibido del backend.
  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(url: json['url'], error: json['error']);
  }
}

/// Singleton que expone una única instancia de ApiServiceMessages
/// para facilitar su acceso en toda la aplicación.
class RetrofitClientMessages {
  // Instancia privada única del singleton.
  static final RetrofitClientMessages _instance =
      RetrofitClientMessages._internal();

  // Método de fábrica para retornar siempre la misma instancia.
  factory RetrofitClientMessages() => _instance;

  // Instancia del servicio.
  final ApiServiceMessages apiServiceMessages;

  // Constructor privado que inicializa el servicio.
  RetrofitClientMessages._internal()
    : apiServiceMessages = ApiServiceMessages();
}
