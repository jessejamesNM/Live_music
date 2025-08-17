// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
// Descripción: Este widget muestra un "chip" o etiqueta visual para un género musical. El chip contiene el nombre del género y, si la opción de edición está habilitada, un botón para eliminarlo. Es útil en interfaces donde los usuarios pueden agregar o quitar géneros musicales de una lista.
// Recomendaciones: Este componente es adecuado para pantallas de edición o filtrado donde los géneros pueden ser añadidos o eliminados. Puedes usarlo para crear una lista de géneros seleccionados en una interfaz de usuario donde se requiera una selección dinámica.
// Características:
// - Muestra un texto con el nombre del género.
// - Incluye un botón de cierre (eliminar) si está habilitada la opción de edición.
// - Está estilizado con un `Card` y puede personalizarse mediante el esquema de colores de la aplicación.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart'; // Importa la paleta de colores personalizada
import 'package:live_music/presentation/resources/strings.dart'; // Importa las cadenas de texto personalizadas

// Widget que representa un chip de género musical
class GenreChip extends StatelessWidget {
  final String genre; // Género musical que se va a mostrar en el chip
  final VoidCallback
  onRemove; // Callback que se ejecuta al hacer clic en el botón de eliminación
  final bool
  isEditing; // Determina si el chip está en modo de edición (y, por lo tanto, puede ser eliminado)

  const GenreChip({
    Key? key,
    required this.genre, // Recibe el nombre del género como parámetro
    required this.onRemove, // Recibe la función de eliminación como parámetro
    required this.isEditing, // Recibe el estado de edición (si el chip puede ser eliminado)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene la paleta de colores personalizada

    // Devuelve el widget del chip de género
    return Card(
      margin: const EdgeInsets.all(4.0), // Margen alrededor del chip
      color:
          Theme.of(
            context,
          ).primaryColor, // Color de fondo del chip basado en el esquema de colores
      child: Padding(
        padding: const EdgeInsets.all(
          8.0,
        ), // Padding interno para separar el contenido del borde
        child: Row(
          mainAxisSize:
              MainAxisSize
                  .min, // Asegura que el tamaño del Row sea solo lo necesario para los elementos internos
          children: [
            // Muestra el nombre del género
            Text(
              genre,
              style: TextStyle(
                fontSize: 14, // Tamaño de la fuente
                color:
                    colorScheme[AppStrings
                        .secondaryColor], // Color del texto basado en la paleta de colores
              ),
            ),
            // Si estamos en modo de edición, mostramos un botón para eliminar el chip
            if (isEditing)
              IconButton(
                icon: Icon(
                  Icons.close, // Ícono de cerrar (eliminar)
                  size: 16, // Tamaño del ícono
                  color:
                      colorScheme[AppStrings
                          .secondaryColor], // Color del ícono basado en la paleta de colores
                ),
                onPressed:
                    onRemove, // Llama a la función onRemove al presionar el ícono
              ),
          ],
        ),
      ),
    );
  }
}
