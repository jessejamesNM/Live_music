// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción:
// Esta clase `MusicChip` crea un widget personalizado que representa una etiqueta
// interactiva (chip) con la capacidad de ser seleccionada o deseleccionada. El chip
// puede tener un aspecto visual diferente dependiendo de si está seleccionado o no.
// Se utiliza en interfaces donde el usuario puede seleccionar elementos relacionados con música,
// como géneros musicales, artistas, o estilos, con un diseño atractivo y responsivo.
// Recomendaciones:
// - Asegúrate de gestionar el estado de selección correctamente en el widget padre,
//   para que los cambios visuales sean reflejados adecuadamente.
// - Puedes añadir más personalizaciones visuales o de interacción según la necesidad.
// Características:
// - El chip es un contenedor circular con texto centrado.
// - El color del fondo y el color del texto cambian según el estado de selección.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class MusicChip extends StatelessWidget {
  // Parámetros requeridos para personalizar el chip
  final String text; // El texto que se muestra en el chip
  final bool isSelected; // Indica si el chip está seleccionado
  final VoidCallback
  onClick; // Función que se ejecuta cuando se hace click en el chip

  MusicChip({
    required this.text, // Se pasa el texto que mostrará el chip
    required this.isSelected, // Se indica si el chip está seleccionado o no
    required this.onClick, // La función que se ejecuta al hacer clic en el chip
  });

  @override
  Widget build(BuildContext context) {
    // Obtiene el esquema de colores actual desde el contexto
    final colorScheme = ColorPalette.getPalette(context);

    // La estructura del widget está envuelta en un GestureDetector para captar la interacción
    return GestureDetector(
      onTap: onClick, // Llama a la función cuando se hace clic en el chip
      child: SizedBox(
        child: AspectRatio(
          // Mantiene una relación de aspecto 1:1 para el chip (cuadrado)
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              // Si está seleccionado, se cambia el color de fondo
              color:
                  isSelected
                      ? colorScheme[AppStrings
                          .essentialColor] // Color de fondo cuando está seleccionado
                      : colorScheme[AppStrings
                          .primaryColorLight], // Color de fondo cuando no está seleccionado
              borderRadius: BorderRadius.circular(12), // Bordes redondeados
            ),
            child: Center(
              // El texto se coloca en el centro del contenedor
              child: Text(
                text, // Texto del chip
                style: TextStyle(
                  fontSize: 20, // Tamaño de la fuente
                  color:
                      isSelected
                          ? colorScheme[AppStrings
                              .primaryColorLight] // Color de texto si está seleccionado
                          : colorScheme[AppStrings
                              .secondaryColor], // Color de texto si no está seleccionado
                ),
                textAlign: TextAlign.center, // Alineación centrada
              ),
            ),
          ),
        ),
      ),
    );
  }
}
