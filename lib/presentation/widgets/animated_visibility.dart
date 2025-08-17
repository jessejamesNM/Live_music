// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: Este widget es una versión animada de un widget visible. Permite controlar la visibilidad de un hijo
//              con animaciones de opacidad. Se puede usar para mostrar u ocultar elementos de la interfaz de usuario
//              de manera suave. La opacidad cambia de forma animada, haciendo que el widget aparezca o desaparezca
//              con una transición de tiempo controlada por el parámetro `duration`.
//
// Recomendaciones:
// 1. Ideal para hacer transiciones suaves en elementos de la UI, como botones, imágenes o textos.
// 2. Si el `child` es un widget pesado, asegúrate de que la animación no cause retrasos en la interfaz.
// 3. Puedes personalizar la duración de la animación según el contexto o la experiencia de usuario que desees.
// 4. Es útil en casos donde deseas mostrar o esconder contenido sin afectar el flujo del layout.
//
// Características:
// 1. La animación de visibilidad se controla mediante el parámetro `visible`.
// 2. La duración de la animación es configurable a través del parámetro `duration`, con un valor predeterminado de 300 ms.
// 3. Cuando `visible` es falso, el widget hijo se reemplaza por un `SizedBox` vacío para evitar que ocupe espacio.

import 'package:flutter/cupertino.dart';

// Widget AnimatedVisibility
// Un widget que permite mostrar o esconder un hijo con una animación de opacidad.

class AnimatedVisibility extends StatelessWidget {
  final bool visible; // Determina si el widget hijo es visible o no.
  final Widget child; // El widget que se mostrará u ocultará.
  final Duration duration; // Duración de la animación de opacidad.

  // Constructor del widget, donde se reciben los parámetros `visible`, `child` y `duration`.
  // Si no se pasa un valor para `duration`, se usa un valor predeterminado de 300 milisegundos.
  const AnimatedVisibility({
    required this.visible,
    required this.child,
    this.duration = const Duration(
      milliseconds: 300,
    ), // Valor predeterminado para la duración.
  });

  @override
  Widget build(BuildContext context) {
    // Aquí utilizamos AnimatedOpacity para animar la visibilidad del widget `child` dependiendo del valor de `visible`.
    return AnimatedOpacity(
      opacity:
          visible
              ? 1.0
              : 0.0, // Si `visible` es true, la opacidad es 1 (totalmente visible), si es false, 0 (invisible).
      duration: duration, // Duración de la animación de opacidad.
      child:
          visible
              ? child
              : SizedBox(), // Si `visible` es true, mostramos el widget `child`, sino mostramos un `SizedBox` vacío.
    );
  }
}
