import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/beggining/option_card.dart';
import 'package:provider/provider.dart';


class WhatYouOfferScreen extends StatelessWidget {
  final GoRouter goRouter;

  const WhatYouOfferScreen({Key? key, required this.goRouter})
      : super(key: key);

  void _selectType(BuildContext context, String type) {
    context.read<UserProvider>().setUserType(type);
    goRouter.push(AppStrings.registerOptionsArtistRoute);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final fontMainFamily = AppStrings.bevietnamProRegular;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Fuente base para toda la pantalla (proporcional al ancho)
    final double baseFontSize = screenWidth * 0.045;

    // Dimensiones
    final double horizontalPadding = screenWidth * 0.05;
    final double spacing = screenWidth * 0.04;
    final double titleHeight = screenHeight * 0.08;
    final double cardWidth =
        (screenWidth - horizontalPadding * 2 - spacing) / 2;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            children: [
              // Botón regresar
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color:
                        colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                    size: screenWidth * 0.08,
                  ),
                  onPressed: () {
                    if (goRouter.canPop()) {
                      goRouter.pop();
                    } else {
                      goRouter.go(AppStrings.selectionScreenRoute);
                    }
                  },
                ),
              ),
              // Contenido scrollable
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Texto principal
                      SizedBox(
                        width: screenWidth,
                        height: titleHeight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "¿Qué servicio ofrece?",
                            style: TextStyle(
                              fontFamily: fontMainFamily,
                              color: colorScheme[AppStrings.secondaryColor],
                              fontWeight: FontWeight.w600,
                              fontSize: baseFontSize,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing),
                      // Wrap de opciones
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildOptionCard(context, "Soy Músico",
                              AppStrings.icMusicAsset, "artist", cardWidth, baseFontSize),
                          _buildOptionCard(context, "Repostería o Comida",
                              "assets/svg/reposteria.svg", "bakery", cardWidth, baseFontSize),
                          _buildOptionCard(context, "Local de eventos",
                              "assets/svg/eventplace.svg", "place", cardWidth, baseFontSize),
                          _buildOptionCard(context, "Decoraciones",
                              "assets/svg/decoration.svg", "decoration", cardWidth, baseFontSize),
                          _buildOptionCard(context, "Mobiliario",
                              "assets/svg/ic_furniture.svg", "furniture", cardWidth, baseFontSize),
                          _buildOptionCard(context, "Entretenimiento",
                              "assets/svg/ic_entertainment.svg", "entertainment", cardWidth, baseFontSize),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Botón iniciar sesión
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () =>
                              goRouter.push(AppStrings.loginOptionsScreenRoute),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 10, right: 5),
                            child: Text(
                              AppStrings.logIn,
                              style: TextStyle(
                                fontFamily: fontMainFamily,
                                color: colorScheme[AppStrings.secondaryColor],
                                fontSize: baseFontSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String text, String imageRes,
      String type, double cardWidth, double baseFontSize) {
    return SizedBox(
      width: cardWidth,
      height: cardWidth,
      child: OptionCard(
        text: text,
        imageRes: imageRes,
        onClick: () => _selectType(context, type),
        fontSize: baseFontSize,
      ),
    );
  }
}

class OptionCard extends StatelessWidget {
  final String text;
  final String imageRes;
  final VoidCallback onClick;
  final double fontSize;

  const OptionCard({
    Key? key,
    required this.text,
    required this.imageRes,
    required this.onClick,
    required this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontMainFamily = AppStrings.bevietnamProRegular;
    final colorScheme = ColorPalette.getPalette(context);

    return GestureDetector(
      onTap: onClick,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;

          return Card(
            color: colorScheme[AppStrings.primaryColorLight] ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(size * 0.12),
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 7,
                    child: SvgPicture.asset(
                      imageRes,
                      fit: BoxFit.contain,
                      width: size * 0.5,
                      height: size * 0.5,
                      color: colorScheme[AppStrings.essentialColor],
                    ),
                  ),
                  SizedBox(height: size * 0.05),
                  Expanded(
                    flex: 3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: fontMainFamily,
                          color: colorScheme[AppStrings.secondaryColor],
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize, // 🔑 Usamos el mismo tamaño global
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}