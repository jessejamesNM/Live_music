/// Autor: kingdomOfJames
/// Fecha: 2025-04-22
///
/// Descripción:
/// `OptionCard` es un widget reutilizable que representa una tarjeta táctil (card)
/// con un ícono SVG y un texto, usado principalmente para mostrar opciones al usuario
/// en la `SelectionScreen`, como elegir entre "Artista" o "Contratante".
///
/// Características:
/// - El widget es táctil y ejecuta la función `onClick` cuando es presionado
/// - Muestra un ícono en SVG centrado y un texto descriptivo debajo
/// - El diseño visual se adapta al tema de la app a través de `ColorPalette`
/// - Usa una fuente definida en `AppStrings.bevietnamProRegular` para mantener consistencia tipográfica
///
/// Parámetros:
/// - `text`: texto que describe la opción (ej. "Artista")
/// - `imageRes`: ruta al recurso SVG que representa gráficamente la opción
/// - `onClick`: función callback que se ejecuta cuando se toca la tarjeta
///
/// Notas:
/// - Recomendado para vistas de selección de tipo de usuario u otras pantallas de onboarding
/// - Puede escalarse para incluir más información si es necesario (descripción, subtexto, etc.)

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OptionCard extends StatelessWidget {
  // Tres propiedades requeridas para configurar el texto, la imagen y la acción al hacer clic.
  final String text;
  final String imageRes;
  final VoidCallback onClick;

  // Constructor que toma los valores de texto, imagen y acción al hacer clic.
  const OptionCard({
    Key? key,
    required this.text,
    required this.imageRes,
    required this.onClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Definimos la fuente principal a usar en los textos de la tarjeta.
    final fontMainFamily = AppStrings.bevietnamProRegular;

    // Obtenemos el esquema de colores de la aplicación para aplicarlos a la tarjeta.
    final colorScheme = ColorPalette.getPalette(context);

    return GestureDetector(
      // Detecta el toque en la tarjeta y ejecuta el callback onClick cuando es tocada.
      onTap: onClick,
      child: Card(
        // Configura el color de la tarjeta según el esquema de colores. Si no está definido, usa blanco por defecto.
        color: colorScheme[AppStrings.primaryColorLight] ?? Colors.white,
        // Definimos el borde de la tarjeta con un radio de curvatura de 20.
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          // Fija el tamaño de la tarjeta a 170x170.
          width: 170,
          height: 170,
          child: Padding(
            // Agrega un padding interno de 8 puntos a la tarjeta.
            padding: const EdgeInsets.all(8.0),
            child: Column(
              // Alineamos los elementos hijos en el centro de la columna.
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Muestra la imagen (un archivo SVG) usando SvgPicture.
                SvgPicture.asset(
                  imageRes,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  // Usamos un color específico del esquema de colores.
                  color: colorScheme[AppStrings.essentialColor],
                ),
                const SizedBox(
                  height: 8,
                ), // Espacio de 8 puntos entre la imagen y el texto.
                // Muestra el texto que se pasa como parámetro.
                Text(
                  text,
                  style: TextStyle(
                    fontFamily:
                        fontMainFamily, // Usamos la fuente principal definida.
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color del texto.
                    fontWeight: FontWeight.bold, // Texto en negrita.
                    fontSize: 16, // Tamaño del texto.
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
