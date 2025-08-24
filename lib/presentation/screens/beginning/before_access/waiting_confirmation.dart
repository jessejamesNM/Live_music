// Fecha de creación: 2025-04-22
// Autor: KingdomOfJames
// Descripción: Pantalla que muestra un mensaje de espera para la verificación del correo electrónico del usuario.
// Recomendaciones: Asegúrese de que el correo electrónico esté correctamente almacenado y recuperado antes de mostrar el mensaje.
// Características:
// - Muestra un mensaje indicando que el usuario debe verificar su correo electrónico.
// - Si el correo no está disponible, se muestra un mensaje de error.
// - Utiliza un CircularProgressIndicator mientras se recupera el correo.
// - Se puede navegar hacia atrás o a la pantalla de selección en caso de error.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/repositories/providers_repositories/user_repository.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../../data/provider_logics/beginning/beginning_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaitingConfirmScreen extends StatefulWidget {
  final GoRouter goRouter;

  const WaitingConfirmScreen({Key? key, required this.goRouter})
      : super(key: key);

  @override
  _WaitingConfirmScreenState createState() => _WaitingConfirmScreenState();
}

class _WaitingConfirmScreenState extends State<WaitingConfirmScreen> {
  String? email;
  String? errorMessage;
  bool _canResend = false;
  int _secondsRemaining = 60;
  Timer? _timer;
  late UserRepository _userRepo;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _userRepo = Provider.of<UserRepository>(context, listen: false);
    _fetchEmailAndUser();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchEmailAndUser() async {
    final provider = Provider.of<BeginningProvider>(context, listen: false);
    final result = await provider.getEmail();
    final user = await _userRepo.getCurrentUser();

    setState(() {
      _currentUser = user;
      if (result != null && result.contains(AppStrings.error)) {
        errorMessage = result;
      } else {
        email = result;
        _startResendCountdown();
      }
    });
  }

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _onResendPressed() async {
    if (_currentUser == null) return;
    try {
      await _userRepo.resendVerificationEmail(_currentUser!);
      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo reenviado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reenviar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ColorPalette.getPalette(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Medidas adaptativas
    final horizontalPadding = screenWidth * 0.06;
    final verticalPadding = screenHeight * 0.02;
    final iconSize = screenWidth * 0.2; // ícono principal
    final titleFontSize = screenWidth * 0.065;
    final messageFontSize = screenWidth * 0.045;
    final buttonFontSize = screenWidth * 0.045;
    final buttonPaddingH = screenWidth * 0.08;
    final buttonPaddingV = screenHeight * 0.015;
    final iconButtonSize = screenWidth * 0.08;
    final spacing = screenHeight * 0.02;

    return Scaffold(
      backgroundColor: colors[AppStrings.primaryColor],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón de volver
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: colors[AppStrings.secondaryColor],
                      size: iconButtonSize,
                    ),
                    onPressed: () {
                      try {
                        context.pop();
                      } catch (_) {
                        widget.goRouter.go(AppStrings.selectionScreenRoute);
                      }
                    },
                  ),
                ),
                SizedBox(height: spacing),

                // Ícono principal
                Icon(
                  Icons.mark_email_read_outlined,
                  size: iconSize,
                  color: colors[AppStrings.secondaryColor],
                ),
                SizedBox(height: spacing),

                // Título adaptativo
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppStrings.verifyYourEmail,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: colors[AppStrings.secondaryColor],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: spacing * 0.5),

                // Mensaje de email o error
                if (email != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${AppStrings.verifyEmailInstructions} $email\n\n${AppStrings.checkSpamFolder}',
                      style: TextStyle(
                        color: colors[AppStrings.grayColor],
                        fontSize: messageFontSize,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (errorMessage != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  CircularProgressIndicator(
                    color: colors[AppStrings.essentialColor],
                  ),
                SizedBox(height: spacing * 2),

                // Botón de reenviar
                if (email != null)
                  ElevatedButton.icon(
                    onPressed: _canResend ? _onResendPressed : null,
                    icon: Icon(Icons.refresh, size: buttonFontSize),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _canResend
                            ? 'Reenviar correo'
                            : 'Reenviar en $_secondsRemaining s',
                        style: TextStyle(fontSize: buttonFontSize),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors[AppStrings.essentialColor],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: buttonPaddingH,
                        vertical: buttonPaddingV,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}