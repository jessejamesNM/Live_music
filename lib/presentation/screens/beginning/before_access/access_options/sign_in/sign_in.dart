/// Autor: kingdomOfJames
/// Fecha: 2025-04-22
///
/// Descripción:
/// Pantalla de opciones de inicio de sesión de la aplicación. Esta es una de las primeras
/// pantallas que se muestra al usuario luego de elegir el tipo de cuenta (artista o contratante).
/// Su objetivo es ofrecer distintos métodos de autenticación para acceder a la plataforma.
///
/// Actualmente soporta dos métodos de inicio de sesión:
/// 1. Correo electrónico y contraseña (navega a una pantalla aparte para introducir credenciales)
/// 2. Inicio de sesión con Google usando Firebase Auth
///
/// En el futuro está diseñada para escalar y soportar hasta:
/// - 3 métodos en Android: Email, Google y Facebook
/// - 4 métodos en Apple: Email, Google, Facebook e inicio de sesión con Apple (Apple Sign-In)
///
/// Características destacadas:
/// - Usa `GoRouter` para navegación
/// - Muestra errores si el usuario no está registrado
/// - Usa colores temáticos obtenidos dinámicamente de la paleta `ColorPalette`
/// - Usa assets SVG para los íconos de Google y el botón de email
/// - Control de carga (`isLoading`) para evitar múltiples intentos de inicio de sesión simultáneos
///
/// Consideraciones:
/// - `errorMessage` se muestra si hay errores con el login
/// - Si el usuario existe en Firebase pero no tiene el campo `isRegistered` o está en false,
///   se fuerza un cierre de sesión y se muestra el mensaje correspondiente
/// - Si en el futuro se agregan más métodos de login, se recomienda encapsular los botones en
///   un widget reutilizable para mantener la consistencia visual y lógica

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../../../../../resources/colors.dart';
import 'package:flutter_svg/svg.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:go_router/go_router.dart';

class LoginOptionsScreen extends StatefulWidget {
  final GoRouter goRouter;

  const LoginOptionsScreen({Key? key, required this.goRouter})
    : super(key: key);

  @override
  _LoginOptionsScreenState createState() => _LoginOptionsScreenState();
}

class _LoginOptionsScreenState extends State<LoginOptionsScreen> {
  bool isLoading = false;
  String errorMessage = "";
  bool isRegistered = false;

  void _signInWithGoogle() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? currentUser = userCredential.user;

      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();

        if (userDoc.exists) {
          setState(() {
            isRegistered = userDoc.get('isRegistered') ?? false;
          });

          if (!isRegistered) {
            setState(() {
              errorMessage = AppStrings.unregisteredUser;
            });
            await FirebaseAuth.instance.signOut();
          } else {
            widget.goRouter.go(AppStrings.homeScreenRoute);
          }
        } else {
          setState(() {
            errorMessage = AppStrings.unregisteredUser;
          });
          await FirebaseAuth.instance.signOut();
        }
      } else {
        setState(() {
          errorMessage = AppStrings.invalidUserIdError;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "${AppStrings.loginError}: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    // Design constants
    const double paddingAll = 16.0;
    const double iconPaddingTop = 16.0;
    const double textFieldSpacing = 8.0;
    const double buttonHeight = 45.0;
    const double buttonBorderWidth = 1.0;
    const double buttonIconSize = 24.0;
    const double buttonPaddingHorizontal = 10.0;
    const double titleFontSize = 32.0;
    const double svgIconSize = 23.0;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
      body: Padding(
        padding: EdgeInsets.all(paddingAll),
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
                  if (widget.goRouter.canPop()) {
                    widget.goRouter.pop();
                  } else {
                    widget.goRouter.go(AppStrings.selectionScreenRoute);
                  }
                },
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: paddingAll),
                  child: Text(
                    AppStrings.logIn,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color:
                          colorScheme[AppStrings.secondaryColor] ??
                          Colors.black,
                    ),
                  ),
                ),

                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        color: colorScheme[AppStrings.redColor] ?? Colors.red,
                      ),
                    ),
                  ),

                SizedBox(height: textFieldSpacing * 2.5),

                // Email button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: buttonPaddingHorizontal,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          colorScheme[AppStrings.essentialColor] ??
                          Colors.white,
                      side: BorderSide(
                        color:
                            colorScheme[AppStrings.essentialColor] ??
                            Colors.black,
                        width: buttonBorderWidth,
                      ),
                    ),
                    onPressed:
                        () => widget.goRouter.push(
                          AppStrings.loginMailScreenRoute,
                        ),
                    child: SizedBox(
                      height: buttonHeight,
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
                              size: buttonIconSize,
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

                SizedBox(height: textFieldSpacing),

                // Google button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: buttonPaddingHorizontal,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          colorScheme[AppStrings.primaryColor] ?? Colors.white,
                      side: BorderSide(
                        color:
                            colorScheme[AppStrings.secondaryColor] ??
                            Colors.black,
                        width: buttonBorderWidth,
                      ),
                    ),
                    onPressed: _signInWithGoogle,
                    child: SizedBox(
                      height: buttonHeight,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Positioned(
                            left: 0,
                            child: SvgPicture.asset(
                              AppStrings.googleIconPath,
                              width: svgIconSize,
                              height: svgIconSize,
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
              ],
            ),

            if (isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
