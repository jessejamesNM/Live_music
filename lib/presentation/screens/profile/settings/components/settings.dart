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
    final baseButtonHeight = screenHeight * 0.075;

    double proportionalSize(double originalSize) =>
        (originalSize / 60) * baseButtonHeight;

    return Container(
      color: colorScheme[AppStrings.primaryColor],
      child: Column(
        children: [
          _buildButton(
            baseHeight: baseButtonHeight,
            iconPath: AppStrings.inviteFriendsIconPath,
            text: AppStrings.inviteFriends,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            originalIconSize: 32,
            onPressed: () => _shareApp(context),
            proportionalSize: proportionalSize,
          ),
          _buildDivider(colorScheme, proportionalSize),
          _buildButton(
            baseHeight: baseButtonHeight,
            iconPath: AppStrings.defaultUserImagePath,
            text: AppStrings.myAccount,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            originalIconSize: 34,
            onPressed: () => router.push(AppStrings.myAccountScreenRoute),
            proportionalSize: proportionalSize,
          ),
          _buildDivider(colorScheme, proportionalSize),
          _buildButton(
            baseHeight: baseButtonHeight,
            iconPath: AppStrings.blockedAccountsIconPath,
            text: AppStrings.blockedAccountsTitle,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            originalIconSize: 35,
            onPressed: () => router.push(AppStrings.blockedAccountsRoute),
            proportionalSize: proportionalSize,
          ),
          _buildDivider(colorScheme, proportionalSize),
          _buildButton(
            baseHeight: baseButtonHeight,
            iconPath: AppStrings.languageIconPath,
            text: AppStrings.language,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            originalIconSize: 35,
            onPressed: () => _showInDevelopmentSnackbar(context, colorScheme),
            proportionalSize: proportionalSize,
          ),
          _buildDivider(colorScheme, proportionalSize),
          _buildButton(
            baseHeight: baseButtonHeight,
            iconPath: AppStrings.appearanceIconPath,
            text: AppStrings.appearance,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            originalIconSize: 43,
            onPressed:
                () => router.push(
                  AppStrings.themeSettingsRoute,
                ), // Actualizado para navegar a la pantalla de tema
            proportionalSize: proportionalSize,
          ),
          _buildDivider(colorScheme, proportionalSize),
          _buildButton(
            baseHeight: baseButtonHeight,
            iconPath: AppStrings.suggestionsIconPath,
            text: AppStrings.suggestions,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            originalIconSize: 37,
            onPressed: () => router.push(AppStrings.suggestionsRoute),
            proportionalSize: proportionalSize,
          ),
          _buildDivider(colorScheme, proportionalSize),
          _buildButton(
            baseHeight: baseButtonHeight,
            iconPath: AppStrings.helpIconPath,
            text: AppStrings.help,
            textColor: defaultTextColor,
            iconColor: defaultTextColor,
            originalIconSize: 32,
            onPressed: () => router.push(AppStrings.helpRoute),
            proportionalSize: proportionalSize,
          ),
          _buildDivider(colorScheme, proportionalSize),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context) {
    String androidUrl =
        'https://play.google.com/store/apps/details?id=com.jesse.live_music';
    String iosUrl = 'https://apps.apple.com/app/id6747364802';
    String message =
        '¡Descarga la app my events y descubre nuevas experiencias musicales! \n\n${Platform.isAndroid ? androidUrl : iosUrl}';

    Share.share(message);
  }

  Widget _buildDivider(
    Map<String, Color?> colorScheme,
    double Function(double) proportionalSize,
  ) {
    return Divider(
      color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.2),
      thickness: proportionalSize(0.8),
      height: proportionalSize(1),
    );
  }

  void _showInDevelopmentSnackbar(
    BuildContext context,
    Map<String, Color?> colorScheme,
  ) {
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
    required double baseHeight,
    required String iconPath,
    required String text,
    required VoidCallback onPressed,
    required Color? textColor,
    required Color? iconColor,
    required double originalIconSize,
    required double Function(double) proportionalSize,
  }) {
    return SizedBox(
      width: double.infinity,
      height: baseHeight,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: proportionalSize(16)),
              child: SizedBox(
                width: proportionalSize(originalIconSize),
                height: proportionalSize(originalIconSize),
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
                    fontSize: proportionalSize(16),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: proportionalSize(16)),
              child: Icon(Icons.chevron_right, size: proportionalSize(24)),
            ),
          ],
        ),
      ),
    );
  }
}
