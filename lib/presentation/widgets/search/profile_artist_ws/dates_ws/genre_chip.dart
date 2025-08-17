// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
// Descripción: Este widget crea un chip visual para mostrar un género musical. Se utiliza para representar etiquetas de géneros dentro de una interfaz de usuario, con un diseño limpio y sencillo. El chip está contenido dentro de un `Card` y muestra el texto del género pasado como parámetro.
// Recomendaciones: Este componente es ideal para interfaces donde los géneros musicales se muestran de forma compacta, como en listas de selección o filtros. Es útil para mostrar una lista de géneros seleccionados sin sobrecargar la pantalla.
// Características:
// - Muestra el nombre del género en un chip visual.
// - Se ajusta al esquema de colores de la aplicación, asegurando consistencia visual.
// - Usa un diseño básico con un `Card` que contiene un `Text` que representa el género musical.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart'; // Importa la paleta de colores personalizada
import 'package:live_music/presentation/resources/strings.dart'; // Importa las cadenas de texto personalizadas

// Widget que representa un chip de género musical
class GenreChip extends StatelessWidget {
  final String genre; // Género musical que se va a mostrar en el chip

  // Constructor que recibe el nombre del género
  const GenreChip({required this.genre});

  @override
  Widget build(BuildContext context) {
    // Obtiene el esquema de colores de la aplicación
    final colorScheme = ColorPalette.getPalette(context);

    // Devuelve el widget del chip de género
    return Card(
      margin: EdgeInsets.all(4.0), // Margen alrededor del chip
      color:
          Theme.of(
            context,
          ).primaryColor, // Color de fondo del chip, basado en el tema actual
      child: Padding(
        padding: EdgeInsets.all(
          8.0,
        ), // Padding interno para separar el contenido del borde del chip
        child: Row(
          mainAxisSize:
              MainAxisSize
                  .min, // Asegura que el tamaño del Row sea solo lo necesario para el contenido
          children: [
            // Muestra el nombre del género dentro del chip
            Text(
              genre, // El texto que representa el género musical
              style: TextStyle(
                fontSize: 14.0, // Tamaño de la fuente para el nombre del género
                color:
                    colorScheme[AppStrings
                        .secondaryColor], // Color del texto según la paleta de colores
              ),
            ),
          ],
        ),
      ),
    );
  }
}
