/// ==============================================================================
/// Fecha de creación: 26 de abril de 2025
/// Autor: KingdomOfJames
///
/// Descripción de la pantalla:
/// Este archivo contiene funciones utilitarias para validar correos electrónicos
/// y contraseñas en procesos de registro o login de usuarios.
///
/// Características:
/// - Validación de formato de email.
/// - Validación de requisitos de seguridad en contraseñas (mínimo de longitud, uso de mayúsculas, minúsculas, números y caracteres especiales).
///
/// Recomendaciones:
/// - La expresión regular de email podría mejorarse para aceptar dominios más amplios (actualmente limitada a dominios simples como "gmail.com").
/// - Ofrecer retroalimentación al usuario basada en qué requisitos de contraseña no se cumplen.
/// - Considerar internacionalización si se muestran los requisitos como mensajes en pantalla.
///
/// ==============================================================================

/// Función para validar el formato de un correo electrónico.
/// Retorna `true` si el correo cumple con el patrón establecido, `false` en caso contrario.
bool isEmailValid(String email) {
  // Patrón básico para validar un email (usuario@dominio.extensión)
  final emailPattern = RegExp(r'[a-zA-Z0-9._-]+@[a-z]+\.+[a-z]+');
  return emailPattern.hasMatch(email);
}

/// Función para validar una contraseña.
/// Retorna un mapa donde cada requisito está asociado a un valor booleano
/// indicando si se cumple o no.
///
/// Requisitos:
/// - Mínimo 8 caracteres
/// - Al menos una letra mayúscula
/// - Al menos una letra minúscula
/// - Al menos un número
/// - Al menos un carácter especial
Map<String, bool> isPasswordValid(String password) {
  final requirements = {
    'Al menos 8 caracteres': password.length >= 8,
    'Al menos 1 letra mayúscula': password.contains(RegExp(r'[A-Z]')),
    'Al menos 1 letra minúscula': password.contains(RegExp(r'[a-z]')),
    'Al menos 1 número': password.contains(RegExp(r'\d')),
    'Al menos 1 caracter especial': password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    ),
  };
  return requirements;
}
