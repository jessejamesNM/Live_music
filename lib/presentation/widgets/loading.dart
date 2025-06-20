// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: Esta pantalla muestra un indicador de carga (CircularProgressIndicator) mientras se espera un proceso, como la carga de datos. Utiliza una paleta de colores personalizada para que la interfaz se ajuste al tema de la aplicación.
// La pantalla incluye un texto de "Cargando", un ícono de carga y un botón para simular una acción (en este caso, no realiza ninguna acción).
// Recomendaciones: Esta pantalla es útil en situaciones donde se necesita mostrar al usuario que un proceso está en curso. Se recomienda personalizar la lógica del botón y la acción del progreso de carga según sea necesario.
// Características:
// 1. Pantalla centrada con un indicador de carga circular.
// 2. Utiliza una paleta de colores personalizada para los elementos de la interfaz.
// 3. Incluye un botón con un color de fondo que se ajusta al tema de la aplicación.

// Código comentado:

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Obtiene la paleta de colores personalizada según el tema actual
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor:
          colorScheme[AppStrings.primaryColor], // Fondo con primaryColor
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Centra el contenido verticalmente
          children: [
            // Texto central "Bienvenido a live music" con color secundario
            Text(
              'Bienvenido a Live Music',
              style: TextStyle(
                fontSize: 24,
                color: colorScheme[AppStrings.secondaryColor], // Texto con secondaryColor
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 30,
            ), // Espaciado entre el texto y el indicador de carga
            // Indicador de carga circular con color personalizado
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme[AppStrings.essentialColor]!, // Color de la barra de carga con essentialColor
              ),
            ),
            const SizedBox(
              height: 16,
            ), // Espaciado entre el indicador de carga y el texto
            // Texto de "Cargando" con color secundario
            Text(
              'Cargando...',
              style: TextStyle(
                color: colorScheme[AppStrings.secondaryColor], // Texto con secondaryColor
              ),
            ),
          ],
        ),
      ),
    );
  }
}