// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
//
// Descripción:
// Este widget es un "ExpandableCard", una tarjeta que se expande o contrae al ser tocada.
// Su título es visible de forma predeterminada, y al hacer clic, el contenido de la tarjeta se muestra o se oculta.
// Es ideal para mostrar información adicional de forma comprimida y permitir al usuario expandirla si lo desea.
//
// Características:
// - El título es siempre visible cuando la tarjeta está contraída.
// - El contenido dentro de la tarjeta solo se muestra si la tarjeta está expandida.
// - Se utiliza GestureDetector para detectar los clics y controlar la expansión o contracción de la tarjeta.
// - La apariencia de la tarjeta puede personalizarse con colores definidos en la paleta del proyecto.
// - La tarjeta tiene bordes redondeados y un estilo visual consistente con el tema del proyecto.

// Recomendaciones:
// - Este widget puede ser útil para mostrar listas de elementos o configuraciones que el usuario puede expandir para obtener más detalles sin sobrecargar la pantalla.
// - Asegúrate de que el contenido de la tarjeta no sea demasiado largo para evitar un desbordamiento visual. Si es necesario, utiliza un `SingleChildScrollView` para manejar el desbordamiento.
// - Considera agregar animaciones al expandir o contraer el contenido para mejorar la experiencia del usuario.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class ExpandableCard extends StatelessWidget {
  final String title; // Título de la tarjeta.
  final bool isExpanded; // Estado de la tarjeta (expandida o contraída).
  final VoidCallback
  onClick; // Función que se ejecuta al hacer clic en la tarjeta.
  final Widget content; // Contenido que se muestra al expandir la tarjeta.

  // Constructor de la tarjeta expansible, recibe el título, el estado, el callback para el clic y el contenido.
  ExpandableCard({
    required this.title,
    required this.isExpanded,
    required this.onClick,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return GestureDetector(
      // Detecta el clic para cambiar el estado de la tarjeta (expandir o contraer).
      onTap: onClick,
      child: Container(
        width:
            double
                .infinity, // Hace que la tarjeta ocupe todo el ancho disponible.
        decoration: BoxDecoration(
          color:
              colorScheme[AppStrings
                  .primaryColor], // Color de fondo de la tarjeta.
          border: Border.all(
            color:
                colorScheme[AppStrings
                    .secondaryColor]!, // Color del borde de la tarjeta.
            width: 2,
          ), // Borde blanco con grosor de 2.
          borderRadius: BorderRadius.circular(
            12,
          ), // Bordes redondeados con radio de 12.
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            16.0,
          ), // Relleno alrededor del contenido de la tarjeta.
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start, // Alineación del contenido al principio de la columna.
            children: [
              if (!isExpanded) // Si la tarjeta no está expandida, muestra solo el título.
                Text(
                  title, // Título de la tarjeta.
                  style: TextStyle(
                    fontSize: 18, // Tamaño de fuente del título.
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color del texto según el tema.
                  ),
                ),
              if (isExpanded) ...[
                // Si la tarjeta está expandida, muestra el contenido.
                SizedBox(
                  height: 8,
                ), // Espaciado entre el título y el contenido.
                content, // Contenido de la tarjeta que se muestra cuando está expandida.
              ],
            ],
          ),
        ),
      ),
    );
  }
}
