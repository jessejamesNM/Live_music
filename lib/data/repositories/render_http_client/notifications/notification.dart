/*
  ============================================================================
  Archivo: send_notification.dart
  Fecha de creación: 26 de abril de 2025
  Autor: KingdomOfJames

  Descripción:
    Esta función envía una notificación push a un dispositivo móvil usando
    un backend propio alojado en Render. El envío se realiza mediante una 
    solicitud HTTP POST que contiene el token del usuario, el título y el 
    cuerpo del mensaje.

  Características:
    - Usa la librería 'http' para hacer solicitudes POST.
    - Codifica el contenido en JSON antes de enviarlo.
    - Maneja errores de red de forma básica.
    - Solo se conecta a un endpoint fijo en la nube.

  Recomendaciones:
    - Mejorar el manejo de errores agregando más validaciones en producción.
    - Usar logs seguros en lugar de prints en entornos reales.
    - Si el endpoint cambia o requiere autenticación adicional, actualizar 
      la función adecuadamente.
  ============================================================================
*/

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Función que envía una notificación push a través de un backend externo.
///
/// [body]: Contenido del mensaje de la notificación.
/// [title]: Título de la notificación.
/// [userToken]: Token de dispositivo al que se enviará la notificación.
Future<void> sendNotification(
  String body,
  String title,
  String userToken,
) async {
  // Define la URL del servidor que maneja el envío de notificaciones
  final url = Uri.parse(
    'https://live-music-backend-du9y.onrender.com/send-notification',
  );

  // Crea el cuerpo de la solicitud en formato JSON
  final json = jsonEncode({
    'user_token': userToken,
    'title': title,
    'body': body,
  });

  try {
    // Envía la solicitud HTTP POST al servidor
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: json,
    );

    // Procesa la respuesta del servidor
    if (response.statusCode == 200) {
      // La notificación fue enviada exitosamente
      // (Se podría agregar aquí un log seguro o una notificación local)
      print("codigo 200");
    } else {
      // Hubo un error al enviar la notificación
      // (En producción se recomienda manejar este error de forma más robusta)
    }
  } catch (e) {
    // Captura cualquier excepción de red o error inesperado
    // (En producción se debería reportar este error de manera segura)
  }
}
