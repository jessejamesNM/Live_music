/*
  ---------------------------------------------------------
  Fecha de creación: 26 de abril de 2025
  Autor: KingdomOfJames

  Descripción:
  Esta clase llamada "FirebaseUtils" proporciona utilidades para gestionar
  tokens de notificaciones push (FCM) y vincularlos a usuarios en Firestore.
  También incluye métodos para obtener el UID actual del usuario autenticado.

  Características:
  - Obtener el token de notificación del dispositivo actual (FCM).
  - Guardar el token de notificación en el documento del usuario en Firestore.
  - Obtener el UID del usuario actualmente autenticado.

  Recomendaciones:
  - Manejar los errores desde la interfaz de usuario para mejor feedback.
  - Llamar a 'getDeviceToken' después de que el usuario haya iniciado sesión.
  - Mantener siempre actualizado el token en Firestore en caso de cambios.
  - No imprimir tokens ni errores sensibles en entornos de producción.

  ---------------------------------------------------------
*/

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUtils {
  /// Función para obtener el token FCM del dispositivo.
  static Future<void> getDeviceToken({
    required Function(String)
    onTokenReceived, // Callback cuando se recibe el token
    required Function(Exception) onError, // Callback en caso de error
  }) async {
    try {
      // Se intenta obtener el token del dispositivo
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        // Si se obtiene el token, se llama al callback exitoso
        onTokenReceived(token);
      } else {
        // Si el token es nulo, se lanza una excepción
        throw Exception("El token fue nulo");
      }
    } catch (e) {
      // En caso de error, se llama al callback de error
      onError(e is Exception ? e : Exception("Error desconocido"));
    }
  }

  /// Función para guardar el token FCM en Firestore bajo el documento del usuario.
  static Future<void> saveTokenToFirestore({
    required String uid, // UID del usuario
    required String token, // Token FCM a guardar
    required Function() onSuccess, // Callback en caso de éxito
    required Function(Exception) onError, // Callback en caso de error
  }) async {
    try {
      // Se actualiza el documento del usuario con el nuevo token FCM
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "fcmToken": token,
      });

      // Llamar callback de éxito
      onSuccess();
    } catch (e) {
      // Llamar callback de error
      onError(e is Exception ? e : Exception("Error desconocido"));
    }
  }

  /// Función auxiliar para obtener el UID del usuario actual autenticado.
  static String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
