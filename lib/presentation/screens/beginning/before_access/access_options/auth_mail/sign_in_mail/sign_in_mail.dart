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
          userType == 'artist' ||
          userType == 'bakery' ||
          userType == 'place' ||
          userType == 'decoration';

      if (!isVerified) {
        return AppStrings.waitingConfirmScreenRoute;
      }

      widget.beginningProvider.setRouteToGo(AppStrings.welcomeScreenRoute);

      if (!isArtistType) {
        if (age == null || acceptedTerms != true || acceptedPrivacy != true) {
          return AppStrings.ageTermsScreenRoute;
        }
        if (name.isEmpty) {
          return AppStrings.usernameScreen;
        }
        if (nickname.isEmpty) {
          return AppStrings.nicknameScreenRoute;
        }
      } else {
        widget.beginningProvider.setRouteToGo(
          AppStrings.profileImageScreenRoute,
        );

        if (age == null || acceptedTerms != true || acceptedPrivacy != true) {
          return AppStrings.ageTermsScreenRoute;
        }
        if (isVerified && name.isEmpty) {
          return AppStrings.verifyEmailRoute;
        }
        if (name.isEmpty) {
          return AppStrings.groupNameScreenRoute;
        }
        if (nickname.isEmpty) {
          return AppStrings.nicknameScreenRoute;
        }
        if (profileImageUrl.isEmpty) {
          return AppStrings.profileImageScreenRoute;
        }
        if (userType == 'artist' && genres.isEmpty) {
          return AppStrings.musicGenresScreenRoute;
        }
        if (specialty.isEmpty) {
          return AppStrings.eventSpecializationScreenRoute;
        }
        if (countries.isEmpty || states.isEmpty) {
          return AppStrings.userCanWorkCountryStateScreenRoute;
        }
        if (country.isEmpty || state.isEmpty) {
          return AppStrings.countryStateScreenRoute;
        }

        final serviceDoc =
            await widget.firestore
                .collection('services')
                .doc(currentUserId)
                .get();

        if (!serviceDoc.exists) {
          return AppStrings.priceScreenRoute;
        }

        final serviceCollectionRef = widget.firestore
            .collection('services')
            .doc(currentUserId)
            .collection('service');

        for (int i = 0; i < 8; i++) {
          final docId = 'service$i';
          final doc = await serviceCollectionRef.doc(docId).get();

          if (!doc.exists) {
            continue;
          }

          final data = doc.data() ?? {};
          final price = data['price'];
          final info = data['information'];
          final images = data['imageList'] as List<dynamic>?;

          final isPriceValid = price != null && (price is num) && price > 0;
          final isInfoValid = info != null && info.toString().trim().isNotEmpty;
          final hasImages = images != null && images.isNotEmpty;

          if (!isPriceValid || !isInfoValid || !hasImages) {
            return AppStrings.priceScreenRoute;
          }
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
    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 23.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                    onPressed:
                        () => widget.goRouter.go(
                          AppStrings.loginOptionsScreenRoute,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.logIn,
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        decoration: InputDecoration(
                          hintText: AppStrings.email,
                          filled: true,
                          fillColor: colorScheme[AppStrings.primaryColor],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme[AppStrings.secondaryColor]!,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme[AppStrings.secondaryColor]!,
                              width: 1.5,
                            ),
                          ),
                          hintStyle: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor]
                                ?.withOpacity(0.7),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                        onChanged: (value) => setState(() => email = value),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: AppStrings.password,
                          filled: true,
                          fillColor: colorScheme[AppStrings.primaryColor],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme[AppStrings.secondaryColor]!,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme[AppStrings.secondaryColor]!,
                              width: 1.5,
                            ),
                          ),
                          hintStyle: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor]
                                ?.withOpacity(0.7),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                        obscureText: _obscurePassword,
                        onChanged: (value) => setState(() => password = value),
                      ),
                      const SizedBox(height: 8),
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (email.isEmpty || password.isEmpty) {
                              setState(
                                () =>
                                    errorMessage = AppStrings.emptyFieldsError,
                              );
                            } else if (!isEmailValid(email)) {
                              setState(
                                () =>
                                    errorMessage = AppStrings.invalidEmailError,
                              );
                            } else {
                              try {
                                await widget.auth.signInWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );
                                setState(() => errorMessage = null);

                                final initialRoute =
                                    await _determineInitialRoute();
                                widget.goRouter.go(initialRoute);
                              } on FirebaseAuthException {
                                setState(
                                  () =>
                                      errorMessage =
                                          AppStrings.incorrectCredentials,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                colorScheme[AppStrings.essentialColor],
                            foregroundColor:
                                colorScheme[AppStrings.primaryColor],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 4,
                          ),
                          child: Text(
                            AppStrings.logIn,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap:
                            () => widget.goRouter.push(
                              AppStrings.forgotPasswordScreenRoute,
                            ),
                        child: Text(
                          AppStrings.forgotPassword,
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (showMessage)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                color: colorScheme[AppStrings.primaryColor],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme[AppStrings.secondaryColor]!,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.passwordResetSent,
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme[AppStrings.secondaryColor],
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
