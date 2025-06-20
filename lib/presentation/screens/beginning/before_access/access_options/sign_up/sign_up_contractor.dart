/// Autor: kingdomOfJames
/// Fecha: 2025-04-22
///
/// Descripción:
/// `RegisterOptionsContractorScreen` es una pantalla que ofrece al usuario las opciones
/// de registro para la categoría de "Contratista" mediante distintos métodos de autenticación
/// (correo electrónico o Google). Este widget maneja la navegación hacia diferentes pantallas
/// de registro dependiendo de la opción seleccionada por el usuario.
/// Se utiliza `ChangeNotifierProvider` para manejar la autenticación de Google y la gestión
/// del estado del usuario. `RegisterOptionsContractorUI` es el componente UI que muestra las
/// opciones de registro.
///
/// Características:
/// - Proporciona dos opciones de registro: con Google o correo electrónico.
/// - Navega a la pantalla de registro con correo electrónico o inicia el flujo de autenticación con Google.
/// - Muestra un botón de "volver" que regresa a la pantalla de selección.
/// - Utiliza `GoRouter` para la navegación.
/// - Incluye la lógica de cambio de estado con `RegisterWithGoogleProvider` y `UserProvider`.
///
/// Parámetros:
/// - `goRouter`: instancia de `GoRouter` para manejar la navegación entre pantallas.
///
/// Notas:
/// - Los botones de autenticación están diseñados para cumplir con el tema visual de la aplicación.
/// - El `ChangeNotifierProvider` envuelve la pantalla para permitir el uso del `RegisterWithGoogleProvider`
///   y el `UserProvider`, que gestionan el registro y el estado del usuario.
/// - El widget incluye constantes de diseño como márgenes y espaciamientos para garantizar una UI consistente.
///

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../../data/provider_logics/auth/register_wigh_google_provider.dart';
import '../../../../../../data/provider_logics/user/user_provider.dart';
import '../../../../../resources/colors.dart';
import '../../../../../resources/strings.dart';

class RegisterOptionsContractorScreen extends StatelessWidget {
  final GoRouter goRouter;

  const RegisterOptionsContractorScreen({Key? key, required this.goRouter})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Proveedor de estado para la autenticación con Google
    return ChangeNotifierProvider(
      create: (_) => RegisterWithGoogleProvider(),
      child: Consumer2<RegisterWithGoogleProvider, UserProvider>(
        builder: (context, registerWithGoogleProvider, userProvider, child) {
          return RegisterOptionsContractorUI(
            registerWithGoogleProvider: registerWithGoogleProvider,
            userProvider: userProvider,
            goRouter: goRouter,
          );
        },
      ),
    );
  }
}

class RegisterOptionsContractorUI extends StatelessWidget {
  final RegisterWithGoogleProvider registerWithGoogleProvider;
  final UserProvider userProvider;
  final GoRouter goRouter;

  const RegisterOptionsContractorUI({
    Key? key,
    required this.registerWithGoogleProvider,
    required this.userProvider,
    required this.goRouter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtener esquema de colores

    return Scaffold(
      backgroundColor:
          colorScheme[AppStrings.primaryColor] ??
          Colors.white, // Fondo personalizado
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Stack(
          children: [
            // Botón de retroceso
            Positioned(
              top: 16,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                ),
                onPressed: () {
                  // Regresar a la pantalla anterior o a la pantalla de selección si no hay más pantallas
                  if (goRouter.canPop()) {
                    goRouter.pop();
                  } else {
                    goRouter.go(AppStrings.selectionScreenRoute);
                  }
                },
              ),
            ),
            // Contenido principal de la pantalla
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Título de la pantalla
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    AppStrings.signUp,
                    style: TextStyle(
                      fontSize: 32,
                      color:
                          colorScheme[AppStrings.secondaryColor] ??
                          Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Botón para registrarse con correo electrónico
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          colorScheme[AppStrings.essentialColor] ??
                          Colors.white,
                      side: BorderSide(
                        color:
                            colorScheme[AppStrings.essentialColor] ??
                            Colors.black,
                      ),
                    ),
                    onPressed:
                        () => goRouter.push(
                          AppStrings.registerContractorMailScreenRoute,
                        ),
                    child: SizedBox(
                      height: 45,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Positioned(
                            left: 0,
                            child: Icon(
                              Icons.mail,
                              color:
                                  colorScheme[AppStrings.secondaryColor] ??
                                  Colors.black,
                              size: 24,
                            ),
                          ),
                          Center(
                            child: Text(
                              AppStrings.continueWithMail,
                              style: TextStyle(
                                color:
                                    colorScheme[AppStrings.secondaryColor] ??
                                    Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Botón para registrarse con Google
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          colorScheme[AppStrings.primaryColor] ?? Colors.white,
                      side: BorderSide(
                        color:
                            colorScheme[AppStrings.secondaryColor] ??
                            Colors.black,
                      ),
                    ),
                    onPressed:
                        () => registerWithGoogleProvider.signInWithGoogle(
                          context,
                          userProvider,
                          goRouter,
                          AppStrings.contractor,
                        ),
                    child: SizedBox(
                      height: 45,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Positioned(
                            left: 0,
                            child: SvgPicture.asset(
                              AppStrings.googleIconPath,
                              width: 23,
                              height: 23,
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                          ),
                          Center(
                            child: Text(
                              AppStrings.continueWithGoogle,
                              style: TextStyle(
                                color:
                                    colorScheme[AppStrings.secondaryColor] ??
                                    Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Enlace para iniciar sesión
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextButton(
                    onPressed:
                        () => goRouter.push(AppStrings.loginOptionsScreenRoute),
                    child: Text(
                      AppStrings.logIn,
                      style: TextStyle(
                        color:
                            colorScheme[AppStrings.secondaryColor] ??
                            Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
