/// Author: kingdomOfJames
/// Date: 2025-04-22
///
/// Descripción:
/// Esta es la pantalla de inicio de sesión por correo electrónico (`LoginMailScreen`) que se muestra
/// después de seleccionar "iniciar sesión con correo" desde la pantalla de selección de opciones.
/// Forma parte del flujo de autenticación de la app y permite al usuario ingresar su correo electrónico
/// y contraseña para acceder a su cuenta.
///
/// Características clave:
/// - Campos de entrada con estilo personalizado para correo y contraseña.
/// - Validación básica del formato del correo electrónico y campos vacíos.
/// - Muestra mensajes de error si los datos son incorrectos o faltan.
/// - Usa Firebase Authentication para realizar el inicio de sesión.
/// - Navega a la pantalla principal (`/home`) si el login es exitoso.
/// - Incluye opción para recuperar contraseña.
/// - Muestra un mensaje tipo "snackbar" al enviar el correo de recuperación de contraseña.
/// - Utiliza colores temáticos a través de `ColorPalette` y textos desde `AppStrings`.
///
/// Sugerencias:
/// - Considerar ocultar el botón de login y mostrar un loader mientras se realiza la autenticación.
/// - El patrón de validación de correo puede mejorarse para admitir dominios con múltiples puntos (ej: .co.uk).
/// - El componente de mensaje inferior podría reutilizarse como un widget separado si se usa en otras pantallas.
///
/// Esta pantalla es parte del flujo central de la app y representa un punto crítico para la conversión de usuarios.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_music/data/model/global_variables.dart';
import 'package:live_music/data/provider_logics/beginning/beginning_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/colors.dart';

class LoginMailScreen extends StatefulWidget {
  final FirebaseAuth auth;
  final GoRouter goRouter;
  final FirebaseFirestore firestore;
  final BeginningProvider beginningProvider;

  const LoginMailScreen({
    Key? key,
    required this.auth,
    required this.goRouter,
    required this.firestore,
    required this.beginningProvider,
  }) : super(key: key);

  @override
  _LoginMailScreenState createState() => _LoginMailScreenState();
}

class _LoginMailScreenState extends State<LoginMailScreen> {
  String email = "";
  String password = "";
  String? errorMessage;
  bool showMessage = false;
  bool _obscurePassword = true;

  bool isEmailValid(String email) {
    return emailPattern.hasMatch(email);
  }

  Future<String> _determineInitialRoute() async {
    final currentUser = widget.auth.currentUser;

    if (currentUser == null) {
      return AppStrings.selectionScreenRoute;
    }

    final currentUserId = currentUser.uid;

    try {
      final userDoc =
          await widget.firestore.collection('users').doc(currentUserId).get();
      final data = userDoc.data() ?? {};

      if (!userDoc.exists || (data['isRegistered'] ?? false) != true) {
        return AppStrings.selectionScreenRoute;
      }

      if (data.containsKey('createdService')) {
        return AppStrings.homeScreenRoute;
      }

      final isVerified = data['isVerified'] ?? false;
      final name = data['name'] ?? '';
      final nickname = data['nickname'] ?? '';
      final profileImageUrl = data['profileImageUrl'] ?? '';
      final country = data['country'] ?? '';
      final state = data['state'] ?? '';
      final genres = data['genres'] as List<dynamic>? ?? [];
      final specialty = data['specialty'] ?? '';
      final countries = data['countries'] as List<dynamic>? ?? [];
      final states = data['states'] as List<dynamic>? ?? [];
      final userType = data['userType'] ?? '';
      final age = data['age'];
      final acceptedTerms = data['acceptedTerms'];
      final acceptedPrivacy = data['acceptedPrivacy'];

      final isArtistType =
          userType == 'artist' || userType == 'bakery' || userType == 'place' || userType == 'decoration';

      if (!isVerified) {
        return AppStrings.waitingConfirmScreenRoute;
      }

      widget.beginningProvider.setRouteToGo(AppStrings.welcomeScreenRoute);

      if (!isArtistType) {
        if (age == null || acceptedTerms != true || acceptedPrivacy != true) {
          return AppStrings.ageTermsScreenRoute;
        }
        if (name.isEmpty) return AppStrings.usernameScreen;
        if (nickname.isEmpty) return AppStrings.nicknameScreenRoute;
      } else {
        widget.beginningProvider.setRouteToGo(AppStrings.profileImageScreenRoute);

        if (age == null || acceptedTerms != true || acceptedPrivacy != true) {
          return AppStrings.ageTermsScreenRoute;
        }
        if (isVerified && name.isEmpty) return AppStrings.verifyEmailRoute;
        if (name.isEmpty) return AppStrings.groupNameScreenRoute;
        if (nickname.isEmpty) return AppStrings.nicknameScreenRoute;
        if (profileImageUrl.isEmpty) return AppStrings.profileImageScreenRoute;
        if (userType == 'artist' && genres.isEmpty) return AppStrings.musicGenresScreenRoute;
        if (specialty.isEmpty) return AppStrings.eventSpecializationScreenRoute;
        if (countries.isEmpty || states.isEmpty) return AppStrings.userCanWorkCountryStateScreenRoute;
        if (country.isEmpty || state.isEmpty) return AppStrings.countryStateScreenRoute;

        final serviceDoc = await widget.firestore.collection('services').doc(currentUserId).get();
        if (!serviceDoc.exists) return AppStrings.priceScreenRoute;

        final serviceCollectionRef = widget.firestore
            .collection('services')
            .doc(currentUserId)
            .collection('service');

        for (int i = 0; i < 8; i++) {
          final docId = 'service$i';
          final doc = await serviceCollectionRef.doc(docId).get();
          if (!doc.exists) continue;

          final data = doc.data() ?? {};
          final price = data['price'];
          final info = data['information'];
          final images = data['imageList'] as List<dynamic>?;

          final isPriceValid = price != null && (price is num) && price > 0;
          final isInfoValid = info != null && info.toString().trim().isNotEmpty;
          final hasImages = images != null && images.isNotEmpty;

          if (!isPriceValid || !isInfoValid || !hasImages) return AppStrings.priceScreenRoute;
        }
      }

      return AppStrings.homeScreenRoute;
    } catch (e) {
      return AppStrings.selectionScreenRoute;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    // Tamaños adaptativos
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final horizontalPadding = screenWidth * 0.08;
    final verticalSpacing = screenHeight * 0.025;
    final textFontSize = screenWidth * 0.055;
    final inputPadding = screenHeight * 0.02;
    final buttonHeight = screenHeight * 0.065;
    final borderRadius = screenWidth * 0.03;
    final iconSize = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.03, left: screenWidth * 0.03),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme[AppStrings.secondaryColor],
                      size: iconSize,
                    ),
                    onPressed: () => widget.goRouter.go(AppStrings.loginOptionsScreenRoute),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppStrings.logIn,
                            style: TextStyle(
                              color: colorScheme[AppStrings.secondaryColor],
                              fontSize: textFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: verticalSpacing),
                        // Email
                        TextField(
                          decoration: InputDecoration(
                            hintText: AppStrings.email,
                            filled: true,
                            fillColor: colorScheme[AppStrings.primaryColor],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: colorScheme[AppStrings.secondaryColor]!,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: colorScheme[AppStrings.secondaryColor]!,
                                width: 1.5,
                              ),
                            ),
                            hintStyle: TextStyle(
                              color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.7),
                              fontSize: textFontSize * 0.85,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: inputPadding,
                            ),
                          ),
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor],
                            fontSize: textFontSize * 0.9,
                          ),
                          onChanged: (value) => setState(() => email = value),
                        ),
                        SizedBox(height: verticalSpacing * 0.8),
                        // Password
                        TextField(
                          decoration: InputDecoration(
                            hintText: AppStrings.password,
                            filled: true,
                            fillColor: colorScheme[AppStrings.primaryColor],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: colorScheme[AppStrings.secondaryColor]!,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: colorScheme[AppStrings.secondaryColor]!,
                                width: 1.5,
                              ),
                            ),
                            hintStyle: TextStyle(
                              color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.7),
                              fontSize: textFontSize * 0.85,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: inputPadding,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: colorScheme[AppStrings.secondaryColor],
                                size: iconSize,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor],
                            fontSize: textFontSize * 0.9,
                          ),
                          obscureText: _obscurePassword,
                          onChanged: (value) => setState(() => password = value),
                        ),
                        SizedBox(height: verticalSpacing * 0.5),
                        if (errorMessage != null)
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: textFontSize * 0.7,
                            ),
                          ),
                        SizedBox(height: verticalSpacing),
                        // Botón Login
                        SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (email.isEmpty || password.isEmpty) {
                                setState(() => errorMessage = AppStrings.emptyFieldsError);
                              } else if (!isEmailValid(email)) {
                                setState(() => errorMessage = AppStrings.invalidEmailError);
                              } else {
                                try {
                                  await widget.auth.signInWithEmailAndPassword(
                                    email: email,
                                    password: password,
                                  );
                                  setState(() => errorMessage = null);
                                  final initialRoute = await _determineInitialRoute();
                                  widget.goRouter.go(initialRoute);
                                } on FirebaseAuthException {
                                  setState(() => errorMessage = AppStrings.incorrectCredentials);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme[AppStrings.essentialColor],
                              foregroundColor: colorScheme[AppStrings.primaryColor],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(borderRadius),
                              ),
                              padding: EdgeInsets.symmetric(vertical: inputPadding * 0.6),
                              elevation: 4,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppStrings.logIn,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: textFontSize * 0.9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: verticalSpacing),
                        GestureDetector(
                          onTap: () => widget.goRouter.push(AppStrings.forgotPasswordScreenRoute),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppStrings.forgotPassword,
                              style: TextStyle(
                                color: colorScheme[AppStrings.secondaryColor],
                                decoration: TextDecoration.underline,
                                fontSize: textFontSize * 0.8,
                              ),
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
          if (showMessage)
            Positioned(
              bottom: screenHeight * 0.02,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: Card(
                elevation: 4,
                color: colorScheme[AppStrings.primaryColor],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  side: BorderSide(
                    color: colorScheme[AppStrings.secondaryColor]!,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppStrings.passwordResetSent,
                            style: TextStyle(
                              color: colorScheme[AppStrings.secondaryColor],
                              fontSize: textFontSize * 0.75,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme[AppStrings.secondaryColor],
                          size: iconSize,
                        ),
                        onPressed: () => setState(() => showMessage = false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}