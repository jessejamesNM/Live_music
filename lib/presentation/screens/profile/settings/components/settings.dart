// Fecha de creación: 2025-04-26
// Autor: KingdomOfJames
//
// Descripción:
// Este componente representa una serie de opciones de configuración para un usuario.
// La pantalla muestra botones de navegación hacia pantallas específicas, como "Mi Cuenta",
// "Cuentas Bloqueadas", "Idioma", entre otras. Los botones tienen iconos, texto y un
// diseño adaptativo con un divisor entre cada uno. También maneja mensajes emergentes
// (snackbars) cuando ciertas opciones están en desarrollo.
//
// Características:
// - Cada opción tiene un icono y texto asociados, con un comportamiento específico al presionar.
// - Diseño adaptativo, los tamaños de los iconos y texto se ajustan proporcionalmente.
// - Uso de un SnackBar para notificar al usuario cuando una función está en desarrollo.
// - Dependencia de `GoRouter` para la navegación entre pantallas.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform;
class SettingsComponent extends StatelessWidget {
  final GoRouter router;
  final Color? textColor;

  const SettingsComponent({super.key, required this.router, this.textColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final defaultTextColor =
        textColor ?? colorScheme[AppStrings.secondaryColor];
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double buttonHeight = screenHeight * 0.075;
    double iconSize = screenWidth * 0.08;
    double fontSize = screenWidth * 0.045;
    double paddingSide = screenWidth * 0.04;
    double dividerThickness = screenHeight * 0.001;
    double chevronSize = screenWidth * 0.06;

    return Container(
      color: colorScheme[AppStrings.primaryColor],
      child: Column(
        children: [
          _buildButton(
            height: buttonHeight,
            iconPath: AppStrings.inviteFriendsIconPath,
            text: AppStrings.inviteFriends,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            iconSize: iconSize,
            fontSize: fontSize,
            chevronSize: chevronSize,
            sidePadding: paddingSide,
            onPressed: () => _shareApp(context),
          ),
          _buildDivider(colorScheme, dividerThickness),
          _buildButton(
            height: buttonHeight,
            iconPath: AppStrings.defaultUserImagePath,
            text: AppStrings.myAccount,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            iconSize: iconSize,
            fontSize: fontSize,
            chevronSize: chevronSize,
            sidePadding: paddingSide,
            onPressed: () => router.push(AppStrings.myAccountScreenRoute),
          ),
          _buildDivider(colorScheme, dividerThickness),
          _buildButton(
            height: buttonHeight,
            iconPath: AppStrings.blockedAccountsIconPath,
            text: AppStrings.blockedAccountsTitle,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            iconSize: iconSize,
            fontSize: fontSize,
            chevronSize: chevronSize,
            sidePadding: paddingSide,
            onPressed: () => router.push(AppStrings.blockedAccountsRoute),
          ),
          _buildDivider(colorScheme, dividerThickness),
          _buildButton(
            height: buttonHeight,
            iconPath: AppStrings.languageIconPath,
            text: AppStrings.language,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            iconSize: iconSize,
            fontSize: fontSize,
            chevronSize: chevronSize,
            sidePadding: paddingSide,
            onPressed: () => _showInDevelopmentSnackbar(context, colorScheme),
          ),
          _buildDivider(colorScheme, dividerThickness),
          _buildButton(
            height: buttonHeight,
            iconPath: AppStrings.appearanceIconPath,
            text: AppStrings.appearance,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            iconSize: iconSize * 1.07,
            fontSize: fontSize,
            chevronSize: chevronSize,
            sidePadding: paddingSide,
            onPressed: () => router.push(AppStrings.themeSettingsRoute),
          ),
          _buildDivider(colorScheme, dividerThickness),
          _buildButton(
            height: buttonHeight,
            iconPath: AppStrings.suggestionsIconPath,
            text: AppStrings.suggestions,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            iconSize: iconSize * 1.02,
            fontSize: fontSize,
            chevronSize: chevronSize,
            sidePadding: paddingSide,
            onPressed: () => router.push(AppStrings.suggestionsRoute),
          ),
          _buildDivider(colorScheme, dividerThickness),
          _buildButton(
            height: buttonHeight,
            iconPath: AppStrings.helpIconPath,
            text: AppStrings.help,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            iconSize: iconSize,
            fontSize: fontSize,
            chevronSize: chevronSize,
            sidePadding: paddingSide,
            onPressed: () => router.push(AppStrings.helpRoute),
          ),
          _buildDivider(colorScheme, dividerThickness),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context) {
    String androidUrl =
        'https://play.google.com/store/apps/details?id=com.jesse.live_music';
    String iosUrl = 'https://apps.apple.com/app/id6747364802';
    String message = '''
¡Descarga la app My Events y descubre nuevas experiencias musicales! 🎶✨  

📱 Para Android: $androidUrl  
🍏 Para iPhone: $iosUrl
''';

    Share.share(message);
  }

  Widget _buildDivider(Map<String, Color?> colorScheme, double thickness) {
    return Divider(
      color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.2),
      thickness: thickness,
      height: thickness * 12,
    );
  }

  void _showInDevelopmentSnackbar(
      BuildContext context, Map<String, Color?> colorScheme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.inDevelopment,
          style: TextStyle(color: colorScheme[AppStrings.primaryColor]),
        ),
        backgroundColor: colorScheme[AppStrings.secondaryColor],
      ),
    );
  }

  Widget _buildButton({
    required double height,
    required String iconPath,
    required String text,
    required VoidCallback onPressed,
    required Color? textColor,
    required Color? iconColor,
    required double iconSize,
    required double fontSize,
    required double chevronSize,
    required double sidePadding,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: sidePadding),
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: SvgPicture.asset(
                  iconPath,
                  colorFilter: ColorFilter.mode(
                    iconColor ?? Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: sidePadding),
              child: Icon(Icons.chevron_right, size: chevronSize),
            ),
          ],
        ),
      ),
    );
  }
}
