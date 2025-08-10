/// ==============================================================================
/// Fecha de creación: 26 de abril de 2025
/// Autor: KingdomOfJames
///
/// Descripción de la pantalla:
/// Este archivo define la paleta de colores para la aplicación en modo oscuro y modo claro.
/// Permite seleccionar dinámicamente los colores basados en el tema del dispositivo.
///
/// Características:
/// - Maneja dos conjuntos de colores: uno para modo oscuro y otro para modo claro.
/// - Proporciona una función centralizada para obtener la paleta adecuada según el contexto.
/// - Facilita el mantenimiento y la coherencia del diseño visual en toda la app.
///
/// Recomendaciones:
/// - Expandir las paletas si se agregan más elementos visuales personalizados.
/// - Considerar nombres más específicos para colores si se agregan muchos más.
/// - Optimizar para usar ThemeData de Flutter si se desea una integración aún más limpia.
///
/// ==============================================================================

import 'package:flutter/material.dart';

/// Clase que contiene los colores específicos para el Modo Oscuro.
class DarkModeColors {
  static const primaryColor = Color(0xFF000000); // Negro absoluto
  static const primaryColorLight = Color(
    0xFF111112,
  ); // Variante más clara del primario
  static const essentialColor = Color(0xFFB00000); // Rojo fuerte
  static const secondaryColor = Color(0xFFFFFFFF); // Blanco
  static const secondaryColorLight = Color.fromARGB(92, 255, 255, 255);
  static const secondaryColorLittleDark = Color(
    0x80FFFFFF,
  ); // Blanco con opacidad
  static const mainColorGray = Color(0xFF2C2C2C); // Gris oscuro
  static const toolBarColor = Color(0xFF0E0E0E); // Casi negro
  static const selectedButtonColor = Color(0xFF1C1C1C); // Gris muy oscuro
  static const primarySecondColor = Color(0xFF0A0A0A); // Negro casi absoluto
  static const correctGreen = Color(0xFF228B22); // Verde fuerte
  static const gray757 = Color(0xFF686868); // Gris medio
  static const redColor = Color(0xFFBA0707); // Rojo fuerte
  static const redColorLight = Color(0x99FF0000); // Rojo con transparencia
  static const blueColor = Color(0xFF005EFF); // Azul fuerte
}

/// Clase que contiene los colores específicos para el Modo Claro.
class LightModeColors {
  static const primaryColor = Color(0xFFFFFFFF); // Blanco absoluto
  static const primaryColorLight = Color.fromARGB(
    255,
    223,
    223,
    223,
  ); // Variante más oscura del blanco
  static const essentialColor = Color(0xFF1A1A1A); // Rojo más claro
  static const secondaryColor = Color(0xFF000000); // Negro para contraste
  static const secondaryColorLight = Color.fromARGB(141, 3, 3, 3);
  static const secondaryColorLittleDark = Color(
    0x80000000,
  ); // Negro con opacidad (50%)
  static const mainColorGray = Color(0xFFE0E0E0); // Gris claro
  static const toolBarColor = Color(0xFFF0F0F0); // Gris muy claro para barra
  static const selectedButtonColor = Color(
    0xFFD6D6D6,
  ); // Gris más notorio pero claro
  static const primarySecondColor = Color(0xFFFFFFFF); // Blanco
  static const correctGreen = Color(0xFF32CD32); // Verde más claro (LimeGreen)
  static const gray757 = Color(0xFFA0A0A0); // Gris claro equivalente
  static const redColor = Color(0xFFE53935); // Rojo claro
  static const redColorLight = Color(
    0x99FF8A80,
  ); // Rojo claro con transparencia
  static const blueColor = Color(0xFF4D90FE); // Azul claro
}

/// Clase que devuelve la paleta de colores según el tema activo (no solo por brillo).
class ColorPalette {
  /// Devuelve la paleta basada en el tema actual de la app (light/dark).
  static Map<String, Color> getPalette(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (brightness == Brightness.dark) {
      return {
        'secondaryColorLight': DarkModeColors.secondaryColorLight,
        'primaryColor': DarkModeColors.primaryColor,
        'primaryColorLight': DarkModeColors.primaryColorLight,
        'essentialColor': DarkModeColors.essentialColor,
        'secondaryColor': DarkModeColors.secondaryColor,
        'secondaryColorLittleDark': DarkModeColors.secondaryColorLittleDark,
        'mainColorGray': DarkModeColors.mainColorGray,
        'toolBarColor': DarkModeColors.toolBarColor,
        'selectedButtonColor': DarkModeColors.selectedButtonColor,
        'primarySecondColor': DarkModeColors.primarySecondColor,
        'correctGreen': DarkModeColors.correctGreen,
        'gray757': DarkModeColors.gray757,
        'redColor': DarkModeColors.redColor,
        'redColorLight': DarkModeColors.redColorLight,
        'blueColor': DarkModeColors.blueColor,
      };
    } else {
      return {
        'secondaryColorLight': LightModeColors.secondaryColorLight,
        'primaryColor': LightModeColors.primaryColor,
        'primaryColorLight': LightModeColors.primaryColorLight,
        'essentialColor': LightModeColors.essentialColor,
        'secondaryColor': LightModeColors.secondaryColor,
        'secondaryColorLittleDark': LightModeColors.secondaryColorLittleDark,
        'mainColorGray': LightModeColors.mainColorGray,
        'toolBarColor': LightModeColors.toolBarColor,
        'selectedButtonColor': LightModeColors.selectedButtonColor,
        'primarySecondColor': LightModeColors.primarySecondColor,
        'correctGreen': LightModeColors.correctGreen,
        'gray757': LightModeColors.gray757,
        'redColor': LightModeColors.redColor,
        'redColorLight': LightModeColors.redColorLight,
        'blueColor': LightModeColors.blueColor,
      };
    }
  }
}
