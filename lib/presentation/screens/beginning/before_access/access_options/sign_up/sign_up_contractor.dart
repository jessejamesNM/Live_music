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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/auth/register_with_apple_provider.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegisterWithGoogleProvider()),
        ChangeNotifierProvider(create: (_) => RegisterWithAppleProvider()),
      ],
      child: Consumer3<RegisterWithGoogleProvider, RegisterWithAppleProvider, UserProvider>(
        builder: (context, googleProvider, appleProvider, userProvider, child) {
          return RegisterOptionsContractorUI(
            registerWithGoogleProvider: googleProvider,
            registerWithAppleProvider: appleProvider,
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
  final RegisterWithAppleProvider registerWithAppleProvider;
  final UserProvider userProvider;
  final GoRouter goRouter;

  const RegisterOptionsContractorUI({
    Key? key,
    required this.registerWithGoogleProvider,
    required this.registerWithAppleProvider,
    required this.userProvider,
    required this.goRouter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    const double buttonHeight = 45.0;
    const double iconSize = 24.0;
    const double svgIconSize = 23.0;
    const double horizontalPadding = 10.0;
    const double titleFontSize = 32.0;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                ),
                onPressed: () {
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    AppStrings.signUp,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Botón de correo electrónico - Texto e icono en blanco
                _buildAuthButton(
                  icon: Icons.mail,
                  text: AppStrings.continueWithMail,
                  onPressed: () => goRouter.push(
                    AppStrings.registerContractorMailScreenRoute,
                  ),
                  colorScheme: colorScheme,
                  buttonHeight: buttonHeight,
                  iconSize: iconSize,
                  svgIconSize: svgIconSize,
                  horizontalPadding: horizontalPadding,
                  backgroundColor: AppStrings.essentialColor,
                  textColor: Colors.white, // Texto en blanco
                  iconColor: Colors.white, // Icono en blanco
                ),

                const SizedBox(height: 8),

                _buildAuthButton(
                  iconWidget: SvgPicture.asset(
                    AppStrings.googleIconPath,
                    width: svgIconSize,
                    height: svgIconSize,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                  text: AppStrings.continueWithGoogle,
                  onPressed: () => registerWithGoogleProvider.signInWithGoogle(
                    context,
                    userProvider,
                    goRouter,
                    AppStrings.contractor,
                  ),
                  colorScheme: colorScheme,
                  buttonHeight: buttonHeight,
                  iconSize: iconSize,
                  svgIconSize: svgIconSize,
                  horizontalPadding: horizontalPadding,
                  backgroundColor: AppStrings.primaryColor,
                  borderColor: AppStrings.secondaryColor,
                ),

                const SizedBox(height: 8),

                if (Theme.of(context).platform == TargetPlatform.iOS ||
                    Theme.of(context).platform == TargetPlatform.macOS)
                  _buildAuthButton(
                    iconWidget: Icon(
                      FontAwesomeIcons.apple,
                      size: iconSize,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                    text: AppStrings.continueWithApple,
                    onPressed: () => registerWithAppleProvider.signInWithApple(
                      context,
                      userProvider,
                      goRouter,
                      AppStrings.contractor,
                    ),
                    colorScheme: colorScheme,
                    buttonHeight: buttonHeight,
                    iconSize: iconSize,
                    svgIconSize: svgIconSize,
                    horizontalPadding: horizontalPadding,
                    backgroundColor: AppStrings.primaryColor,
                    borderColor: AppStrings.secondaryColor,
                  ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextButton(
                    onPressed: () => goRouter.push(AppStrings.loginOptionsScreenRoute),
                    child: Text(
                      AppStrings.logIn,
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
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

  Widget _buildAuthButton({
    IconData? icon,
    Widget? iconWidget,
    required String text,
    required VoidCallback onPressed,
    required Map<String, Color?> colorScheme,
    required double buttonHeight,
    required double iconSize,
    required double svgIconSize,
    required double horizontalPadding,
    required String backgroundColor,
    String borderColor = '',
    Color? textColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme[backgroundColor] ?? Colors.white,
          side: BorderSide(
            color: borderColor.isNotEmpty
                ? colorScheme[borderColor] ?? Colors.black
                : colorScheme[backgroundColor] ?? Colors.black,
          ),
          minimumSize: Size(double.infinity, buttonHeight),
        ),
        onPressed: onPressed,
        child: SizedBox(
          height: buttonHeight,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (iconWidget != null || icon != null)
                Positioned(
                  left: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: iconWidget ??
                        Icon(
                          icon,
                          color: iconColor ?? colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                          size: iconSize,
                        ),
                  ),
                ),
              Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor ?? colorScheme[AppStrings.secondaryColor] ?? Colors.black,
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