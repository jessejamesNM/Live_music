// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
// Descripción: El widget `ButtonRowWS` muestra una fila horizontal de botones personalizables que permiten a los usuarios seleccionar diferentes opciones de una lista, como "Works", "Availability", "Information", y "Reviews". El estado de selección se gestiona mediante un `ValueNotifier` que actualiza la apariencia y funcionalidad del botón seleccionado.
// Recomendaciones: Este widget es útil en pantallas donde se necesita permitir la selección de una opción entre varias disponibles de forma visualmente clara y fluida. Asegúrate de que los colores y la forma sean consistentes con el diseño general de la aplicación.
// Características:
// - Utiliza un `ValueListenableBuilder` para gestionar el estado de selección.
// - Cada botón tiene una forma y color personalizado basado en la paleta de colores de la aplicación.
// - El widget se adapta dinámicamente cuando el estado de selección cambia.

import 'package:flutter/material.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart'; // Importa la lógica de estado de usuario
import 'package:live_music/presentation/resources/colors.dart'; // Importa los colores personalizados
import 'package:live_music/presentation/resources/strings.dart'; // Importa las cadenas de texto personalizadas

// Widget que representa una fila horizontal de botones seleccionables
class ButtonRowWS extends StatelessWidget {
  final ValueNotifier<String>
  selectedButtonIndex; // Notificador para gestionar el índice del botón seleccionado
  final Function(String)
  onButtonSelect; // Función callback que se llama cuando se selecciona un botón
  final UserProvider userProvider; // Proveedor de estado de usuario

  // Constructor que recibe los parámetros necesarios
  ButtonRowWS({
    required this.selectedButtonIndex,
    required this.onButtonSelect,
    required this.userProvider,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene el esquema de colores de la aplicación

    // Lista de botones con sus textos, formas y selecciones (strings)
    final buttons = [
      ButtonDataWS(
        text: AppStrings.works, // Texto del primer botón
        shape: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        selection:
            AppStrings
                .worksSelectionWS, // String de selección asociado al botón
      ),
      ButtonDataWS(
        text: AppStrings.availability, // Texto del segundo botón
        shape: BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        selection:
            AppStrings
                .availabilitySelectionWS, // String de selección asociado al botón
      ),
      ButtonDataWS(
        text: AppStrings.information, // Texto del tercer botón
        shape: BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        selection:
            AppStrings
                .informationSelectionWS, // String de selección asociado al botón
      ),
      ButtonDataWS(
        text: AppStrings.reviews, // Texto del cuarto botón
        shape: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        selection:
            AppStrings
                .reviewsSelectionWS, // String de selección asociado al botón
      ),
    ];

    return ValueListenableBuilder<String>(
      valueListenable:
          selectedButtonIndex, // Vincula el notificador con el estado actual
      builder: (context, value, child) {
        return Container(
          color:
              colorScheme[AppStrings
                  .primaryColorLight], // Fondo del contenedor según la paleta de colores
          padding: const EdgeInsets.symmetric(
            vertical: 8,
          ), // Espaciado vertical
          child: SingleChildScrollView(
            scrollDirection:
                Axis.horizontal, // Permite desplazarse horizontalmente si hay muchos botones
            child: Row(
              children:
                  buttons.map((button) {
                    final isSelected =
                        value ==
                        button
                            .selection; // Verifica si el botón está seleccionado

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                      ), // Espaciado entre los botones
                      child: Material(
                        borderRadius:
                            button.shape, // Forma personalizada para cada botón
                        color:
                            colorScheme[AppStrings
                                .primaryColorLight], // Color de fondo del botón
                        child: InkWell(
                          borderRadius:
                              button.shape, // Forma del botón al hacer clic
                          onTap: () {
                            selectedButtonIndex.value =
                                button
                                    .selection; // Actualiza el estado de selección
                            onButtonSelect(
                              button.selection,
                            ); // Llama a la función de selección
                            userProvider.setMenuSelection(
                              button.selection,
                            ); // Actualiza la selección en el proveedor de usuario
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ), // Espaciado interno del botón
                            decoration: BoxDecoration(
                              borderRadius: button.shape, // Forma del borde
                              border:
                                  isSelected
                                      ? Border.all(
                                        color:
                                            colorScheme[AppStrings
                                                .secondaryColor]!, // Borde cuando el botón está seleccionado
                                        width: 1.5,
                                      )
                                      : null,
                            ),
                            child: Text(
                              button.text, // Muestra el texto del botón
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color:
                                    colorScheme[AppStrings
                                        .secondaryColor], // Color del texto
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }
}

// Clase que define los datos de cada botón (texto, forma y selección)
class ButtonDataWS {
  final String text; // Texto que se muestra en el botón
  final BorderRadius shape; // Forma del borde del botón
  final String selection; // Identificador único para la selección del botón

  // Constructor de la clase
  ButtonDataWS({
    required this.text,
    required this.shape,
    required this.selection,
  });
}
