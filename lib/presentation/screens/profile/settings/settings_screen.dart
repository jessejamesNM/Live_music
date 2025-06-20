// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción:
// Esta pantalla de configuración permite a los usuarios acceder a diversas opciones de configuración de su cuenta. Se muestra un encabezado con un botón para regresar, y un área principal donde se cargan los componentes de configuración.
// Recomendaciones:
// - Asegúrate de que el componente `SettingsComponent` esté correctamente implementado y que se adapte a la experiencia de usuario esperada.
// - Personaliza los elementos dentro de la pantalla de acuerdo a los requerimientos específicos del sistema de configuración.
// Características:
// - Barra de navegación en la parte inferior que varía dependiendo del tipo de usuario (artista o no artista).
// - Uso de `GoRouter` para la navegación entre pantallas.
// - Escucha del `UserProvider` para obtener el tipo de usuario y adaptar la interfaz según eso.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../../buttom_navigation_bar.dart';
import 'components/settings.dart';

class SettingsScreen extends StatelessWidget {
  final GoRouter goRouter;
  final UserProvider userProvider;

  // Constructor que recibe el router y el proveedor de usuario.
  SettingsScreen({required this.goRouter, required this.userProvider});

  @override
  Widget build(BuildContext context) {
    // Obtiene el esquema de colores para la pantalla.
    final colorScheme = ColorPalette.getPalette(context);

    // Verifica el tipo de usuario para determinar si es un artista.
    final userType = userProvider.userType;
    final isArtist = userType == AppStrings.artist;

    // Construye la interfaz de la pantalla de configuración.
    return Scaffold(
      // Configura el color de fondo de la pantalla.
      backgroundColor: colorScheme[AppStrings.primaryColor],
      // Barra de navegación inferior que varía según el tipo de usuario.
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
        isArtist: isArtist,
      ),
      // Contenido principal de la pantalla.
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Encabezado con el título y el botón de regresar.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Positioned(
                    // Botón de regresar que utiliza el router para navegar a la pantalla anterior.
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: colorScheme[AppStrings.secondaryColor],
                        size: 30,
                      ),
                      onPressed: () {
                        goRouter.pop();
                      },
                    ),
                  ),
                  Center(
                    // Título de la pantalla de configuración.
                    child: Text(
                      AppStrings.settings,
                      style: TextStyle(
                        fontSize: 20,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sección de contenido, que es el componente de configuración.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: SettingsComponent(router: goRouter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
