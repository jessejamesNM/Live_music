/*
  Fecha de creación: 26 de abril de 2025
  Autor: KingdomOfJames
  
  Descripción de la pantalla:
  Esta pantalla permite al usuario confirmar su identidad proporcionando su correo electrónico y contraseña. 
  Se utiliza como un paso de seguridad para realizar solicitudes de eliminación de cuenta u otras acciones sensibles.
  
  Recomendaciones:
  - Asegúrate de que el usuario esté autenticado antes de acceder a esta pantalla.
  - La autenticación debe manejarse de manera segura para evitar vulnerabilidades.
  
  Características:
  - Muestra la imagen de perfil, nombre y apodo del usuario.
  - Permite al usuario ingresar su correo electrónico y contraseña para volver a autenticarse.
  - Proporciona un botón para continuar con la confirmación después de la reautenticación.
  - Utiliza Firebase Auth para realizar la reautenticación.
  
  Comentarios generales del código:
  - El código está dividido en dos clases principales: la clase `ConfirmIdentity` que es el widget principal, y el `ConfirmIdentityState` que maneja el estado.
  - Se hace uso de `Provider` para obtener los datos del usuario.
  - La imagen de perfil, nombre y apodo del usuario se obtienen de Firestore.
  - La reautenticación del usuario se realiza a través de Firebase Auth utilizando las credenciales del correo electrónico y la contraseña.
*/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../../../data/model/profile/deletion_request.dart';
import '../../../../../../data/provider_logics/user/user_provider.dart';
import '../../../../buttom_navigation_bar.dart';
import 'package:live_music/presentation/resources/colors.dart';
class ConfirmIdentity extends StatefulWidget {
  final GoRouter goRouter;
  final Function(DeletionRequest?) deletionRequest;

  const ConfirmIdentity({
    Key? key,
    required this.deletionRequest,
    required this.goRouter,
  }) : super(key: key);

  @override
  _ConfirmIdentityState createState() => _ConfirmIdentityState();
}

class _ConfirmIdentityState extends State<ConfirmIdentity> {
  // Variables para almacenar los datos del usuario
  String email = "";
  String password = "";
  String? profileImageUrl;
  String nickname = "";
  String name = "";

  @override
  void initState() {
    super.initState();
    // Llamada para obtener los datos del usuario al iniciar la pantalla
    _fetchUserData();
  }

  // Método para obtener los datos del usuario desde Firestore
  Future<void> _fetchUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.currentUserId;
    final userDoc =
        await FirebaseFirestore.instance
            .collection(AppStrings.usersCollection)
            .doc(currentUserId)
            .get();
    setState(() {
      email = userDoc.get(AppStrings.emailField) ?? "";
      profileImageUrl = userDoc.get(AppStrings.profileImageUrlField);
      nickname =
          userDoc.get(AppStrings.nicknameField) ?? AppStrings.unknownUser;
      name = userDoc.get(AppStrings.nameField) ?? AppStrings.unknownUser;
    });
  }

  // Método para reautenticar al usuario con Firebase Auth
  Future<void> _reauthenticateUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    if (user != null) {
      try {
        // Intento de reautenticación con las credenciales proporcionadas
        await user.reauthenticateWithCredential(credential);
        context.go(
          AppStrings.finalConfirmationRoute,
        ); // Navegar a la pantalla final de confirmación
      } catch (e) {
        // Si ocurre un error, se muestra un mensaje de error
        Fluttertoast.showToast(msg: "${AppStrings.error}: ${e.toString()}");
      }
    } else {
      // Si no se ha completado correctamente el formulario, se muestra un mensaje de error
      Fluttertoast.showToast(msg: AppStrings.fillAllFields);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se obtiene la información del proveedor de usuario
    final userProvider = Provider.of<UserProvider>(context);
    final colorScheme = ColorPalette.getPalette(context);

    final userType = userProvider.userType;
    final isArtist = userType == AppStrings.artist;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: widget.goRouter,
        isArtist: isArtist,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Barra superior con el botón de retroceso y el título
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme[AppStrings.essentialColor],
                    ),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        AppStrings.confirmIdentity,
                        style: TextStyle(
                          fontSize: 25,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Mostrar imagen de perfil
              CircleAvatar(
                backgroundImage:
                    profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : AssetImage(AppStrings.defaultUserImagePath)
                            as ImageProvider,
                radius: 50,
              ),
              const SizedBox(height: 10),
              // Mostrar nombre del usuario
              Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme[AppStrings.secondaryColor],
                ),
              ),
              const SizedBox(height: 6),
              // Mostrar apodo del usuario
              Text(
                nickname,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme[AppStrings.grayColor],
                ),
              ),
              const SizedBox(height: 16),
              // Campo de texto para ingresar el correo electrónico
              TextField(
                decoration: InputDecoration(
                  labelText: AppStrings.email,
                  labelStyle: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: colorScheme[AppStrings.primaryColor],
                ),
                style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
                onChanged: (value) => setState(() => email = value),
              ),
              const SizedBox(height: 16),
              // Campo de texto para ingresar la contraseña
              TextField(
                decoration: InputDecoration(
                  labelText: AppStrings.password,
                  labelStyle: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: colorScheme[AppStrings.primaryColor],
                ),
                style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
                obscureText: true,
                onChanged: (value) => setState(() => password = value),
              ),
              const SizedBox(height: 16),
              // Botón para reautenticar al usuario
              ElevatedButton(
                onPressed: _reauthenticateUser,
                child: Text(
                  AppStrings.continueText,
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: colorScheme[AppStrings.essentialColor],
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}