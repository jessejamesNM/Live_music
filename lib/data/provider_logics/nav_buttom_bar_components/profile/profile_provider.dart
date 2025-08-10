/*
  Fecha de creación: 2025-04-26
  Autor: KingdomOfJames

  Descripción:
  Esta clase ProfileProvider maneja la lógica relacionada con la gestión del perfil de usuario en una aplicación móvil, utilizando Firebase para almacenar y recuperar datos relacionados con el usuario. 

  Funcionalidades principales:
  - Guardar y cargar los días ocupados de un usuario en Firestore.
  - Cargar imágenes desde archivos locales o URIs, y proporcionar imágenes predeterminadas en caso de error.
  - Enviar correos de restablecimiento de contraseña y gestionar cambios de contraseña mediante Firebase Authentication.
  - Funciones para cerrar sesión, gestionar solicitudes de eliminación de cuenta y enviar descripciones de problemas o sugerencias a Firestore.
  - Métodos auxiliares para gestionar la navegación dentro de la aplicación.

  Recomendaciones:
  - Asegúrese de gestionar correctamente los permisos de Firebase y las configuraciones de Firestore antes de utilizar estas funciones.
  - Para la carga de imágenes, es importante validar el estado del archivo y manejar adecuadamente los errores.
  - Si se implementan más funcionalidades que interactúan con el usuario o Firestore, considere mejorar la gestión de errores y las validaciones.
*/

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Guarda los días ocupados del usuario en Firestore
  Future<void> saveBusyDays(
    String userId,
    List<DateTime> busyDays,
    VoidCallback onComplete,
  ) async {
    final userRef = _firestore.collection("users").doc(userId);

    // Convertir la lista de DateTime a String para poder almacenarla en Firestore
    final busyDaysString =
        busyDays.map((date) => DateFormat('yyyy-MM-dd').format(date)).toList();

    // Actualiza la colección de Firestore con la lista de días ocupados
    await userRef
        .update({"busyDays": busyDaysString})
        .then((_) {
          onComplete(); // Llama al callback una vez se haya completado la actualización
        })
        .catchError((exception) {
          // Maneja el error en caso de que falle la actualización
        });
  }

  // Carga los días ocupados del usuario desde Firestore
  Future<void> loadBusyDays(
    String userId,
    Function(List<DateTime>) onComplete,
  ) async {
    final userRef = _firestore.collection("users").doc(userId);

    await userRef
        .get()
        .then((document) {
          if (document.exists) {
            // Convierte la lista de Strings a List<DateTime>
            final busyDaysString = List<String>.from(
              document.get("busyDays") ?? [],
            );
            final busyDays =
                busyDaysString
                    .map((date) => DateFormat('yyyy-MM-dd').parse(date))
                    .toList();
            onComplete(
              busyDays,
            ); // Llama al callback con los días ocupados cargados
          } else {
            onComplete(
              [], // Si no existe el documento, retorna una lista vacía
            );
          }
        })
        .catchError((exception) {
          onComplete([]); // Maneja el error devolviendo una lista vacía
        });
  }

  // Función auxiliar para cargar una imagen desde un archivo (File)
  Future<Image?> loadImageFromFile(File imageFile) async {
    try {
      // Verifica si el archivo de imagen existe
      if (await imageFile.exists()) {
        // Si el archivo existe, carga la imagen desde el archivo
        final image = Image.file(imageFile);
        return image;
      } else {
        return null; // Si el archivo no existe, retorna null
      }
    } catch (e) {
      return null; // Si ocurre un error al cargar la imagen, retorna null
    }
  }

  // Carga una imagen desde una URI (por ejemplo, desde almacenamiento o servidor)
  Future<ImageProvider> loadImageBitmapFromUri(
    Uri uri,
    BuildContext context,
  ) async {
    try {
      // Convierte la URI en un archivo (File)
      final file = File.fromUri(uri);

      // Verifica si el archivo existe
      if (await file.exists()) {
        // Si el archivo existe, retorna un ImageProvider (FileImage)
        return FileImage(file);
      } else {
        // Si el archivo no existe, retorna un ImageProvider vacío (placeholder)
        return const AssetImage('assets/placeholder.png');
      }
    } catch (e) {
      // En caso de error, retorna un ImageProvider de un placeholder
      return const AssetImage('assets/placeholder.png');
    }
  }

  // Envia un correo de reseteo de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      // Maneja el error en caso de que falle el envío del correo
    }
  }

  // Cambia la contraseña del usuario actual
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    Function(bool, String) callback,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      callback(false, AppStrings.noUserAuthenticated);
      return;
    }

    try {
      // Reautenticación con las credenciales actuales
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Actualiza la contraseña con la nueva
      await user.updatePassword(newPassword);
      callback(true, AppStrings.passwordChangedSuccess);
    } on FirebaseAuthException catch (e) {
      callback(false, "${AppStrings.passwordChangeError} ${e.message}");
    }
  }

  // Cierra sesión del usuario y navega a otra pantalla
  Future<void> signOutAndNavigate(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final googleSignIn = GoogleSignIn();

    // Cerrar sesión en Firebase Authentication
    await auth.signOut();

    // Cerrar sesión en Google Sign-In
    await googleSignIn.signOut();

    // Navegar a la pantalla de selección y limpiar la pila de navegación
    context.go('/selectionscreen');
  }

  // Solicita la eliminación de una cuenta
  Future<void> saveDeletionRequest({
    required String userId,
    required String reason,
    required String currentDay,
    required String eliminationDay,
    required Function() onSuccess,
    required Function(String) onFailure,
  }) async {
    final db = FirebaseFirestore.instance;

    final motive =
        "El usuario $userId desea eliminar su cuenta: $reason, $currentDay y $eliminationDay.";
    final request = {
      "motive": motive,
      "currentDay": currentDay,
      "eliminationDay": eliminationDay,
      "UserId": userId,
      "isValid": false,
    };

    try {
      await db.collection("eliminateAccountsRequest").add(request);
      onSuccess(); // Llama al callback de éxito
    } catch (e) {
      onFailure(
        AppStrings.saveDeletionRequestFailure,
      ); // Llama al callback de fallo con el mensaje de error
    }
  }

  // Envia una descripción de problema a Firestore
  Future<void> sendProblemDescriptionToFirestore(
    String description,
    String email,
    String nickname,
  ) async {
    final db = FirebaseFirestore.instance;
    final problemData = {
      "description": description,
      "email": email,
      "nickname": nickname,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await db.collection("ProblemDescriptions").add(problemData);
    } catch (e) {
      // Maneja el error en caso de que falle el envío
    }
  }

  // Envia una sugerencia a Firestore
  Future<void> sendSuggestionToFirestore(
    String content,
    String email,
    String nickname,
  ) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    final Map<String, dynamic> suggestionData = {
      "content": content,
      "email": email,
      "nickname": nickname,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await db.collection("Suggestions").add(suggestionData);
    } catch (e) {
      // Maneja el error en caso de que falle el envío
    }
  }

  // Abre una URL externa (por ejemplo, en un navegador)
  Future<void> myLaunchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw "No se pudo abrir $url";
    }
  }
}
