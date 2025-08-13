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

import 'dart:io';

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
class RegisterOptionsArtistScreen extends StatelessWidget {
  final GoRouter goRouter;

  const RegisterOptionsArtistScreen({Key? key, required this.goRouter})
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
          return RegisterOptionsArtistUI(
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

class RegisterOptionsArtistUI extends StatelessWidget {
  final RegisterWithGoogleProvider registerWithGoogleProvider;
  final RegisterWithAppleProvider registerWithAppleProvider;
  final UserProvider userProvider;
  final GoRouter goRouter;

  const RegisterOptionsArtistUI({
    Key? key,
    required this.registerWithGoogleProvider,
    required this.registerWithAppleProvider,
    required this.userProvider,
    required this.goRouter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

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

    final String userType = userProvider.userType ?? '';

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(paddingAll),
        child: Stack(
          children: [
            Positioned(
              top: iconPaddingTop,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                  size: 26.0,
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

                // Registro con correo - Texto en blanco
                _buildAuthButton(
                  icon: Icons.mail,
                  text: AppStrings.continueWithMail,
                  onPressed: () {
                    if (userType.isNotEmpty) {
                      goRouter.push(AppStrings.registerArtistMailScreenRoute);
                    } else {
                      _showUserTypeError(context);
                    }
                  },
                  colorScheme: colorScheme,
                  buttonHeight: buttonHeight,
                  buttonIconSize: buttonIconSize,
                  buttonPaddingHorizontal: buttonPaddingHorizontal,
                  buttonBorderWidth: buttonBorderWidth,
                  backgroundColor: AppStrings.essentialColor,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                ),
                const SizedBox(height: textFieldSpacing),

                // Registro con Google - Mantiene secondaryColor
                _buildAuthButton(
                  iconWidget: SvgPicture.asset(
                    AppStrings.googleIconPath,
                    width: svgIconSize,
                    height: svgIconSize,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                  text: AppStrings.continueWithGoogle,
                  onPressed: () {
                    if (userType.isNotEmpty) {
                      registerWithGoogleProvider.signInWithGoogle(
                        context,
                        userProvider,
                        goRouter,
                        userType,
                      );
                    } else {
                      _showUserTypeError(context);
                    }
                  },
                  colorScheme: colorScheme,
                  buttonHeight: buttonHeight,
                  buttonIconSize: buttonIconSize,
                  buttonPaddingHorizontal: buttonPaddingHorizontal,
                  buttonBorderWidth: buttonBorderWidth,
                  backgroundColor: AppStrings.primaryColor,
                  borderColor: AppStrings.secondaryColor,
                  textColor: colorScheme[AppStrings.secondaryColor],
                ),
                
                const SizedBox(height: textFieldSpacing),
                
                // Registro con Apple - Nuevo botón
                if (Platform.isIOS)
               // Cambia esta parte del código donde creas el botón de Apple
_buildAuthButton(
  iconWidget: SvgPicture.asset(
    'assets/svg/apple_logo.svg',
    width: svgIconSize,
    height: svgIconSize,
    color: Colors.white,
  ),
  text: AppStrings.continueWithApple,
  onPressed: () {
    if (userType.isNotEmpty) {
      registerWithAppleProvider.signInWithApple(
        context,
        userProvider,
        goRouter,
        userType,
      );
    } else {
      _showUserTypeError(context);
    }
  },
  colorScheme: colorScheme,
  buttonHeight: buttonHeight,
  buttonIconSize: buttonIconSize,
  buttonPaddingHorizontal: buttonPaddingHorizontal,
  buttonBorderWidth: buttonBorderWidth,
  backgroundColor: 'black', // Cambiado a String en lugar de Colors.black
  textColor: Colors.white,
),

                const SizedBox(height: textFieldSpacing),
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

  void _showUserTypeError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Por favor selecciona un tipo de usuario antes de continuar.',
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
    required double buttonIconSize,
    required double buttonPaddingHorizontal,
    required double buttonBorderWidth,
    required String backgroundColor,
    String borderColor = '',
    Color? textColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: buttonPaddingHorizontal),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor == 'black' 
              ? Colors.black 
              : colorScheme[backgroundColor] ?? Colors.white,
          side: BorderSide(
            color: borderColor.isNotEmpty
                ? colorScheme[borderColor] ?? Colors.black
                : backgroundColor == 'black'
                    ? Colors.black
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
              if (iconWidget != null || icon != null)
                Positioned(
                  left: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: iconWidget ??
                        Icon(
                          icon,
                          color: iconColor ??
                              colorScheme[AppStrings.secondaryColor] ??
                              Colors.black,
                          size: buttonIconSize,
                        ),
                  ),
                ),
              Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor ??
                        colorScheme[AppStrings.secondaryColor] ??
                        Colors.black,
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