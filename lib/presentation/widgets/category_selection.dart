// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
//
// Descripción:
// Este widget muestra una fila horizontal de tarjetas de categorías dentro de una sección
// que puede ser utilizada en la pantalla principal de la aplicación. Cada categoría está representada
// por una tarjeta que, al ser clicada, ejecuta una acción (pasando la categoría seleccionada).
//
// Recomendaciones:
// - Es importante asegurarse de que las categorías estén bien definidas y que no haya duplicados.
// - Para una experiencia de usuario óptima, se recomienda no cargar muchas categorías a la vez para evitar problemas de rendimiento.
//
// Características:
// - ListView horizontal para mostrar las categorías de forma eficiente.
// - `CategoryCard` representa cada categoría, y se proporciona un callback para manejar el clic en cada categoría.
// - Se utiliza `AppStrings` para manejar las categorías de manera centralizada.

import 'package:flutter/cupertino.dart';
import 'category_card.dart';
import 'package:live_music/presentation/resources/strings.dart';

class CategoriesSection extends StatelessWidget {
  // Este callback permite pasar la categoría seleccionada al componente padre.
  final Function(String) onCategoryClick;

  // Constructor que inicializa el callback para manejar el clic en una categoría.
  CategoriesSection({required this.onCategoryClick});

  // Lista de categorías que se mostrarán en la sección.
  final List<String> categories = [
    AppStrings.categoryBand, // Categoría: Band
    AppStrings.categoryNortStyle, // Categoría: Norteña
    AppStrings.categoryCorridos, // Categoría: Corridos
    AppStrings.categoryMariachi, // Categoría: Mariachi
    AppStrings.categoryMontainStyle, // Categoría: Estilo Montañés
    AppStrings.categoryCumbia, // Categoría: Cumbia
    AppStrings.reggaeton, // Categoría: Reggaetón
  ];

  @override
  Widget build(BuildContext context) {
    // Retorna un contenedor que contiene un ListView horizontal de categorías.
    return Container(
      height: 52, // Altura fija para la fila de categorías.
      child: ListView.separated(
        // Desplazamiento horizontal.
        scrollDirection: Axis.horizontal,
        itemCount: categories.length, // Número de categorías.
        separatorBuilder:
            (context, index) =>
                const SizedBox(width: 8), // Espaciado entre elementos.
        itemBuilder: (context, index) {
          // Se obtiene la categoría por el índice de la lista.
          final category = categories[index];
          return CategoryCard(
            // Se pasa la categoría y el callback para manejar el clic.
            category: category,
            onClick: () {
              // Se ejecuta la acción pasada desde el widget padre al hacer clic.
              onCategoryClick(category);
            },
          );
        },
      ),
    );
  }
}
