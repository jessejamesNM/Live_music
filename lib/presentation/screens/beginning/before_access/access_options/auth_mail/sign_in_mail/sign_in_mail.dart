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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_music/data/model/global_variables.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/colors.dart';

// Pantalla de login con email y contraseña
class LoginMailScreen extends StatefulWidget {
  final FirebaseAuth auth; // Instancia de FirebaseAuth para autenticar
  final GoRouter goRouter; // Instancia del enrutador para navegación

  const LoginMailScreen({Key? key, required this.auth, required this.goRouter})
    : super(key: key);

  @override
  _LoginMailScreenState createState() => _LoginMailScreenState();
}

class _LoginMailScreenState extends State<LoginMailScreen> {
  // Variables para guardar email, contraseña, error y visibilidad de mensaje
  String email = "";
  String password = "";
  String? errorMessage;
  bool showMessage = false;

  // Valida si el email tiene un formato correcto
  bool isEmailValid(String email) {
    return emailPattern.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Paleta de colores personalizada

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor], // Fondo
      body: Stack(
        children: [
          Column(
            children: [
              // Botón de regreso
              Align(
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Título: "Iniciar sesión"
                      Text(
                        AppStrings.logIn,
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Campo de texto para el email
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

                      // Campo de texto para la contraseña
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
                        ),
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                        obscureText: true, // Oculta la contraseña
                        onChanged: (value) => setState(() => password = value),
                      ),
                      const SizedBox(height: 8),

                      // Muestra mensaje de error si existe
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Botón de iniciar sesión
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Validación de campos
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
                              // Intenta iniciar sesión con Firebase
                              try {
                                await widget.auth.signInWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );
                                setState(() => errorMessage = null);
                                widget.goRouter.go(AppStrings.homeScreenRoute);
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
                              color: colorScheme[AppStrings.primaryColor],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Enlace para recuperar contraseña
                      GestureDetector(
                        onTap:
                            () => widget.goRouter.go(
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

          // Mensaje de éxito (por ejemplo, al enviar link de recuperación de contraseña)
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
                      // Texto del mensaje
                      Expanded(
                        child: Text(
                          AppStrings.passwordResetSent,
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                      ),
                      // Botón para cerrar el mensaje
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
