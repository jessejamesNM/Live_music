/*
 * Fecha de creación: 2025-04-26
 * Autor: KingdomOfJames
 * 
 * Descripción:
 * La clase `LocationHelper` proporciona un servicio para obtener la ubicación actual del usuario. Utiliza la librería `Geolocator` 
 * para verificar si el servicio de ubicación está habilitado, solicita permisos de ubicación si es necesario y luego obtiene la 
 * ubicación del usuario con la precisión más alta posible. Si en algún momento los permisos no se otorgan o el servicio no está 
 * disponible, el método devuelve `null`.
 * 
 * Recomendaciones:
 * - Asegúrate de manejar los permisos de ubicación correctamente en plataformas Android y iOS. En Android, debes declarar los permisos 
 *   necesarios en el archivo `AndroidManifest.xml`, mientras que en iOS es necesario configurarlos en el archivo `Info.plist`.
 * - Considera implementar un manejo de errores más robusto para los posibles fallos en la obtención de la ubicación, 
 *   especialmente si el servicio está inactivo o el dispositivo no tiene capacidad para obtener la ubicación.
 * - La precisión de la ubicación se establece como `high`, pero podrías ajustarla si la precisión no es crucial para tu caso de uso.
 *
 * Características:
 * - Verifica si los servicios de ubicación están habilitados.
 * - Solicita permisos de ubicación si no están otorgados.
 * - Obtiene la ubicación actual del dispositivo con alta precisión.
 * - Maneja errores y permisos denegados devolviendo `null` en caso de fallos.
 * - El código es útil para funcionalidades que dependan de la ubicación del usuario, como mostrar lugares cercanos o realizar 
 *   geolocalización en una aplicación.
 */

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationHelper {
  final BuildContext context;

  // Constructor que recibe el contexto de la aplicación
  LocationHelper(this.context);

  // Método que obtiene la ubicación actual del usuario
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si el servicio de ubicación no está habilitado, devolver null
      return null;
    }

    // Verificar el estado del permiso de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Si el permiso está denegado, solicitar permiso
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Si el permiso sigue denegado, devolver null
        return null;
      }
    }

    // Verificar si los permisos están denegados permanentemente
    if (permission == LocationPermission.deniedForever) {
      // Si los permisos están denegados permanentemente, devolver null
      return null;
    }

    // Intentar obtener la ubicación actual con alta precisión
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      // Si ocurre un error, devolver null
      return null;
    }
  }
}
