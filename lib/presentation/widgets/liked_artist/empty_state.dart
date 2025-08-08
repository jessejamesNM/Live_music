// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
//
// Descripción: Esta pantalla muestra un estado vacío cuando el usuario no tiene artistas en su lista de favoritos.
// Utiliza un ícono de "corazón vacío" junto con un mensaje que invita al usuario a empezar a agregar artistas a sus favoritos.
//
// Recomendaciones:
// - Considerar añadir más interacciones para guiar al usuario a explorar artistas o agregar su primer favorito.
// - Añadir una animación o transición visual para hacer que el estado vacío sea más dinámico.
//
// Características:
// - Se muestra un ícono de corazón vacío (que podría cambiar según el tema).
// - El texto explica que el usuario no tiene favoritos y le da una sugerencia para comenzar a agregar.
// - Los textos tienen estilos personalizados según el esquema de colores actual.
//
// Comentarios del código:
// - Se utiliza un `Center` para alinear todo en el centro de la pantalla.
// - Los textos y el ícono están distribuidos en una columna, ajustando su espacio con márgenes adecuados.
// - Se toma el esquema de colores desde el `ColorPalette` para mantener la consistencia visual en toda la aplicación.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtiene el esquema de colores actual
    final colorScheme = ColorPalette.getPalette(context);

    // Construye la interfaz de usuario
    return Center(
      // Centra los elementos en la pantalla
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Centra los elementos verticalmente
        children: [
          // Icono de corazón vacío, de tamaño grande
          Icon(
            Icons.favorite_border,
            size: 64,
            color:
                colorScheme[AppStrings
                    .essentialColor], // Aplica el color principal del esquema
          ),
          // Espaciado entre el ícono y el texto
          SizedBox(height: 16),
          // Primer mensaje indicando que no hay favoritos
          Text(
            AppStrings.noFavoritesYet, // Mensaje de estado vacío
            style: TextStyle(
              fontSize: 18, // Tamaño del texto
              color: colorScheme[AppStrings.secondaryColor], // Color del texto
            ),
          ),
          // Espaciado entre los dos textos
          SizedBox(height: 8),
          // Segundo mensaje animando al usuario a empezar a agregar favoritos
          Text(
            AppStrings.startLikingArtists, // Sugerencia para agregar favoritos
            style: TextStyle(
              fontSize: 14, // Tamaño del texto más pequeño
              color: colorScheme[AppStrings.secondaryColor]?.withOpacity(
                0.7,
              ), // Color más suave
            ),
          ),
        ],
      ),
    );
  }
}
