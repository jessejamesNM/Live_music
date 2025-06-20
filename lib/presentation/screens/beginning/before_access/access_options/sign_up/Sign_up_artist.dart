/// Autor: kingdomOfJames
/// Fecha: 2025-04-22
///
/// Descripción:
/// `RegisterOptionsArtistScreen` es una pantalla que ofrece al usuario las opciones
/// de registro para la categoría de "Artista" mediante distintos métodos de autenticación
/// (correo electrónico o Google). Este widget maneja la lógica de navegación hacia
/// diferentes pantallas de registro dependiendo de la opción seleccionada por el usuario.
/// Se usa un `ChangeNotifierProvider` para manejar la autenticación de Google y la gestión
/// del estado del usuario, mientras que `RegisterOptionsArtistUI` es el componente UI
/// que muestra las opciones de registro.
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

class RegisterOptionsArtistScreen extends StatelessWidget {
  final GoRouter goRouter;

  // Constructor que recibe el objeto 'goRouter' para manejar la navegación.
  const RegisterOptionsArtistScreen({Key? key, required this.goRouter})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Se crea un proveedor de estado para manejar el registro con Google.
      create: (_) => RegisterWithGoogleProvider(),
      child: Consumer2<RegisterWithGoogleProvider, UserProvider>(
        // El Consumer escucha cambios en los proveedores de estado y actualiza la UI.
        builder: (context, registerWithGoogleProvider, userProvider, child) {
          return RegisterOptionsArtistUI(
            // Se pasa el estado y los datos necesarios al widget de UI.
            registerWithGoogleProvider: registerWithGoogleProvider,
            userProvider: userProvider,
            goRouter: goRouter,
          );
        },
      ),
    );
  }
}

class RegisterOptionsArtistUI extends StatelessWidget {
  final RegisterWithGoogleProvider registerWithGoogleProvider;
  final UserProvider userProvider;
  final GoRouter goRouter;

  // Constructor que recibe los proveedores y el objeto 'goRouter'.
  const RegisterOptionsArtistUI({
    Key? key,
    required this.registerWithGoogleProvider,
    required this.userProvider,
    required this.goRouter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenemos el esquema de colores de la aplicación.
    final colorScheme = ColorPalette.getPalette(context);

    // Definimos constantes de diseño para la UI.
    const double paddingAll = 16.0;
    const double iconPaddingTop = 16.0;
    const double textFieldSpacing = 8.0;
    const double buttonHeight = 45.0;
    const double buttonBorderWidth = 1.0;
    const double buttonIconSize = 24.0;
    const double buttonPaddingHorizontal = 10.0;
    const double titleFontSize = 32.0;
    const double buttonFontSize = 16.0;
    const double svgIconSize = 23.0;

    return Scaffold(
      // Establecemos el color de fondo de la pantalla usando el esquema de colores.
      backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(paddingAll),
        child: Stack(
          children: [
            Positioned(
              top: iconPaddingTop,
              // Botón para navegar hacia atrás.
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                  size: 26.0,
                ),
                onPressed: () {
                  // Si es posible, navega hacia atrás, sino regresa a la pantalla de selección.
                  if (goRouter.canPop()) {
                    goRouter.pop();
                  } else {
                    goRouter.go(AppStrings.selectionScreenRoute);
                  }
                },
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Título de la pantalla de registro.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: paddingAll),
                  child: Text(
                    AppStrings.signUp,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color:
                          colorScheme[AppStrings.secondaryColor] ??
                          Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: textFieldSpacing * 2.5),
                // Botón de registro con correo electrónico.
                _buildAuthButton(
                  icon: Icons.mail,
                  text: AppStrings.continueWithMail,
                  onPressed:
                      () => goRouter.push(
                        AppStrings.registerArtistMailScreenRoute,
                      ),
                  colorScheme: colorScheme,
                  buttonHeight: buttonHeight,
                  buttonIconSize: buttonIconSize,
                  buttonPaddingHorizontal: buttonPaddingHorizontal,
                  buttonBorderWidth: buttonBorderWidth,
                  backgroundColor: AppStrings.essentialColor,
                ),
                const SizedBox(height: textFieldSpacing),
                // Botón de registro con Google.
                _buildAuthButton(
                  iconWidget: SvgPicture.asset(
                    AppStrings.googleIconPath,
                    width: svgIconSize,
                    height: svgIconSize,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                  text: AppStrings.continueWithGoogle,
                  onPressed:
                      () => registerWithGoogleProvider.signInWithGoogle(
                        context,
                        userProvider,
                        goRouter,
                        AppStrings.artist,
                      ),
                  colorScheme: colorScheme,
                  buttonHeight: buttonHeight,
                  buttonIconSize: buttonIconSize,
                  buttonPaddingHorizontal: buttonPaddingHorizontal,
                  buttonBorderWidth: buttonBorderWidth,
                  backgroundColor: AppStrings.primaryColor,
                  borderColor: AppStrings.secondaryColor,
                ),
                const SizedBox(height: textFieldSpacing),
                // Botón de texto para ir a la pantalla de login.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: paddingAll),
                  child: TextButton(
                    onPressed:
                        () => goRouter.push(AppStrings.loginOptionsScreenRoute),
                    child: Text(
                      AppStrings.logIn,
                      style: TextStyle(
                        color:
                            colorScheme[AppStrings.secondaryColor] ??
                            Colors.black,
                        fontSize: buttonFontSize,
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

  // Método para construir los botones de autenticación (email, Google, etc.).
  Widget _buildAuthButton({
    IconData? icon,
    Widget? iconWidget,
    required String text,
    required VoidCallback onPressed,
    required Map<String, Color?> colorScheme,
    required double buttonHeight,
    required double buttonIconSize,
    required double buttonPaddingHorizontal,
    required double buttonBorderWidth,
    required String backgroundColor,
    String borderColor = '',
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: buttonPaddingHorizontal),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme[backgroundColor] ?? Colors.white,
          side: BorderSide(
            color:
                borderColor.isNotEmpty
                    ? colorScheme[borderColor] ?? Colors.black
                    : colorScheme[backgroundColor] ?? Colors.black,
            width: buttonBorderWidth,
          ),
        ),
        onPressed: onPressed,
        child: SizedBox(
          height: buttonHeight,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: 0,
                child:
                    iconWidget ??
                    Icon(
                      icon,
                      color:
                          colorScheme[AppStrings.secondaryColor] ??
                          Colors.black,
                      size: buttonIconSize,
                    ),
              ),
              Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color:
                        colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
