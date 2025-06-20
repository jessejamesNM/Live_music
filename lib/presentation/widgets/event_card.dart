// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: Este widget crea una tarjeta de evento personalizable para mostrar diferentes tipos de eventos, como bodas, fiestas de 15 años, fiestas casuales y eventos públicos. La tarjeta cambia de apariencia cuando se selecciona o deselecciona.
// Recomendaciones: Asegúrate de pasar un texto válido y un callback adecuado al usar este widget. Se recomienda utilizar este widget en un contexto donde los usuarios puedan seleccionar entre diferentes tipos de eventos.
// Características:
// 1. Cambia el color de la tarjeta dependiendo de si está seleccionada.
// 2. Muestra un ícono diferente según el tipo de evento.
// 3. Usabilidad con GestureDetector para la interacción táctil.

// Código comentado:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class EventCard extends StatelessWidget {
  final String
  text; // Texto que describe el evento (ej. boda, fiesta de 15 años, etc.)
  final bool isSelected; // Estado de selección de la tarjeta
  final VoidCallback
  onClick; // Callback que se ejecuta al hacer clic en la tarjeta

  // Constructor para inicializar las propiedades del widget
  EventCard({
    required this.text,
    required this.isSelected,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene la paleta de colores según el contexto del tema
    String? iconPath; // Variable que almacenará el camino del ícono del evento

    // Asigna el ícono correspondiente según el tipo de evento
    switch (text) {
      case AppStrings.wedding:
        iconPath = AppStrings.weddingIcon; // Ícono para bodas
        break;
      case AppStrings.sweetFifteen:
        iconPath = AppStrings.sweetFifteenIcon; // Ícono para fiestas de 15 años
        break;
      case AppStrings.casualParty:
        iconPath = AppStrings.casualPartyIcon; // Ícono para fiestas casuales
        break;
      case AppStrings.publicEvent:
        iconPath = AppStrings.publicEventIcon; // Ícono para eventos públicos
        break;
    }

    return GestureDetector(
      onTap: onClick, // Ejecuta el callback cuando se hace clic en la tarjeta
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            12,
          ), // Bordes redondeados para la tarjeta
          side: BorderSide(
            color:
                isSelected
                    ? colorScheme[AppStrings.secondaryColor] ??
                        Colors
                            .blue // Color de borde si está seleccionado
                    : Colors
                        .grey[300]!, // Color de borde si no está seleccionado
            width: 1,
          ),
        ),
        color:
            isSelected
                ? colorScheme[AppStrings.essentialColor] ??
                    Colors
                        .red // Color de fondo si está seleccionado
                : colorScheme[AppStrings.primaryColorLight] ??
                    Colors.white, // Color de fondo si no está seleccionado
        child: SizedBox(
          width: 140, // Ancho fijo para la tarjeta
          height: 140, // Alto fijo para la tarjeta
          child: Padding(
            padding: const EdgeInsets.all(12), // Espaciado interno
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centra el contenido verticalmente
              children: [
                if (iconPath != null)
                  SvgPicture.asset(
                    iconPath, // Muestra el ícono según el tipo de evento
                    width: 60, // Ancho del ícono
                    height: 60, // Alto del ícono
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color del ícono según el esquema de colores
                  ),
                const SizedBox(
                  height: 8,
                ), // Espaciado entre el ícono y el texto
                Text(
                  text, // Muestra el texto del evento
                  style: TextStyle(
                    fontSize: 16, // Tamaño de fuente
                    fontWeight: FontWeight.w500, // Peso de la fuente
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color del texto
                  ),
                  textAlign: TextAlign.center, // Centra el texto
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
