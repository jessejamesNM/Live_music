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

class ForgotPasswordScreen extends StatefulWidget {
  final GoRouter goRouter;

  const ForgotPasswordScreen({Key? key, required this.goRouter})
      : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailValid = true;
  bool _isButtonEnabled = true;
  int _countdown = 0;
  bool _showErrorMessage = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    return emailPattern.hasMatch(email);
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.recoveryEmailSent)),
        );
      }
    } catch (e) {
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

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() => _countdown--);
        _startCountdown();
      } else if (mounted) {
        setState(() => _isButtonEnabled = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    // Tamaños adaptativos
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final paddingAll = screenWidth * 0.08;
    final spacing = screenHeight * 0.02;
    final iconSize = screenWidth * 0.07;
    final titleFontSize = screenWidth * 0.06;
    final textFontSize = screenWidth * 0.045;
    final buttonHeight = screenHeight * 0.065;
    final borderRadius = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
      body: Stack(
        children: [
          // Botón de retroceso
          Positioned(
            top: spacing,
            left: paddingAll * 0.2,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: colorScheme[AppStrings.secondaryColor] ?? Colors.white,
                size: iconSize,
              ),
              onPressed: () => widget.goRouter.pop(),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingAll),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Título
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.recoverAccount,
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor] ??
                              Colors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing),
                    // Instrucciones
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.enterYourEmail,
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor] ??
                              Colors.white,
                          fontSize: textFontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: spacing * 0.5),
                    // Campo de email
                    TextField(
                      controller: _emailController,
                      onChanged: (value) {
                        setState(() {
                          _isEmailValid = _validateEmail(value);
                          _showErrorMessage = false;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: AppStrings.enterEmail,
                        labelStyle: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor] ??
                              Colors.white,
                          fontSize: textFontSize,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor] ??
                            Colors.white,
                        fontSize: textFontSize,
                      ),
                    ),
                    // Mensaje de email inválido
                    if (!_isEmailValid && _emailController.text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: spacing * 0.3),
                        child: Text(
                          AppStrings.invalidEmailError,
                          style: TextStyle(
                            color: colorScheme[AppStrings.redColor] ?? Colors.red,
                            fontSize: textFontSize * 0.9,
                          ),
                        ),
                      ),
                    SizedBox(height: spacing),
                    // Botón enviar correo
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_emailController.text.isEmpty || !_isEmailValid) {
                            setState(() => _showErrorMessage = true);
                          } else if (_isButtonEnabled) {
                            _sendPasswordResetEmail(_emailController.text);
                            setState(() {
                              _isButtonEnabled = false;
                              _countdown = 60;
                            });
                            _startCountdown();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isButtonEnabled
                              ? colorScheme[AppStrings.redColor] ?? Colors.red
                              : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppStrings.continueText,
                            style: TextStyle(
                              color: colorScheme[AppStrings.secondaryColor] ??
                                  Colors.white,
                              fontSize: textFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Temporizador
                    if (!_isButtonEnabled)
                      Padding(
                        padding: EdgeInsets.only(top: spacing * 0.3),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${AppStrings.wait} $_countdown ${AppStrings.secondsToTryAgain}',
                            style: TextStyle(
                              color: colorScheme[AppStrings.secondaryColor]
                                      ?.withOpacity(0.7) ??
                                  Colors.grey,
                              fontSize: textFontSize * 0.9,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    // Mensaje de error
                    if (_showErrorMessage)
                      Padding(
                        padding: EdgeInsets.only(top: spacing * 0.3),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppStrings.enterValidEmail,
                            style: TextStyle(
                              color: colorScheme[AppStrings.redColor] ??
                                  Colors.red,
                              fontSize: textFontSize * 0.9,
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
    );
  }
}