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
  final String text;
  final String? iconPath;
  final bool isSelected;
  final VoidCallback onClick;

  const EventCard({
    required this.text,
    required this.iconPath,
    required this.isSelected,
    required this.onClick,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return GestureDetector(
      onTap: onClick,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                isSelected
                    ? colorScheme[AppStrings.secondaryColor] ?? Colors.blue
                    : Colors.grey[300]!,
            width: 1,
          ),
        ),
        color:
            isSelected
                ? colorScheme[AppStrings.essentialColor] ?? Colors.red
                : colorScheme[AppStrings.primaryColorLight] ?? Colors.white,
        child: SizedBox(
          width: 140,
          height: 140,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconPath != null)
                  SvgPicture.asset(
                    iconPath!,
                    width: 60,
                    height: 60,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
