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

class RegisterWithGoogleProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isSigningIn = false;

  Future<void> signInWithGoogle(
    BuildContext context,
    UserProvider userProvider,
    GoRouter goRouter,
    String userType,
  ) async {
    if (_isSigningIn) return;
    _isSigningIn = true;

    try {
      // 1. Iniciar el flujo de Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Usuario canceló el flujo
        return;
      }

      // 2. Obtener la autenticación de Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Crear credenciales para Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase con las credenciales
      final UserCredential authResult = await _auth.signInWithCredential(
        credential,
      );
      final User? user = authResult.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'El usuario de Firebase es nulo después del login.',
        );
      }

      // 5. Verificar/crear documento en Firestore
      final userDocRef = _firestore
          .collection(AppStrings.usersCollection)
          .doc(user.uid);
      final doc = await userDocRef.get();

      if (doc.exists) {
        final isRegistered = doc.data()?[AppStrings.isRegisteredField] ?? false;
        final existingUserType = doc.data()?[AppStrings.userTypeField];

        if (isRegistered) {
          if (existingUserType != userType) {
            _showUserTypeMismatchDialog(context, goRouter);
          } else {
            _showAlreadyRegisteredDialog(context, goRouter);
          }
        } else {
          await userDocRef.update({
            AppStrings.isRegisteredField: true,
            AppStrings.userTypeField: userType,
            AppStrings.registerNameField: user.displayName ?? AppStrings.noName,
            'accountCreationDate': FieldValue.serverTimestamp(),
          });
          _goToCorrectScreen(userType, goRouter);
        }
      } else {
        await userDocRef.set({
          AppStrings.isRegisteredField: true,
          AppStrings.userTypeField: userType,
          AppStrings.emailField: user.email,
          AppStrings.registerNameField: user.displayName ?? AppStrings.noName,
          AppStrings.isVerifiedField: true,
          'accountCreationDate': FieldValue.serverTimestamp(),
        });
        _goToCorrectScreen(userType, goRouter);
      }

      // 6. Guardar fecha de creación
      userProvider.saveAccountCreationDate();
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: $e');
      _showError(context, 'Error de autenticación: ${e.message}');
    } on FirebaseException catch (e) {
      debugPrint('Firestore Error: $e');
      _showError(context, 'Error de base de datos: ${e.message}');
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      _showError(context, AppStrings.googleSignInFailed);
    } finally {
      _isSigningIn = false;
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showAlreadyRegisteredDialog(BuildContext context, GoRouter goRouter) {
    final colorScheme = ColorPalette.getPalette(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppStrings.no,
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  goRouter.go(AppStrings.loginOptionsScreenRoute);
                  Navigator.of(context).pop();
                },
                child: Text(
                  AppStrings.yes,
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
            ],
          ),
    );
  }
void _showUserTypeMismatchDialog(BuildContext context, GoRouter goRouter) {
  final colorScheme = ColorPalette.getPalette(context);
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      title: Text(
        "Cuenta ya registrada",
        style: TextStyle(
          color: colorScheme[AppStrings.secondaryColor],
        ),
      ),
      content: Text(
        "Ya está registrada esta cuenta, ¿quieres iniciar sesión?",
        style: TextStyle(
          color: colorScheme[AppStrings.secondaryColor],
        ),
      ),
      actions: [
        // Botón No a la izquierda
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            "No",
            style: TextStyle(
              color: colorScheme[AppStrings.secondaryColor],
            ),
          ),
        ),
        // Botón Sí (Aceptar) a la derecha
        TextButton(
          onPressed: () {
            goRouter.go(AppStrings.loginOptionsScreenRoute);
            Navigator.of(context).pop();
          },
          child: Text(
            AppStrings.accept,
            style: TextStyle(
              color: colorScheme[AppStrings.secondaryColor],
            ),
          ),
        ),
      ],
    ),
  );
}

  void _goToCorrectScreen(String userType, GoRouter goRouter) {
    goRouter.go(AppStrings.ageTermsScreenRoute);
  }

  Future<void> registerWithGoogle(
    String userType,
    Function(RegisterResult) onResult,
  ) async {
    if (_isSigningIn) return;
    _isSigningIn = true;

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
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
      debugPrint('registerWithGoogle Error: $e');
      onResult(RegisterResult.failure);
    } finally {
      _isSigningIn = false;
    }
  }

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
          existingUserType != userType
              ? onResult(RegisterResult.userAlreadyExists)
              : onResult(RegisterResult.success);
        } else {
          await _saveUserToFirestore(uid, userType);
          onResult(RegisterResult.success);
        }
      } else {
        await _saveUserToFirestore(uid, userType);
        onResult(RegisterResult.success);
      }
    } catch (e) {
      debugPrint('_checkUserExists Error: $e');
      onResult(RegisterResult.failure);
    }
  }

  Future<void> _saveUserToFirestore(String uid, String userType) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection(AppStrings.usersCollection).doc(uid).set({
        AppStrings.emailField: user.email,
        AppStrings.userTypeField: userType,
        AppStrings.registerNameField: user.displayName ?? AppStrings.noName,
        AppStrings.isRegisteredField: true,
        AppStrings.isVerifiedField: true,
        'accountCreationDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('_saveUserToFirestore Error: $e');
      rethrow;
    }
  }
}

enum RegisterResult { success, failure, userAlreadyExists }
