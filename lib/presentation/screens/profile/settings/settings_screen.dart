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

  SettingsScreen({required this.goRouter, required this.userProvider, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    final userType = userProvider.userType;
    final isArtist = userType == AppStrings.artist;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double iconSize = screenWidth * 0.08;
    double titleFontSize = screenWidth * 0.055;
    double headerPadding = screenWidth * 0.04;
    double buttonFontSize = screenWidth * 0.045;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
        userType: userType,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(headerPadding),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: colorScheme[AppStrings.secondaryColor],
                        size: iconSize * 1.1,
                      ),
                      onPressed: () {
                        goRouter.pop();
                      },
                    ),
                  ),
                  Center(
                    child: Text(
                      AppStrings.settings,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: colorScheme[AppStrings.secondaryColor],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 0),
                child: SettingsComponent(router: goRouter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
