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
  String email = "";
  String password = "";
  String? profileImageUrl;
  String nickname = "";
  String name = "";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final userDoc = await FirebaseFirestore.instance
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

  Future<void> _reauthenticateUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    if (user != null) {
      try {
        await user.reauthenticateWithCredential(credential);
        context.go(AppStrings.finalConfirmationRoute);
      } catch (e) {
        Fluttertoast.showToast(
            msg: "${AppStrings.error}: ${e.toString()}");
      }
    } else {
      Fluttertoast.showToast(msg: AppStrings.fillAllFields);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final colorScheme = ColorPalette.getPalette(context);
    final userType = userProvider.userType;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: widget.goRouter,
        userType: userType,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final widthFactor = constraints.maxWidth / 400;
            final heightFactor = constraints.maxHeight / 800;
            final scale = widthFactor < heightFactor ? widthFactor : heightFactor;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Barra superior con botón de retroceso y título
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: colorScheme[AppStrings.essentialColor],
                          size: 28 * scale,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            child: Text(
                              AppStrings.confirmIdentity,
                              style: TextStyle(
                                fontSize: 25 * scale,
                                color: colorScheme[AppStrings.secondaryColor],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * scale),
                  // Imagen de perfil
                  CircleAvatar(
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : AssetImage(AppStrings.defaultUserImagePath)
                            as ImageProvider,
                    radius: 50 * scale,
                  ),
                  SizedBox(height: 10 * scale),
                  // Nombre del usuario
                  FittedBox(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 18 * scale,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  // Apodo del usuario
                  FittedBox(
                    child: Text(
                      nickname,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        color: colorScheme[AppStrings.grayColor],
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  // Campo de correo electrónico
                  TextField(
                    decoration: InputDecoration(
                      labelText: AppStrings.email,
                      labelStyle: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: 14 * scale,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      filled: true,
                      fillColor: colorScheme[AppStrings.primaryColor],
                    ),
                    style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: 14 * scale),
                    onChanged: (value) => setState(() => email = value),
                  ),
                  SizedBox(height: 16 * scale),
                  // Campo de contraseña
                  TextField(
                    decoration: InputDecoration(
                      labelText: AppStrings.password,
                      labelStyle: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: 14 * scale,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      filled: true,
                      fillColor: colorScheme[AppStrings.primaryColor],
                    ),
                    style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: 14 * scale),
                    obscureText: true,
                    onChanged: (value) => setState(() => password = value),
                  ),
                  SizedBox(height: 16 * scale),
                  // Botón de continuar
                  SizedBox(
                    width: double.infinity,
                    height: 50 * scale,
                    child: ElevatedButton(
                      onPressed: _reauthenticateUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme[AppStrings.essentialColor],
                        foregroundColor: Colors.white,
                      ),
                      child: FittedBox(
                        child: Text(
                          AppStrings.continueText,
                          style: TextStyle(
                            fontSize: 16 * scale,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}