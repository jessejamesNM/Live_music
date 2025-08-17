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

// Pantalla de bienvenida que muestra un pequeño flujo de mensajes antes de redirigir al usuario
class WelcomeScreen extends StatefulWidget {
  // Se le pasa un GoRouter desde fuera para manejar navegación
  final GoRouter goRouter;

  const WelcomeScreen({Key? key, required this.goRouter}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Estados para controlar qué mensaje o elemento se muestra
  bool _showLoading = false;
  bool _showReadyMessage = true;
  bool _showWelcomeMessage = false;

  @override
  void initState() {
    super.initState();
    // Inicia la secuencia de mensajes al entrar en la pantalla
    _startMessageSequence();
  }

  // Controla la lógica de mostrar primero "Todo listo", luego "Bienvenido"
  void _startMessageSequence() {
    setState(() {
      _showReadyMessage = true;
    });

    // Después de 2 segundos cambia al mensaje de bienvenida
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showReadyMessage = false;
        _showWelcomeMessage = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtiene la paleta de colores personalizada
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Center(
        // Animación suave entre los distintos widgets (texto o botón)
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child:
              _showLoading
                  // Muestra un loading circular si está en modo cargando
                  ? CircularProgressIndicator(
                    color: colorScheme[AppStrings.essentialColor],
                    strokeWidth: 4.0,
                  )
                  // Si no está cargando y está en la primera etapa, muestra el mensaje "Todo listo"
                  : _showReadyMessage
                  ? Text(
                    AppStrings.allReady,
                    style: TextStyle(
                      fontSize: 24,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  )
                  // Si ya terminó la primera etapa, muestra el mensaje de bienvenida y el botón
                  : _showWelcomeMessage
                  ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mensaje de bienvenida con nombre de la app
                        Text(
                          '${AppStrings.welcomeTo} ${AppStrings.appName}',
                          style: TextStyle(
                            fontSize: 24,
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botón para continuar a la pantalla principal
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // Usa el router pasado por props para navegar al home
                              widget.goRouter.go(AppStrings.homeScreenRoute);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  colorScheme[AppStrings.essentialColor],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              AppStrings.continueText,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  // Si aún no se ha activado ningún estado, no muestra nada
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
