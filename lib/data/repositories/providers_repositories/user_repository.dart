/// -----------------------------------------------------------------------------
/// Fecha de creación: 26 de abril de 2025
/// Autor: KingdomOfJames
///
/// Descripción:
/// Clase responsable de manejar todas las operaciones relacionadas con el
/// registro, autenticación, verificación de email, y cierre de sesión de usuarios.
/// Utiliza Firebase Authentication, Cloud Firestore y SharedPreferences para
/// almacenar y validar la información del usuario.
///
/// Características:
/// - Registro de usuario con validación y control de duplicados.
/// - Almacenamiento de datos adicionales en Firestore.
/// - Envío automático de correo de verificación.
/// - Persistencia local del correo registrado.
/// - Reenvío de email de verificación.
/// - Función para obtener el usuario actual y cerrar sesión.
///
/// Recomendaciones:
/// - Se recomienda añadir validaciones del lado del cliente antes de llamar
///   a esta clase para mejorar la experiencia del usuario.
/// - Considerar agregar logging solo en entorno de desarrollo para evitar
///   exponer errores sensibles en producción.
/// -----------------------------------------------------------------------------

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRepository {
  final SharedPreferences sharedPreferences;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Constructor con inyección de dependencias (útil para testing).
  /// Si no se proporciona una instancia de `auth` o `firestore`, se usa la predeterminada.
  UserRepository(
    this.sharedPreferences, {
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Función principal para registrar un usuario.
  /// Crea la cuenta en Firebase Authentication y guarda datos adicionales en Firestore.
  /// También envía un correo de verificación y guarda el email en SharedPreferences.
  Future<String?> registerUser(
    String email,
    String password,
    String role,
    String userName,
    String lastName,
  ) async {
    try {
      // Crea el usuario en Firebase Authentication
      final authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = authResult.user;
      if (user == null) return 'Error al crear el usuario';

      // Verifica si el documento del usuario ya existe en Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        // Si ya existía, elimina el usuario creado y retorna error
        await user.delete();
        return 'El correo ya está registrado';
      }

      // Crea el documento del usuario en Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'userType': role,
        'email': email,
        'uid': user.uid,
        'registerName': userName,
        'lastName': lastName,
        'isRegistered': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Envía el correo de verificación
      await _sendVerificationEmail(user);

      // Guarda el correo en almacenamiento local
      await sharedPreferences.setString('userEmail', email);

      return null; // Registro exitoso
    } on FirebaseAuthException catch (e) {
      // Manejo de errores específicos de autenticación
      return _getAuthErrorMessage(e);
    } on FirebaseException catch (e) {
      // Manejo de errores generales de Firebase
      return 'Error de base de datos: ${e.message}';
    } catch (e) {
      // Cualquier otro error no controlado
      return 'Error inesperado: $e';
    }
  }

  /// Función auxiliar para mapear códigos de error de FirebaseAuth a mensajes en español.
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
      case 'email-already-registered':
        return 'El correo ya está registrado';
      case 'invalid-email':
        return 'Formato de correo inválido';
      case 'weak-password':
        return 'Contraseña débil (mínimo 6 caracteres)';
      case 'network-request-failed':
        return 'Error de red. Verifica tu conexión';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }

  /// Función privada que envía el correo de verificación.
  Future<void> _sendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      // Si hay error al enviar el correo, se lanza una excepción específica
      throw FirebaseAuthException(
        code: 'verification-error',
        message: 'Error enviando email: ${e.message}',
      );
    }
  }

  /// Función pública para reenviar el correo de verificación.
  Future<void> resendVerificationEmail(User user) async {
    await _sendVerificationEmail(user);
  }

  /// Retorna el usuario actual si está autenticado, o null si no hay sesión activa.
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  /// Cierra la sesión del usuario y limpia datos locales.
  Future<void> signOut() async {
    await _auth.signOut();
    await sharedPreferences.remove('userEmail');
  }
}
