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
  static const primaryColor = Color(
    0xFF000000,
  ); // Color primario (negro absoluto)
  static const primaryColorLight = Color(
    0xFF111112,
  ); // Variante más clara del primario
  static const essentialColor = Color(
    0xFFB00000,
  ); // Color esencial (rojo fuerte)
  static const secondaryColor = Color(0xFFFFFFFF); // Color secundario (blanco)
  static const secondaryColorLittleDark = Color(
    0x80FFFFFF,
  ); // Blanco con opacidad (50%)
  static const mainColorGray = Color(0xFF2C2C2C); // Gris principal
  static const toolBarColor = Color(
    0xFF0E0E0E,
  ); // Color de la barra de herramientas
  static const selectedButtonColor = Color(
    0xFF1C1C1C,
  ); // Color para botón seleccionado
  static const primarySecondColor = Color(0xFF0A0A0A); // Segundo color primario
  static const correctGreen = Color(0xFF228B22); // Verde para indicar correcto
  static const gray757 = Color(0xFF686868); // Gris más suave
  static const redColor = Color(0xFFBA0707); // Rojo para advertencias o errores
  static const redColorLight = Color(0x99FF0000); // Rojo con transparencia
  static const blueColor = Color(0xFF005EFF); // Azul principal
}

/// Clase que contiene los colores específicos para el Modo Claro.
/// Actualmente reutiliza los mismos valores que DarkModeColors,
/// lo que sugiere que puede expandirse o personalizarse en el futuro.
class LightModeColors {
  static const primaryColor = Color(0xFF000000);
  static const primaryColorLight = Color(0xFF111112);
  static const essentialColor = Color(0xFFB00000);
  static const secondaryColor = Color(0xFFFFFFFF);
  static const secondaryColorLittleDark = Color(0x80FFFFFF);
  static const mainColorGray = Color(0xFF2C2C2C);
  static const toolBarColor = Color(0xFF0E0E0E);
  static const selectedButtonColor = Color(0xFF1C1C1C);
  static const primarySecondColor = Color(0xFF0A0A0A);
  static const correctGreen = Color(0xFF228B22);
  static const gray757 = Color(0xFF686868);
  static const redColor = Color(0xFFBA0707);
  static const redColorLight = Color(0x99FF0000);
  static const blueColor = Color(0xFF005EFF);
}

/// Clase utilitaria que selecciona dinámicamente la paleta de colores
/// adecuada dependiendo del modo actual del dispositivo (oscuro o claro).
class ColorPalette {
  /// Obtiene la paleta de colores basándose en el brillo del dispositivo.
  ///
  /// Devuelve un mapa (`Map<String, Color>`) que contiene los nombres de los colores
  /// como claves y sus valores correspondientes.
  static Map<String, Color> getPalette(BuildContext context) {
    var brightness =
        MediaQuery.of(
          context,
        ).platformBrightness; // Detecta si es modo oscuro o claro.

    if (brightness == Brightness.dark) {
      // Retorna la paleta de modo oscuro.
      return {
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
      // Retorna la paleta de modo claro.
      return {
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
