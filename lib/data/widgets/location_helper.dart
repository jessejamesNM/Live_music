/*
  Fecha de creación: 26/04/2025
  Autor: KingdomOfJames

  Descripción:
  Esta clase `LocationHelper` proporciona una utilidad para obtener la ubicación actual del usuario 
  utilizando la librería Geolocator. Se encarga de verificar los permisos, solicitar acceso si es necesario
  y devolver las coordenadas de latitud y longitud.

  Características:
  - Verificación automática de servicios de localización habilitados.
  - Manejo de permisos de ubicación (solicita al usuario si están denegados).
  - Retorno de ubicación en un Map<String, double> sencillo de usar.
  - Precisión alta en la obtención de la ubicación.

  Recomendaciones:
  - Asegurarse de pedir permisos de ubicación en tiempo de ejecución, especialmente en Android 10+ y iOS.
  - Implementar un manejo de errores más detallado en producción (no solo devolver null).
  - Considerar escenarios donde la ubicación tarde mucho o no esté disponible (timeout o retries).
*/

import 'package:geolocator/geolocator.dart';

// Clase auxiliar para obtener la ubicación actual
class LocationHelper {
  // Método estático para obtener la ubicación actual
  static Future<Map<String, double>?> getCurrentLocation() async {
    // Verificar si el servicio de localización está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si el servicio no está habilitado, no se puede obtener ubicación
      return null;
    }

    // Verificar el estado de los permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Si están denegados, solicitar permisos
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Si siguen estando denegados después de solicitar, devolver null
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Si los permisos están denegados permanentemente, no se puede pedir más permisos
      return null;
    }

    // Intentar obtener la posición actual
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy
                .high, // Alta precisión recomendada para geolocalización exacta
      );

      // Devolver la latitud y longitud en un mapa
      return {'latitude': position.latitude, 'longitude': position.longitude};
    } catch (_) {
      // En caso de error (por ejemplo timeout o excepción interna), devolver null de manera silenciosa
      return null;
    }
  }
}
