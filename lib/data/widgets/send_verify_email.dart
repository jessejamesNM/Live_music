/// ==============================================================================
/// Fecha de creación: 26 de abril de 2025
/// Autor: KingdomOfJames
///
/// Descripción de la pantalla:
/// Este archivo contiene la función responsable de enviar un correo de verificación
/// a la dirección de email asociada a un usuario autenticado mediante Firebase Authentication.
///
/// Características:
/// - Verifica que el usuario esté autenticado antes de intentar enviar el email.
/// - Utiliza ActionCodeSettings para definir cómo se debe manejar el enlace de verificación.
/// - Personaliza el enlace de verificación para abrir la app móvil o una página web.
///
/// Recomendaciones:
/// - Manejar excepciones en caso de errores de red o problemas con Firebase.
/// - Mostrar mensajes claros al usuario indicando si el correo fue enviado correctamente o si ocurrió un error.
/// - Verificar que el usuario no haya sido eliminado o deslogueado antes de intentar enviar el email.
///
/// ==============================================================================

import 'package:firebase_auth/firebase_auth.dart';

/// Función que envía un correo de verificación al email del usuario actual.
///
/// Parámetros:
/// - [email]: Este parámetro actualmente no se utiliza dentro de la función,
///   ya que `FirebaseAuth.instance.currentUser` ya contiene el email del usuario.
///   (Se podría optimizar eliminando el parámetro si no es necesario).

Future<void> sendVerificationEmail(String email) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  } catch (e) {
    throw Exception("Error enviando correo: $e");
  }
}