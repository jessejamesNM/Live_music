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
    final userType = userProvider.userType;
    final isArtist = userType == AppStrings.artist;
    final colorScheme = ColorPalette.getPalette(context);

    var reason = ""; // Variable local para almacenar el texto del TextField

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
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
                  // Header con botón de retroceso y título
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: colorScheme[AppStrings.secondaryColor],
                            size: 28 * scale,
                          ),
                          onPressed: () {
                            try {
                              context.pop();
                            } catch (e) {
                              goRouter.go(AppStrings.myAccountScreenRoute);
                            }
                          },
                        ),
                      ),
                      FittedBox(
                        child: Text(
                          AppStrings.deleteAccount,
                          style: TextStyle(
                            fontSize: 25 * scale,
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * scale),
                  // Mensaje sobre la eliminación de la cuenta
                  FittedBox(
                    child: Text(
                      AppStrings.accountDeletionMessage,
                      style: TextStyle(
                        fontSize: 14 * scale,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  // Campo de texto para ingresar razón de eliminación
                  TextField(
                    decoration: InputDecoration(
                      labelText: AppStrings.deletionReason,
                      labelStyle: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: 14 * scale,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: colorScheme[AppStrings.secondaryColor]!,
                        ),
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: colorScheme[AppStrings.essentialColor]!,
                        ),
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                    ),
                    style: TextStyle(
                      color: colorScheme[AppStrings.secondaryColor],
                      fontSize: 14 * scale,
                    ),
                    onChanged: (value) => reason = value,
                  ),
                  SizedBox(height: 16 * scale),
                  // Botón de continuar
                  SizedBox(
                    width: double.infinity,
                    height: 50 * scale,
                    child: ElevatedButton(
                      onPressed: () {
                        if (reason.isNotEmpty) {
                          userProvider.deletionRequest = reason;

                          final isGoogleUser = FirebaseAuth.instance.currentUser
                                  ?.providerData
                                  .any((info) =>
                                      info.providerId ==
                                      GoogleAuthProvider.PROVIDER_ID) ??
                              false;

                          if (isGoogleUser) {
                            context.go(AppStrings.finalConfirmationRoute);
                          } else {
                            context.go(AppStrings.confirmIdentityRoute);
                          }
                        } else {
                          Fluttertoast.showToast(
                            msg: AppStrings.enterReasonMessage,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            colorScheme[AppStrings.essentialColor],
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