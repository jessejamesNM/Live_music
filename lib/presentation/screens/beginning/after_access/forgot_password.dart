/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla que permite a los usuarios recuperar su cuenta mediante el envío
/// de un correo electrónico para restablecer la contraseña. La pantalla incluye
/// validación de correo electrónico en tiempo real y un temporizador para evitar
/// intentos repetidos en corto tiempo. Si el correo es válido, se envía una solicitud
/// para el restablecimiento de la contraseña a través de FirebaseAuth.
///
/// Recomendaciones:
/// - Implementar validaciones adicionales para manejar errores específicos de la API de Firebase.
/// - Mejorar la interfaz con un indicador de carga al enviar el correo.
/// - Considerar agregar un mensaje de éxito más claro o redirigir a una pantalla de confirmación.
///
/// Características:
/// - Validación de formato de correo electrónico mediante una expresión regular.
/// - Temporizador de cuenta regresiva que bloquea el botón "Continuar" durante 60 segundos.
/// - Retroalimentación visual cuando el correo es inválido o cuando el usuario debe esperar.
/// - Diseño adaptado a la paleta de colores definida en `ColorPalette`.
/// - Utilización de `FirebaseAuth` para enviar el correo de restablecimiento de contraseña.
/// -----------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_music/data/model/global_variables.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';

// Pantalla de recuperación de contraseña
class ForgotPasswordScreen extends StatefulWidget {
  final GoRouter goRouter;

  const ForgotPasswordScreen({Key? key, required this.goRouter})
    : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

// Estado de la pantalla ForgotPasswordScreen
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controlador para el campo de texto del email
  final TextEditingController _emailController = TextEditingController();
  // Indicador de si el email es válido o no
  bool _isEmailValid = true;
  // Controla si el botón está habilitado o no
  bool _isButtonEnabled = true;
  // Temporizador para contar atrás (en segundos)
  int _countdown = 0;
  // Indicador para mostrar el mensaje de error
  bool _showErrorMessage = false;

  @override
  void dispose() {
    _emailController
        .dispose(); // Liberar recursos cuando la pantalla se destruya
    super.dispose();
  }

  // Función que valida si el email coincide con el patrón
  bool _validateEmail(String email) {
    return emailPattern.hasMatch(email);
  }

  // Función que envía el correo de restablecimiento de contraseña a Firebase
  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      // Intentar enviar el correo de restablecimiento
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        // Si se envía correctamente, mostrar un mensaje en pantalla
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.recoveryEmailSent)));
      }
    } catch (e) {
      // Si ocurre un error, mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.errorSendingEmail}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Función para iniciar el conteo regresivo
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(
          () => _countdown--,
        ); // Decrementar el contador y actualizar la UI
        _startCountdown(); // Llamar de nuevo para continuar el conteo
      } else if (mounted) {
        setState(
          () => _isButtonEnabled = true,
        ); // Habilitar el botón después de que el contador llegue a 0
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtener la paleta de colores del contexto
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
      body: Stack(
        children: [
          // Botón de retroceso
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: colorScheme[AppStrings.secondaryColor] ?? Colors.white,
                size: 24,
              ),
              onPressed:
                  () => widget.goRouter.pop(), // Volver a la pantalla anterior
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Título de la pantalla de recuperación
                Text(
                  AppStrings.recoverAccount,
                  style: TextStyle(
                    color:
                        colorScheme[AppStrings.secondaryColor] ?? Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Instrucciones para ingresar el correo electrónico
                Text(
                  AppStrings.enterYourEmail,
                  style: TextStyle(
                    color:
                        colorScheme[AppStrings.secondaryColor] ?? Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                // Campo de texto para ingresar el email
                TextField(
                  controller: _emailController,
                  onChanged: (value) {
                    setState(() {
                      _isEmailValid = _validateEmail(
                        value,
                      ); // Verificar si el email es válido al cambiarlo
                      _showErrorMessage =
                          false; // Ocultar el mensaje de error al modificar el campo
                    });
                  },
                  decoration: InputDecoration(
                    labelText: AppStrings.enterEmail,
                    labelStyle: TextStyle(
                      color:
                          colorScheme[AppStrings.secondaryColor] ??
                          Colors.white,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            colorScheme[AppStrings.secondaryColor] ??
                            Colors.white,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            colorScheme[AppStrings.secondaryColor] ??
                            Colors.white,
                        width: 1.5,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: TextStyle(
                    color:
                        colorScheme[AppStrings.secondaryColor] ?? Colors.white,
                  ),
                ),
                // Mostrar mensaje de error si el email no es válido
                if (!_isEmailValid && _emailController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      AppStrings.invalidEmailError,
                      style: TextStyle(
                        color: colorScheme[AppStrings.redColor] ?? Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Botón para enviar el correo de restablecimiento
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      // Si el email está vacío o no es válido, mostrar error
                      if (_emailController.text.isEmpty || !_isEmailValid) {
                        setState(() => _showErrorMessage = true);
                      } else if (_isButtonEnabled) {
                        // Enviar el correo de restablecimiento si todo está correcto
                        _sendPasswordResetEmail(_emailController.text);
                        setState(() {
                          _isButtonEnabled = false; // Deshabilitar el botón
                          _countdown = 60; // Iniciar el contador de 60 segundos
                        });
                        _startCountdown(); // Comenzar el conteo regresivo
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isButtonEnabled
                              ? colorScheme[AppStrings.redColor] ?? Colors.red
                              : Colors
                                  .grey, // Cambiar color si el botón está habilitado o no
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      AppStrings.continueText,
                      style: TextStyle(
                        color:
                            colorScheme[AppStrings.secondaryColor] ??
                            Colors.white,
                      ),
                    ),
                  ),
                ),
                // Mostrar el temporizador si el botón está deshabilitado
                if (!_isButtonEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${AppStrings.wait} $_countdown ${AppStrings.secondsToTryAgain}',
                      style: TextStyle(
                        color:
                            colorScheme[AppStrings.secondaryColor]?.withOpacity(
                              0.7,
                            ) ??
                            Colors.grey,
                      ),
                    ),
                  ),
                // Mostrar mensaje de error si el email no es válido y hay un intento
                if (_showErrorMessage)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      AppStrings.enterValidEmail,
                      style: TextStyle(
                        color: colorScheme[AppStrings.redColor] ?? Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
