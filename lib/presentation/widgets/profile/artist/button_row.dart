// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
// Descripción: Esta pantalla presenta una fila de botones horizontales para navegar entre secciones en una interfaz de usuario. Los botones cambian de apariencia cuando están seleccionados, proporcionando una interacción visual clara para el usuario.
// Recomendaciones: Este componente puede ser reutilizado en otras partes de la aplicación que necesiten una fila de botones de navegación similar. Asegúrate de que los índices de los botones sean consistentes con las secciones que deseas manejar.
// Características:
// - Utiliza un contenedor horizontal para los botones.
// - Cada botón se define con un texto y una forma específica.
// - Los botones tienen un estado visual diferente cuando están seleccionados.
// - El diseño está basado en un esquema de colores personalizables a través de la paleta de colores definida.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart'; // Importa la paleta de colores personalizada
import 'package:live_music/presentation/resources/strings.dart'; // Importa las cadenas de texto personalizadas

// Widget que representa una fila de botones para navegación
class ButtonRow extends StatefulWidget {
  final int selectedButtonIndex; // Índice del botón seleccionado
  final Function(int)
  onButtonSelect; // Callback para manejar la selección de un botón

  const ButtonRow({
    Key? key,
    required this.selectedButtonIndex, // Recibe el índice del botón seleccionado como parámetro
    required this.onButtonSelect, // Recibe la función de callback para manejar la selección del botón
  }) : super(key: key);

  @override
  _ButtonRowState createState() => _ButtonRowState();
}

class _ButtonRowState extends State<ButtonRow> {
  // Lista de botones con sus respectivas configuraciones
  final List<ButtonData> buttons = [
    ButtonData(
      text: AppStrings.works, // Texto del primer botón
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft:
              Radius
                  .zero, // No tiene bordes redondeados en la esquina superior izquierda
          bottomLeft:
              Radius
                  .zero, // No tiene bordes redondeados en la esquina inferior izquierda
        ),
      ),
      index: 0, // Índice de este botón
    ),
    ButtonData(
      text: AppStrings.availability, // Texto del segundo botón
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ), // Sin bordes redondeados
      index: 1, // Índice de este botón
    ),
    ButtonData(
      text: AppStrings.dates, // Texto del tercer botón
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ), // Sin bordes redondeados
      index: 2, // Índice de este botón
    ),
    ButtonData(
      text: AppStrings.review, // Texto del cuarto botón
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight:
              Radius
                  .zero, // No tiene bordes redondeados en la esquina superior derecha
          bottomRight:
              Radius
                  .zero, // No tiene bordes redondeados en la esquina inferior derecha
        ),
      ),
      index: 3, // Índice de este botón
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene la paleta de colores definida en la aplicación

    // Devuelve el widget de la fila de botones
    return Container(
      color:
          colorScheme[AppStrings
              .primaryColorLight], // Color de fondo de la fila de botones
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal, // Los botones se presentan horizontalmente
        itemCount: buttons.length, // Número de botones en la fila
        itemBuilder: (context, index) {
          final button = buttons[index]; // Obtiene el botón según el índice
          final isSelected =
              widget.selectedButtonIndex ==
              button.index; // Verifica si el botón está seleccionado

          // Retorna el widget de cada botón
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4.0,
            ), // Espaciado horizontal entre los botones
            child: ElevatedButton(
              onPressed:
                  () => widget.onButtonSelect(
                    button.index,
                  ), // Llama a la función de selección al presionar
              style: ElevatedButton.styleFrom(
                padding:
                    EdgeInsets
                        .zero, // Elimina el padding para que el contenido ocupe todo el botón
                shape:
                    button.shape as OutlinedBorder, // Define la forma del botón
                backgroundColor:
                    colorScheme[AppStrings
                        .primaryColorLight], // Color de fondo del botón
                foregroundColor:
                    isSelected
                        ? colorScheme[AppStrings
                            .secondaryColor] // Color de texto cuando está seleccionado
                        : colorScheme[AppStrings
                            .secondaryColorLittleDark], // Color de texto cuando no está seleccionado
              ),
              child: Text(
                button.text, // Texto del botón
                style: const TextStyle(
                  fontSize: 16, // Tamaño de fuente
                  fontFamily: AppStrings.customFont, // Fuente personalizada
                ),
                textAlign: TextAlign.center, // Alineación del texto
              ),
            ),
          );
        },
      ),
    );
  }
}

// Clase que representa la información de cada botón
class ButtonData {
  final String text; // Texto que se muestra en el botón
  final ShapeBorder shape; // Forma del botón
  final int index; // Índice del botón

  ButtonData({
    required this.text,
    required this.shape,
    required this.index,
  }); // Constructor de la clase
}
