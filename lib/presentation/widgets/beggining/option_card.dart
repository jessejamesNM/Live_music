/// Autor: kingdomOfJames
/// Fecha: 2025-04-22
///
/// Descripción:
/// `OptionCard` es un widget reutilizable que representa una tarjeta táctil (card)
/// con un ícono SVG y un texto, usado principalmente para mostrar opciones al usuario
/// en la `SelectionScreen`, como elegir entre "Artista" o "Contratante".
///
/// Características:
/// - El widget es táctil y ejecuta la función `onClick` cuando es presionado
/// - Muestra un ícono en SVG centrado y un texto descriptivo debajo
/// - El diseño visual se adapta al tema de la app a través de `ColorPalette`
/// - Usa una fuente definida en `AppStrings.bevietnamProRegular` para mantener consistencia tipográfica
///
/// Parámetros:
/// - `text`: texto que describe la opción (ej. "Artista")
/// - `imageRes`: ruta al recurso SVG que representa gráficamente la opción
/// - `onClick`: función callback que se ejecuta cuando se toca la tarjeta
///
/// Notas:
/// - Recomendado para vistas de selección de tipo de usuario u otras pantallas de onboarding
/// - Puede escalarse para incluir más información si es necesario (descripción, subtexto, etc.)

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OptionCard extends StatelessWidget {
  final String text;
  final String imageRes;
  final VoidCallback onClick;

  const OptionCard({
    Key? key,
    required this.text,
    required this.imageRes,
    required this.onClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontMainFamily = AppStrings.bevietnamProRegular;
    final colorScheme = ColorPalette.getPalette(context);

    return GestureDetector(
      onTap: onClick,
      child: Card(
        color: colorScheme[AppStrings.primaryColorLight] ?? Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 170,
          height: 170,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  imageRes,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  color: colorScheme[AppStrings.essentialColor],
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: fontMainFamily,
                    color: colorScheme[AppStrings.secondaryColor],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
