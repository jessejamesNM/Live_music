import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final cardWidth = (screenWidth - 60) / 2;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Botón de regresar alineado a la izquierda
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color:
                            colorScheme[AppStrings.secondaryColor] ??
                            Colors.black,
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

                  // Mosaico de opciones con el texto integrado
                  Expanded(
                    child: Center(
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          // Texto como un card más
                          SizedBox(
                            width:
                                screenWidth -
                                40, // Ancho completo menos padding
                            height: 60, // Altura reducida
                            child: Center(
                              child: Text(
                                "¿Qué servicio ofrece?",
                                style: TextStyle(
                                  fontFamily: fontMainFamily,
                                  color: colorScheme[AppStrings.secondaryColor],
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            height: cardWidth,
                            child: OptionCard(
                              text: AppStrings.iAmMusician,
                              imageRes: AppStrings.icMusicAsset,
                              onClick: () => _selectType(context, 'artist'),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            height: cardWidth,
                            child: OptionCard(
                              text: 'Repostería o Comida',
                              imageRes: 'assets/svg/reposteria.svg',
                              onClick: () => _selectType(context, 'bakery'),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            height: cardWidth,
                            child: OptionCard(
                              text: 'Local de eventos',
                              imageRes: 'assets/svg/eventplace.svg',
                              onClick: () => _selectType(context, 'place'),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            height: cardWidth,
                            child: OptionCard(
                              text: 'Decoraciones',
                              imageRes: 'assets/svg/decoration.svg',
                              onClick: () => _selectType(context, 'decoration'),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            height: cardWidth,
                            child: OptionCard(
                              text: 'Mueblería',
                              imageRes: 'assets/svg/ic_furniture.svg',
                              onClick: () => _selectType(context, 'furniture'),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            height: cardWidth,
                            child: OptionCard(
                              text: 'Entretenimiento',
                              imageRes: 'assets/svg/ic_entertainment.svg',
                              onClick:
                                  () => _selectType(context, 'entertainment'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Botón "Iniciar sesión"
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onTap:
                      () => goRouter.push(AppStrings.loginOptionsScreenRoute),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10, right: 5),
                    child: Text(
                      AppStrings.logIn,
                      style: TextStyle(
                        fontFamily: fontMainFamily,
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
