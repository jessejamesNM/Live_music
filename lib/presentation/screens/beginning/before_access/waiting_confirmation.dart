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
        // activamos el reenvío inmediatamente después de mostrar la pantalla
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al reenviar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colors[AppStrings.primaryColor],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: colors[AppStrings.secondaryColor],
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
                const Spacer(),
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: colors[AppStrings.secondaryColor],
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.verifyYourEmail,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors[AppStrings.secondaryColor],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (email != null)
                  Text(
                    '${AppStrings.verifyEmailInstructions} $email\n\n${AppStrings.checkSpamFolder}',
                    style: TextStyle(
                      color: colors[AppStrings.grayColor],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  )
                else if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  )
                else
                  CircularProgressIndicator(
                    color: colors[AppStrings.essentialColor],
                  ),
                const SizedBox(height: 32),
                if (email != null)
                  ElevatedButton.icon(
                    onPressed: _canResend ? _onResendPressed : null,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _canResend
                          ? 'Reenviar correo'
                          : 'Reenviar en $_secondsRemaining s',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors[AppStrings.essentialColor],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
