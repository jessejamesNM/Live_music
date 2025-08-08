// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
//
// Descripción:
// Este widget es una tarjeta de categoría (CategoryCard), diseñada para mostrar una categoría específica, como un género musical o una categoría temática.
// La tarjeta tiene un fondo personalizado, bordes redondeados y una animación de clic (InkWell) para hacerla interactiva.
// Al hacer clic en la tarjeta, se ejecuta un callback `onClick` que permite definir una acción personalizada al presionar la tarjeta.
//
// Características:
// - La tarjeta tiene un fondo de color configurado según el tema actual.
// - Los bordes son redondeados con un radio de 16.
// - Al tocar la tarjeta, se dispara la función `onClick` proporcionada por el usuario.
// - El texto que muestra la categoría se ajusta dependiendo de la categoría que se le pase (por ejemplo, el tamaño de fuente cambia para "reggaetonUrbanCategory").
//
// Recomendaciones:
// - Este widget es útil para representar elementos clicables en una lista o cuadrícula de categorías.
// - Se puede usar para representar géneros musicales, secciones temáticas, filtros, entre otros.
// - Asegúrate de que el texto sea legible, especialmente si se usan categorías con nombres largos.
// - Es recomendable añadir animaciones o transiciones al interactuar con las tarjetas para mejorar la experiencia del usuario.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class CategoryCard extends StatelessWidget {
  final String category; // Nombre de la categoría a mostrar en la tarjeta.
  final VoidCallback
  onClick; // Función que se ejecuta al hacer clic en la tarjeta.

  // Constructor que recibe la categoría y el callback para el clic.
  const CategoryCard({required this.category, required this.onClick});

  @override
  Widget build(BuildContext context) {
    // Obtiene la paleta de colores según el contexto (tema de la app).
    final colorScheme = ColorPalette.getPalette(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ), // Borde redondeado con radio de 16.
      color:
          colorScheme[AppStrings.primaryColorLight] ??
          Colors.grey, // Color de fondo de la tarjeta (color primario ligero).
      child: InkWell(
        // Detecta el clic sobre la tarjeta y ejecuta el callback proporcionado.
        onTap: onClick,
        child: Container(
          width: 110, // Ancho de la tarjeta.
          height: 52, // Altura de la tarjeta.
          alignment: Alignment.center, // Centra el texto en la tarjeta.
          child: Text(
            category, // Texto que muestra el nombre de la categoría.
            style: TextStyle(
              fontSize:
                  category == AppStrings.reggaetonUrbanCategory
                      ? 12
                      : 14, // Ajusta el tamaño de fuente para una categoría específica.
              color:
                  Theme.of(
                    context,
                  ).secondaryHeaderColor, // Color del texto basado en el tema.
              fontFamily:
                  AppStrings.customFont, // Fuente personalizada para el texto.
            ),
            textAlign: TextAlign.center, // Alineación centrada del texto.
          ),
        ),
      ),
    );
  }
}
