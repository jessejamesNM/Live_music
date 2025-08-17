/*
  Fecha de creación: 2025-04-26
  Autor: KingdomOfJames
  Descripción: 
    Esta pantalla es responsable de la gestión de la solicitud de eliminación de cuenta del usuario. 
    Permite al usuario ingresar una razón para la eliminación y luego dirigirlo al flujo de confirmación, 
    dependiendo de si el usuario está registrado a través de Google o no. También maneja la navegación hacia 
    otras pantallas y la validación de la razón ingresada.

  Recomendaciones:
    - Asegúrate de que los textos, como el motivo de eliminación, se validen correctamente para evitar entradas vacías.
    - Puedes implementar una confirmación adicional para que el usuario esté completamente seguro antes de eliminar su cuenta.
    - Verifica que la lógica de navegación y los flujos de Firebase (GoogleAuthProvider y demás) estén correctamente configurados.

  Características:
    - Muestra una interfaz con un botón de retroceso y un formulario para ingresar el motivo de eliminación de la cuenta.
    - Validación simple de campo de texto para la razón de eliminación.
    - Navegación condicional dependiendo del método de autenticación del usuario (Google o correo electrónico).
*/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../../buttom_navigation_bar.dart';

class DeleteAccount extends StatelessWidget {
  final GoRouter goRouter;
  final UserProvider userProvider;

  const DeleteAccount({
    Key? key,
    required this.goRouter,
    required this.userProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userType = userProvider.userType; // Obtener el tipo de usuario
    final isArtist =
        userType == AppStrings.artist; // Verificar si el usuario es artista
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtener los colores del tema

    var reason = ""; // Variable local para almacenar el texto del TextField

    return Scaffold(
      backgroundColor:
          colorScheme[AppStrings.primaryColor], // Fondo con el color primario
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
        userType: userType,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                      onPressed: () {
                        try {
                          // Intentamos hacer pop en la pila de navegación
                          context.pop();
                        } catch (e) {
                          // Si falla, navegamos a la ruta /myaccountscreen
                          goRouter.go(AppStrings.myAccountScreenRoute);
                        }
                      },
                    ),
                  ),
                  Text(
                    AppStrings.deleteAccount, // Título de la pantalla
                    style: TextStyle(
                      fontSize: 25,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                AppStrings
                    .accountDeletionMessage, // Mensaje sobre la eliminación de la cuenta
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme[AppStrings.secondaryColor],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText:
                      AppStrings
                          .deletionReason, // Etiqueta para el campo de texto
                  labelStyle: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme[AppStrings.secondaryColor]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme[AppStrings.essentialColor]!,
                    ),
                  ),
                ),
                style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
                onChanged:
                    (value) =>
                        reason = value, // Actualizar la razón de eliminación
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (reason.isNotEmpty) {
                    userProvider.deletionRequest =
                        reason; // Guardar la razón en el proveedor

                    final isGoogleUser =
                        FirebaseAuth.instance.currentUser?.providerData.any(
                          (info) =>
                              info.providerId == GoogleAuthProvider.PROVIDER_ID,
                        ) ??
                        false;

                    // Navegar a la pantalla de confirmación según el tipo de usuario
                    if (isGoogleUser) {
                      context.go(AppStrings.finalConfirmationRoute);
                    } else {
                      context.go(AppStrings.confirmIdentityRoute);
                    }
                  } else {
                    Fluttertoast.showToast(
                      msg: AppStrings.enterReasonMessage,
                    ); // Mostrar mensaje si no se ingresa razón
                  }
                },
                child: Text(AppStrings.continueText), // Texto del botón
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: colorScheme[AppStrings.essentialColor],
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
