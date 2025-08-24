// Autor: kingdomOfJames
// Fecha: 2025-04-22
//
// Descripción:
// Pantalla de opciones de inicio de sesión de la aplicación. Esta es una de las primeras
// pantallas que se muestra al usuario luego de elegir el tipo de cuenta (artista o contratante).
// Su objetivo es ofrecer distintos métodos de autenticación para acceder a la plataforma.
//
// Actualmente soporta dos métodos de inicio de sesión:
// 1. Correo electrónico y contraseña (navega a una pantalla aparte para introducir credenciales)
// 2. Inicio de sesión con Google usando Firebase Auth
//
// En el futuro está diseñada para escalar y soportar hasta:
// - 3 métodos en Android: Email, Google y Facebook
// - 4 métodos en Apple: Email, Google, Facebook e inicio de sesión con Apple (Apple Sign-In)
//
// Características destacadas:
// - Usa `GoRouter` para navegación
// - Muestra errores si el usuario no está registrado
// - Usa colores temáticos obtenidos dinámicamente de la paleta `ColorPalette`
// - Usa assets SVG para los íconos de Google y el botón de email
// - Control de carga (`isLoading`) para evitar múltiples intentos de inicio de sesión simultáneos
//
// Consideraciones:
// - `errorMessage` se muestra si hay errores con el login
// - Si el usuario existe en Firebase pero no tiene el campo `isRegistered` o está en false,
//   se fuerza un cierre de sesión y se muestra el mensaje correspondiente
// - Si en el futuro se agregan más métodos de login, se recomienda encapsular los botones en
//   un widget reutilizable para mantener la consistencia visual y lógica

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:live_music/data/provider_logics/beginning/beginning_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../../../../../resources/colors.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LoginOptionsScreen extends StatefulWidget {
  final GoRouter goRouter;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final BeginningProvider beginningProvider;

  const LoginOptionsScreen({
    Key? key,
    required this.goRouter,
    required this.auth,
    required this.firestore,
    required this.beginningProvider,
  }) : super(key: key);

  @override
  _LoginOptionsScreenState createState() => _LoginOptionsScreenState();
}

class _LoginOptionsScreenState extends State<LoginOptionsScreen> {
  bool isLoading = false;
  String errorMessage = "";
  bool isRegistered = false;

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

      UserCredential userCredential = await widget.auth.signInWithCredential(
        credential,
      );
      User? currentUser = userCredential.user;

      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await widget.firestore
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
            await widget.auth.signOut();
          } else {
            final initialRoute = await _determineInitialRoute();
            widget.goRouter.go(initialRoute);
          }
        } else {
          setState(() {
            errorMessage = AppStrings.unregisteredUser;
          });
          await widget.auth.signOut();
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

  Future<void> _signInWithApple() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      // Crear el proveedor de Apple
      final appleProvider = AppleAuthProvider();
      
      // Iniciar sesión con Apple
      final UserCredential userCredential = 
          await widget.auth.signInWithProvider(appleProvider);
      
      User? currentUser = userCredential.user;

      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await widget.firestore
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
            await widget.auth.signOut();
          } else {
            final initialRoute = await _determineInitialRoute();
            widget.goRouter.go(initialRoute);
          }
        } else {
          setState(() {
            errorMessage = AppStrings.unregisteredUser;
          });
          await widget.auth.signOut();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Tamaños adaptativos basados en porcentaje de pantalla
    final double paddingAll = screenWidth * 0.04;
    final double iconPaddingTop = screenHeight * 0.02;
    final double textFieldSpacing = screenHeight * 0.015;
    final double buttonHeight = screenHeight * 0.065;
    final double buttonBorderWidth = 1.0;
    final double buttonIconSize = screenHeight * 0.028;
    final double buttonPaddingHorizontal = screenWidth * 0.03;
    final double titleFontSize = screenHeight * 0.035;
    final double svgIconSize = screenHeight * 0.026;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.all(paddingAll),
                  child: Stack(
                    children: [
                      Positioned(
                        top: iconPaddingTop,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                            size: screenHeight * 0.03,
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
                          SizedBox(height: screenHeight * 0.08),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: paddingAll),
                            child: Text(
                              AppStrings.logIn,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                              ),
                            ),
                          ),

                          if (errorMessage.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: textFieldSpacing),
                              child: Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme[AppStrings.redColor] ?? Colors.red,
                                  fontSize: screenHeight * 0.018,
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
                                backgroundColor: colorScheme[AppStrings.essentialColor] ?? Colors.white,
                                side: BorderSide(
                                  color: colorScheme[AppStrings.essentialColor] ?? Colors.black,
                                  width: buttonBorderWidth,
                                ),
                                minimumSize: Size(double.infinity, buttonHeight),
                              ),
                              onPressed: () => widget.goRouter.push(
                                AppStrings.loginMailScreenRoute,
                                extra: {
                                  'auth': widget.auth,
                                  'firestore': widget.firestore,
                                  'beginningProvider': widget.beginningProvider,
                                },
                              ),
                              child: SizedBox(
                                height: buttonHeight,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Positioned(
                                      left: 0,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: buttonHeight * 0.3),
                                        child: Icon(
                                          Icons.mail,
                                          color: Colors.white,
                                          size: buttonIconSize,
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        AppStrings.continueWithMail,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: buttonHeight * 0.30,
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
                                backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
                                side: BorderSide(
                                  color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                                  width: buttonBorderWidth,
                                ),
                                minimumSize: Size(double.infinity, buttonHeight),
                              ),
                              onPressed: _signInWithGoogle,
                              child: SizedBox(
                                height: buttonHeight,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Positioned(
                                      left: 0,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: buttonHeight * 0.3),
                                        child: SvgPicture.asset(
                                          AppStrings.googleIconPath,
                                          width: svgIconSize,
                                          height: svgIconSize,
                                          color: colorScheme[AppStrings.secondaryColor],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        AppStrings.continueWithGoogle,
                                        style: TextStyle(
                                          color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                                          fontSize: buttonHeight * 0.30,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: textFieldSpacing),
// Apple button (solo para iOS)
if (Theme.of(context).platform == TargetPlatform.iOS)
  Padding(
    padding: EdgeInsets.symmetric(
      horizontal: buttonPaddingHorizontal,
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black, // Color negro para el botón de Apple
        side: BorderSide(
          color: Colors.white, // Borde blanco
          width: buttonBorderWidth,
        ),
        minimumSize: Size(double.infinity, buttonHeight),
      ),
      onPressed: _signInWithApple,
      child: SizedBox(
        height: buttonHeight,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 0,
              child: Padding(
                padding: EdgeInsets.only(left: buttonHeight * 0.3),
                child: Icon(
                  Icons.apple,
                  color: Colors.white,
                  size: buttonIconSize,
                ),
              ),
            ),
            Center(
              child: Text(
                AppStrings.continueWithApple,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: buttonHeight * 0.30,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),

SizedBox(height: screenHeight * 0.05),
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
              ),
            ),
          );
        },
      ),
    );
  }
}