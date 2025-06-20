// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: El widget `CardOption` es una tarjeta interactiva que muestra un texto y ejecuta una acción cuando se toca.
//              Está diseñado para ser reutilizado en cualquier parte de la aplicación donde se necesite una tarjeta con
//              texto que, al ser tocada, ejecute una función, como un botón. Es útil para opciones dentro de menús, formularios,
//              o cualquier otra interfaz donde se desee que el usuario seleccione una acción.
// Recomendaciones: Asegúrate de proporcionar el texto y la función `onClick` correctamente al usar este widget. El texto se
//                  mostrará en el color secundario definido en el tema de la aplicación, y la acción se ejecutará cuando el
//                  usuario toque la tarjeta. Asegúrate de que `ColorPalette.getPalette(context)` devuelva el esquema de colores
//                  adecuado para evitar errores de diseño.
// Características:
//   - Tarjeta interactiva con texto.
//   - Ejecuta una función cuando el usuario toca la tarjeta (acción `onClick`).
//   - Tamaño del texto y color configurados dinámicamente según el esquema de colores de la aplicación.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class CardOption extends StatelessWidget {
  final String text; // El texto que se mostrará en la tarjeta.
  final VoidCallback
  onClick; // La función que se ejecutará cuando se toque la tarjeta.

  CardOption({required this.text, required this.onClick});

  @override
  Widget build(BuildContext context) {
    // Obtener el esquema de colores del contexto actual.
    final colorScheme = ColorPalette.getPalette(context);

    return GestureDetector(
      onTap:
          onClick, // Ejecutar la función `onClick` cuando se toque la tarjeta.
      child: Container(
        width:
            double
                .infinity, // Hacer que la tarjeta ocupe el ancho completo disponible.
        padding: EdgeInsets.all(
          16.0,
        ), // Aplicar un padding de 16 píxeles alrededor del contenido de la tarjeta.
        child: Text(
          text, // Mostrar el texto proporcionado en la tarjeta.
          style: TextStyle(
            fontSize: 16.0, // Tamaño de fuente estático para el texto.
            color:
                colorScheme[AppStrings
                    .secondaryColor], // Usar el color secundario del esquema de colores para el texto.
          ),
        ),
      ),
    );
  }
}
