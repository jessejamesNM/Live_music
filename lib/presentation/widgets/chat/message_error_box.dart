/*
Fecha de creación: 26 de abril de 2025
Autor: KingdomOfJames

Descripción general:
El widget 'ErrorMessageBox' muestra un pequeño contenedor de error o alerta con un texto personalizado.
Se usa para mostrar mensajes de error en la aplicación de forma clara y llamativa.

Características:
- Permite personalizar el color de fondo del mensaje.
- Utiliza un esquema de colores para definir el color del texto.
- El tamaño del cuadro se adapta automáticamente, entre 50 y 250 de ancho.

Recomendaciones:
- Asegurar que los colores proporcionados en `colorScheme` contengan el valor para `AppStrings.secondaryColor` para evitar usar el color blanco por defecto.
- Utilizar textos breves para evitar que el cuadro de error se vea saturado.
- Podría mejorarse agregando íconos o animaciones para errores más visibles.

Notas adicionales:
- Es un widget stateless, por lo tanto muy ligero y eficiente.
*/

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';

class ErrorMessageBox extends StatelessWidget {
  final String text; // Texto que se mostrará dentro del cuadro de error
  final Color backgroundColor; // Color de fondo del cuadro de error
  final Map<String, Color>
  colorScheme; // Mapa de esquema de colores para obtener el color del texto

  ErrorMessageBox({
    required this.text,
    required this.backgroundColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Establece el padding interno del mensaje
      padding: EdgeInsets.all(8),
      // Restringe el tamaño mínimo y máximo del ancho del cuadro
      constraints: BoxConstraints(minWidth: 50, maxWidth: 250),
      decoration: BoxDecoration(
        color: backgroundColor, // Usa el color de fondo proporcionado
        borderRadius: BorderRadius.circular(
          4,
        ), // Bordes ligeramente redondeados
      ),
      child: Text(
        text,
        style: TextStyle(
          // Intenta usar el color definido en colorScheme, si no, usa blanco
          color: colorScheme[AppStrings.secondaryColor] ?? Colors.white,
        ),
      ),
    );
  }
}
