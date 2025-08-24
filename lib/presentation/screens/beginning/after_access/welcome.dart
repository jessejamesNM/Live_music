/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla de bienvenida que introduce a los usuarios a la aplicación "Live Music".
/// Muestra una breve secuencia de mensajes con transiciones visuales para generar
/// una experiencia más fluida y agradable antes de acceder a la pantalla principal.
/// Una vez completada la secuencia, se ofrece un botón para continuar a la HomeScreen.
///
/// Recomendaciones:
/// - Considerar agregar una animación o branding visual durante el mensaje de bienvenida
///   para reforzar la identidad de la app.
/// - Añadir soporte para accesibilidad (por ejemplo, lectores de pantalla) si es necesario.
/// - Se podría mostrar una animación más envolvente si se desea un impacto visual más fuerte.
///
/// Características:
/// - Muestra un mensaje inicial ("¡Todo listo!") durante 2 segundos.
/// - Cambia automáticamente a un mensaje de bienvenida con botón de continuación.
/// - Usa `AnimatedSwitcher` para transiciones suaves entre mensajes.
/// - Permite navegación hacia la pantalla principal mediante `GoRouter`.
/// - Interfaz limpia, centrada y adaptada a los colores definidos por `ColorPalette`.
///
/// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class WelcomeScreen extends StatefulWidget {
  final GoRouter goRouter;

  const WelcomeScreen({Key? key, required this.goRouter}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _showLoading = false;
  bool _showReadyMessage = true;
  bool _showWelcomeMessage = false;

  @override
  void initState() {
    super.initState();
    _startMessageSequence();
  }

  void _startMessageSequence() {
    setState(() {
      _showReadyMessage = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showReadyMessage = false;
        _showWelcomeMessage = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    // Tamaños adaptativos
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final paddingHorizontal = screenWidth * 0.08;
    final spacingVertical = screenHeight * 0.03;
    final textFontSize = screenWidth * 0.06; // adaptativo
    final buttonHeight = screenHeight * 0.065;
    final borderRadius = screenWidth * 0.03;
    final loadingSize = screenWidth * 0.15;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _showLoading
              ? SizedBox(
                  width: loadingSize,
                  height: loadingSize,
                  child: CircularProgressIndicator(
                    color: colorScheme[AppStrings.essentialColor],
                    strokeWidth: 4.0,
                  ),
                )
              : _showReadyMessage
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.allReady,
                        style: TextStyle(
                          fontSize: textFontSize,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                    )
                  : _showWelcomeMessage
                      ? Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: paddingHorizontal),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${AppStrings.welcomeTo} ${AppStrings.appName}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: textFontSize,
                                    color: colorScheme[AppStrings.secondaryColor],
                                  ),
                                ),
                              ),
                              SizedBox(height: spacingVertical),
                              SizedBox(
                                width: double.infinity,
                                height: buttonHeight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    widget.goRouter
                                        .go(AppStrings.homeScreenRoute);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        colorScheme[AppStrings.essentialColor],
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(borderRadius),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      AppStrings.continueText,
                                      style: TextStyle(
                                        fontSize: textFontSize * 0.9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
        ),
      ),
    );
  }
}