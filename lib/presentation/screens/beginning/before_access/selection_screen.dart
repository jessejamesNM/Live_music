// Autor: kingdomOfJames
// Fecha de creación: 2025-04-22
// File: selection_screen.dart
// Descripción: Pantalla de selección de tipo de cuenta.
// Esta es la primera pantalla que se muestra al abrir la aplicación. Permite al usuario elegir
// entre dos tipos de cuentas: "Músico" (Artista) o "Contratante" (Persona que quiere contratar músicos).
// También ofrece la opción de iniciar sesión si ya se tiene una cuenta existente.
// Esta pantalla está diseñada con un enfoque visual claro y botones grandes, accesibles,
// utilizando una paleta de colores dinámica definida por ColorPalette, y fuentes personalizadas.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/beggining/option_card.dart';
import '../../../resources/colors.dart';

class SelectionScreen extends StatelessWidget {
  final VoidCallback onArtistClick;
  final VoidCallback onContractorClick;
  final VoidCallback onLoginClick;

  const SelectionScreen({
    Key? key,
    this.onArtistClick = _defaultCallback,
    this.onContractorClick = _defaultCallback,
    this.onLoginClick = _defaultCallback,
  }) : super(key: key);

  static void _defaultCallback() {}

  @override
  Widget build(BuildContext context) {
    final fontMainFamily = AppStrings.bevietnamProRegular;
    final colorScheme = ColorPalette.getPalette(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Ancho adaptativo para las tarjetas (mitad de pantalla - márgenes)
    final cardWidth = (screenWidth - 60) / 2;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Spacer(flex: 65),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontFamily: fontMainFamily,
                      color: colorScheme[AppStrings.secondaryColor],
                      fontSize: screenWidth * 0.09, // Escala con ancho pantalla
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      height: cardWidth,
                      child: OptionCard(
                        text: "Ofrezco servicios",
                        imageRes: "assets/svg/businessman.svg",
                        onClick: onArtistClick,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      height: cardWidth,
                      child: OptionCard(
                        text: AppStrings.iWantToHire,
                        imageRes: AppStrings.icContractorAsset,
                        onClick: onContractorClick,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(flex: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: onLoginClick,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppStrings.logIn,
                      style: TextStyle(
                        fontFamily: fontMainFamily,
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: screenWidth * 0.045, // Adaptativo
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
