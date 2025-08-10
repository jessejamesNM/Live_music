// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: Este widget es responsable de mostrar el nombre de usuario en la interfaz, obteniendo los datos
//              de Firebase Firestore. El nombre se obtiene del documento del usuario autenticado, y si existe,
//              se muestra en la pantalla con el tamaño de fuente proporcionado. Ideal para personalizar el perfil
//              del usuario en una aplicación que utilice Firebase para la autenticación y almacenamiento de datos.
// Recomendaciones: Asegúrate de tener configurada la autenticación de Firebase y Firestore correctamente en tu proyecto,
//                  y proporciona un nombre de usuario para los usuarios autenticados. Este widget depende de la colección
//                  de usuarios en Firestore, cuya clave debe coincidir con la de `AppStrings.usersCollection`.
// Características:
//   - Obtiene el nombre del usuario desde Firebase Firestore.
//   - Muestra el nombre de usuario en la interfaz con un tamaño de fuente personalizable.
//   - Muestra el nombre en el color secundario configurado en el tema de la aplicación.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class UserName extends StatefulWidget {
  final double fontSize; // Tamaño de fuente para mostrar el nombre del usuario.

  UserName({required this.fontSize});

  @override
  _UserNameState createState() => _UserNameState();
}

class _UserNameState extends State<UserName> {
  String name = ""; // Variable para almacenar el nombre del usuario.
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Instancia de FirebaseAuth para la autenticación.
  final FirebaseFirestore _firestore =
      FirebaseFirestore
          .instance; // Instancia de FirebaseFirestore para acceder a Firestore.

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // Llamar a la función para obtener el nombre del usuario al inicializar el widget.
  }

  // Función para obtener el nombre del usuario desde Firestore.
  void _fetchUserName() async {
    User? user = _auth.currentUser; // Obtener el usuario autenticado.
    if (user != null) {
      // Si el usuario está autenticado, buscar el documento correspondiente en Firestore.
      DocumentSnapshot document =
          await _firestore
              .collection(
                AppStrings.usersCollection,
              ) // Colección de usuarios en Firestore.
              .doc(user.uid) // Documento del usuario autenticado.
              .get();
      if (document.exists) {
        // Si el documento existe, obtener los datos del nombre del usuario.
        final data = document.data() as Map<String, dynamic>?;
        setState(() {
          // Asignar el nombre a la variable `name` desde el campo correspondiente del documento.
          name = data?[AppStrings.nameField] ?? data?['registerName'] ?? "";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el esquema de colores del contexto actual.
    final colorScheme = ColorPalette.getPalette(context);
    return Text(
      name, // Mostrar el nombre del usuario.
      style: TextStyle(
        color:
            colorScheme[AppStrings.secondaryColor] ??
            Colors
                .white, // Usar el color secundario del tema o blanco por defecto.
        fontSize:
            widget
                .fontSize, // Usar el tamaño de fuente proporcionado por el widget.
      ),
    );
  }
}
