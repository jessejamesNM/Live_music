// Created on: 2025-04-26
// Author: KingdomOfJames
//
// Description:
// La pantalla `ResetPasswordScreen` permite a los usuarios restablecer su contraseña
// mediante un código de recuperación recibido en un enlace profundo (deep link).
// Esta pantalla está diseñada para trabajar con Firebase Authentication.
// Si el código de recuperación es válido, se permite al usuario introducir una nueva contraseña.
//
// Características:
// - Validación de parámetros: Verifica que el deep link contenga el código de recuperación (oobCode) y el modo (resetPassword).
// - Manejo de errores: Muestra mensajes de error en caso de que haya problemas con el código de recuperación o la contraseña.
// - Interfaz de usuario (UI) clara con un formulario para introducir una nueva contraseña.
// - Redirección automática a la pantalla de inicio después de un restablecimiento exitoso.
//
// Recomendaciones:
// - Asegúrate de que los deep links estén bien configurados para que los parámetros se pasen correctamente.
// - Revisa la validación de entrada para evitar que los usuarios envíen contraseñas vacías.
// - Considera mejorar la accesibilidad y la experiencia de usuario con más retroalimentación visual.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';

class ResetPasswordScreen extends StatefulWidget {
  final GoRouter goRouter;
  final GoRouterState routerState;
  final String? deepLink;

  const ResetPasswordScreen({
    Key? key,
    required this.goRouter,
    required this.routerState,
    this.deepLink,
  }) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  String? _oobCode;
  String? _mode;
  String _newPassword = '';
  bool _isResetSuccessful = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _extractParameters(); // Extrae parámetros del deep link o la ruta actual
  }

  // Extrae el código de recuperación (oobCode) y el modo de la URL
  void _extractParameters() {
    final uri = Uri.parse(widget.deepLink ?? widget.routerState.location);

    setState(() {
      _mode = uri.queryParameters['mode'];
      _oobCode = uri.queryParameters['oobCode'];
    });
  }

  // Realiza la solicitud de restablecimiento de contraseña a Firebase
  Future<void> _resetPassword() async {
    if (_newPassword.isEmpty) {
      setState(() {
        _errorMessage =
            AppStrings
                .emptyPasswordError; // Muestra un error si la contraseña está vacía
      });
      return;
    }

    if (_oobCode == null) {
      setState(() {
        _errorMessage =
            AppStrings
                .invalidRecoveryCode; // Muestra un error si no se proporciona un código de recuperación
      });
      return;
    }

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: _oobCode!, // Utiliza el código de recuperación
        newPassword: _newPassword, // Utiliza la nueva contraseña proporcionada
      );

      setState(() {
        _isResetSuccessful = true; // Marca el restablecimiento como exitoso
        _errorMessage = null; // Elimina cualquier mensaje de error
      });

      // Redirige al usuario a la pantalla principal después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        widget.goRouter.go('/homescreen');
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage =
            e.message ??
            AppStrings
                .unknownResetError; // Muestra un mensaje de error si la solicitud falla
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene el esquema de colores

    // Si el modo es 'resetPassword' y el código de recuperación no es nulo, muestra el formulario
    if (_mode == 'resetPassword' && _oobCode != null) {
      return _ResetPasswordForm(
        newPassword: _newPassword,
        onPasswordChanged: (value) => setState(() => _newPassword = value),
        onResetPressed: _resetPassword,
        isResetSuccessful: _isResetSuccessful,
        errorMessage: _errorMessage,
        colorScheme: colorScheme,
      );
    } else {
      // Si el modo no es 'resetPassword' o el código es inválido, muestra un mensaje de error
      return Scaffold(
        backgroundColor: colorScheme[AppStrings.primaryColor],
        body: Center(
          child: Text(
            AppStrings.invalidLink,
            style: TextStyle(
              color: colorScheme[AppStrings.secondaryColor],
              fontSize: 18,
            ),
          ),
        ),
      );
    }
  }
}

class _ResetPasswordForm extends StatelessWidget {
  final String newPassword;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onResetPressed;
  final bool isResetSuccessful;
  final String? errorMessage;
  final Map<String, Color?> colorScheme;

  const _ResetPasswordForm({
    required this.newPassword,
    required this.onPasswordChanged,
    required this.onResetPressed,
    required this.isResetSuccessful,
    required this.colorScheme,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Título de la pantalla
            Text(
              AppStrings.resetPasswordTitle,
              style: TextStyle(
                color: colorScheme[AppStrings.secondaryColor],
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            // Campo de texto para la nueva contraseña
            TextField(
              obscureText: true, // La contraseña es oculta por seguridad
              decoration: InputDecoration(
                labelText: AppStrings.newPassword,
                labelStyle: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor]?.withOpacity(
                    0.7,
                  ),
                ),
                filled: true,
                fillColor: colorScheme[AppStrings.primaryColor],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme[AppStrings.secondaryColor]!,
                    width: 1.5,
                  ),
                ),
              ),
              style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
              onChanged:
                  onPasswordChanged, // Actualiza la contraseña cuando el usuario escribe
            ),
            const SizedBox(height: 24),
            // Botón para restablecer la contraseña
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onResetPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme[AppStrings.essentialColor],
                  foregroundColor: colorScheme[AppStrings.primaryColor],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                ),
                child: Text(
                  AppStrings.resetPasswordButton,
                  style: TextStyle(
                    color: colorScheme[AppStrings.primaryColor],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Mensaje de éxito si el restablecimiento fue exitoso
            if (isResetSuccessful)
              Text(
                AppStrings.passwordResetSuccess,
                style: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor],
                  fontSize: 16,
                ),
              ),
            // Muestra el mensaje de error si existe uno
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
