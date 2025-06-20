/*
  Fecha de creación: 26/04/2025
  Autor: KingdomOfJames

  Descripción:
  Provider encargado de gestionar el registro e inicio de sesión de usuarios a través de Google en una aplicación 
  que utiliza Firebase Authentication y Firestore. Permite tanto la autenticación inicial como la validación y 
  actualización del tipo de usuario (artista o contratante) y el manejo de flujos alternativos en caso de que el 
  usuario ya exista o tenga un tipo de cuenta distinto al esperado.

  Recomendaciones:
  - Implementar un manejo más robusto de errores para mostrar mensajes más amigables al usuario en caso de fallos.
  - Considerar agregar un loading indicator mientras se procesa el inicio de sesión para mejorar la experiencia de usuario.
  - Agregar logs más detallados para facilitar la depuración en producción.
  - Extraer la lógica de navegación y diálogos fuera del provider para seguir mejor el principio de responsabilidad única.

  Características:
  - Inicio de sesión con Google y autenticación con Firebase.
  - Verificación de existencia de usuario en Firestore.
  - Diferenciación de flujo entre usuarios nuevos, usuarios no registrados completamente, y usuarios ya registrados.
  - Manejo de conflictos cuando el tipo de cuenta del usuario no coincide.
  - Dos métodos de registro: uno orientado a navegación directa y otro a devolución de resultados vía callback.
*/

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../user/user_provider.dart';
import 'package:go_router/go_router.dart';

// Provider que maneja el registro de usuarios usando Google Sign-In
class RegisterWithGoogleProvider with ChangeNotifier {
  // Instancias de Firebase Auth y Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RegisterWithGoogleProvider();

  // Método principal para iniciar sesión con Google y registrar usuario
  Future<void> signInWithGoogle(
    BuildContext context,
    UserProvider userProvider,
    GoRouter _goRouter,
    String userType, // 'artist' o 'contractor'
  ) async {
    try {
      // 1. Inicia el flujo de autenticación de Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // El usuario canceló el proceso

      // 2. Obtiene las credenciales de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // 3. Usa las credenciales para autenticar en Firebase
      final UserCredential authResult = await _auth.signInWithCredential(
        credential,
      );
      final User? user = authResult.user;

      if (user != null) {
        // 4. Referencia al documento del usuario en Firestore
        final userDocRef = _firestore
            .collection(AppStrings.usersCollection)
            .doc(user.uid);
        final doc = await userDocRef.get();

        if (doc.exists) {
          // Caso: Usuario ya existe
          final isRegistered =
              doc.data()?[AppStrings.isRegisteredField] ?? false;
          final existingUserType = doc.data()?[AppStrings.userTypeField];

          if (isRegistered) {
            // Usuario ya completó su registro antes
            if (existingUserType != userType) {
              // Tipo de usuario no coincide
              _showUserTypeMismatchDialog(context, _goRouter);
            } else {
              // Usuario registrado correctamente
              _showAlreadyRegisteredDialog(context, _goRouter);
            }
          } else {
            // Usuario no completó su registro anteriormente
            await userDocRef.update({
              AppStrings.isRegisteredField: true,
              AppStrings.userTypeField: userType,
              AppStrings.registerNameField:
                  user.displayName ?? AppStrings.noName,
            });
            userProvider.saveAccountCreationDate();
            _goToCorrectScreen(userType, _goRouter);
          }
        } else {
          // Caso: Nuevo usuario
          await userDocRef.set({
            AppStrings.isRegisteredField: true,
            AppStrings.userTypeField: userType,
            AppStrings.emailField: user.email,
            AppStrings.registerNameField: user.displayName ?? AppStrings.noName,
            AppStrings.isVerifiedField:
                true, // Email verificado automáticamente
          });
          userProvider.saveAccountCreationDate();
          _goToCorrectScreen(userType, _goRouter);
        }
      }
    } catch (e) {
      // En caso de error, muestra un SnackBar al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.googleSignInFailed)),
      );
    }
  }
void _showAlreadyRegisteredDialog(BuildContext context, GoRouter _goRouter) {
 final colorScheme = ColorPalette.getPalette(context);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      title: Text(
        AppStrings.accountRegisteredTitle,
        style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
      ),
      content: Text(
        AppStrings.accountRegisteredContent,
        style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
      ),
      actions: [
        // Botón "No" a la izquierda
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppStrings.no,
            style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
          ),
        ),
        // Botón "Sí" a la derecha
        TextButton(
          onPressed: () {
            _goRouter.go(AppStrings.loginOptionsScreenRoute);
            Navigator.of(context).pop();
          },
          child: Text(
            AppStrings.yes,
            style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
          ),
        ),
      ],
    ),
  );
}
  // Muestra un diálogo si el tipo de usuario no coincide con el registro
  void _showUserTypeMismatchDialog(BuildContext context, GoRouter _goRouter) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(AppStrings.unblockUserTitle),
            content: const Text(AppStrings.unblockUserMessage),
            actions: [
              TextButton(
                onPressed: () {
                  _goRouter.go(AppStrings.loginOptionsScreenRoute);
                  Navigator.of(context).pop();
                },
                child: const Text(AppStrings.accept),
              ),
            ],
          ),
    );
  }

  // Redirige a la pantalla correcta según el tipo de usuario
  void _goToCorrectScreen(String userType, GoRouter _goRouter) {
    _goRouter.go(
      userType == AppStrings.artist
          ? AppStrings.ageTermsScreenRoute
          : AppStrings.ageTermsScreenRoute,
    );
  }

  // Método alternativo para registro usando Google, más genérico
  Future<void> registerWithGoogle(
    String userType,
    Function(RegisterResult) onResult, // Callback para devolver el resultado
  ) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        onResult(RegisterResult.failure);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        await _checkUserExists(userCredential.user!.uid, userType, onResult);
      } else {
        onResult(RegisterResult.failure);
      }
    } catch (e) {
      onResult(RegisterResult.failure);
    }
  }

  // Verifica si el usuario ya existe en Firestore
  Future<void> _checkUserExists(
    String uid,
    String userType,
    Function(RegisterResult) onResult,
  ) async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore
              .collection(AppStrings.usersCollection)
              .doc(uid)
              .get();

      if (userDoc.exists) {
        final existingUserType = userDoc.get(AppStrings.userTypeField);
        final isRegistered = userDoc.get(AppStrings.isRegisteredField);

        if (isRegistered == true) {
          // Usuario ya registrado
          existingUserType != userType
              ? onResult(RegisterResult.userAlreadyExists)
              : onResult(RegisterResult.success);
        } else {
          // Usuario incompleto, se guarda correctamente
          await _saveUserToFirestore(uid, userType);
          onResult(RegisterResult.success);
        }
      } else {
        // Nuevo usuario, se guarda
        await _saveUserToFirestore(uid, userType);
        onResult(RegisterResult.success);
      }
    } catch (e) {
      onResult(RegisterResult.failure);
    }
  }

  // Guarda la información del usuario en Firestore
  Future<void> _saveUserToFirestore(String uid, String userType) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection(AppStrings.usersCollection).doc(uid).set({
        AppStrings.emailField: user.email,
      });
    } catch (e) {
      // Manejo de errores (sin exponer información)
    }
  }
}

// Enum para representar los posibles resultados del registro
enum RegisterResult { success, failure, userAlreadyExists }
