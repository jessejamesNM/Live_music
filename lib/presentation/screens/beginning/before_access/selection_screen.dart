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
  // Definición de tres variables de callback (funciones) que se pasarán a los widgets.
  // Estos callbacks se usan cuando el usuario hace clic en alguna de las opciones.
  final VoidCallback onArtistClick;
  final VoidCallback onContractorClick;
  final VoidCallback onLoginClick;

  // Constructor para la clase, permite pasar funciones para los tres callbacks.
  // Si no se pasa ninguna función, se usa la función por defecto _defaultCallback.
  const SelectionScreen({
    Key? key,
    this.onArtistClick = _defaultCallback,
    this.onContractorClick = _defaultCallback,
    this.onLoginClick = _defaultCallback,
  }) : super(key: key);

  // Función por defecto que no hace nada, se usa cuando no se pasan funciones específicas.
  static void _defaultCallback() {}

  @override
  Widget build(BuildContext context) {
    // Definimos la fuente principal que se usará en el texto de la UI.
    final fontMainFamily = AppStrings.bevietnamProRegular;

    // Obtenemos el esquema de colores de la aplicación para aplicar el tema.
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      // Configuramos el color de fondo del Scaffold utilizando el esquema de colores.
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Padding(
        // Aplicamos un padding de 20 puntos en todos los lados.
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Esto crea un espacio vacío de 65% del total disponible en el eje vertical.
            const Spacer(flex: 65),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Un texto que muestra el nombre de la aplicación, con estilo personalizado.
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontFamily: fontMainFamily,
                    color: colorScheme[AppStrings.secondaryColor],
                    fontSize: 37,
                  ),
                ),
                const SizedBox(
                  height: 40,
                ), // Espacio vacío de 40 puntos entre elementos.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Dos tarjetas de opción (OptionCard) que representan las opciones disponibles.
                    OptionCard(
                      text: AppStrings.iAmMusician,
                      imageRes: AppStrings.icMusicAsset,
                      onClick: onArtistClick,
                    ),
                    OptionCard(
                      text: AppStrings.iWantToHire,
                      imageRes: AppStrings.icContractorAsset,
                      onClick: onContractorClick,
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(flex: 5), // Espacio vacío de 5% en la parte inferior.
            Align(
              alignment:
                  Alignment
                      .bottomRight, // Alinea el texto en la parte inferior derecha.
              child: GestureDetector(
                // Detecta un toque y llama al callback para iniciar sesión.
                onTap: onLoginClick,
                child: Text(
                  AppStrings.logIn,
                  style: TextStyle(
                    fontFamily: fontMainFamily,
                    color: colorScheme[AppStrings.secondaryColor],
                    fontSize: 17,
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
