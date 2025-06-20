// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción:
// Este código define un widget de barra de navegación inferior personalizada que
// se adapta a diferentes tipos de usuarios (Artistas o Contratistas). Según el
// tipo de usuario, los íconos de navegación mostrados en la barra cambiarán.
// Además, se utiliza la librería `go_router` para la navegación entre pantallas.
// Recomendaciones:
// 1. Asegúrate de tener configuradas correctamente las rutas en `GoRouter`
//    para que las transiciones entre pantallas funcionen sin problemas.
// 2. Personaliza los íconos y las rutas según los requisitos de tu aplicación.
// Características:
// - Muestra una barra de navegación con íconos de diferentes tamaños según el
//   tipo de usuario (artista o contratista).
// - Los íconos cambian de color cuando están seleccionados.
// - Permite la navegación entre diferentes pantallas de la aplicación.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:go_router/go_router.dart'; // Importa go_router

// Widget que representa la barra de navegación inferior
class BottomNavigationBarWidget extends StatelessWidget {
  final bool isArtist; // Define si el usuario es un artista o no
  final GoRouter goRouter; // Instancia de GoRouter para la navegación

  // Constructor que recibe el tipo de usuario y la instancia de goRouter
  const BottomNavigationBarWidget({
    Key? key,
    required this.isArtist,
    required this.goRouter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se obtiene el esquema de colores para usar en la UI
    final colorScheme = ColorPalette.getPalette(context);

    // Definición de los elementos de navegación, dependiendo si es un artista o no
    final items =
        isArtist
            ? [
              NavigationItem.home,
              NavigationItem.search,
              NavigationItem.message,
              NavigationItem.profileArtist,
            ]
            : [
              NavigationItem.home,
              NavigationItem.search,
              NavigationItem.favorites,
              NavigationItem.message,
              NavigationItem.profileContractor,
            ];

    // Construcción de la barra de navegación inferior
    return BottomNavigationBar(
      type:
          BottomNavigationBarType
              .fixed, // Configura la barra para que tenga íconos fijos
      backgroundColor:
          colorScheme[AppStrings.toolBarColor]?.withOpacity(1.0) ??
          Colors.grey, // Color de fondo de la barra
      selectedItemColor:
          colorScheme[AppStrings.essentialColor] ??
          Colors.red, // Color del ícono seleccionado
      unselectedItemColor:
          colorScheme[AppStrings.redColor] ??
          Colors.red, // Color del ícono no seleccionado
      currentIndex: 0, // Índice inicial
      showSelectedLabels: false, // Oculta las etiquetas de los íconos
      showUnselectedLabels:
          false, // Oculta las etiquetas de los íconos no seleccionados
      elevation: 8, // Elevación de la barra
      iconSize: 32, // Tamaño de los íconos
      items:
          items.map((item) {
            return BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.only(top: 8.0),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  item.iconPath, // Carga el ícono de la navegación
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    colorScheme[AppStrings.essentialColor] ??
                        Colors.white, // Color del ícono
                    BlendMode.srcIn, // Filtro de color para el ícono
                  ),
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.only(top: 8.0),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  item.iconPath, // Carga el ícono de la navegación
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    colorScheme[AppStrings.essentialColor] ??
                        Colors.red, // Color cuando está seleccionado
                    BlendMode
                        .srcIn, // Filtro de color para el ícono seleccionado
                  ),
                ),
              ),
              label: '', // No se muestra etiqueta, solo ícono
            );
          }).toList(),
      // Maneja el evento de clic en un ítem de la barra de navegación
      onTap: (index) {
        final route =
            items[index].route; // Obtiene la ruta del ítem seleccionado
        goRouter.go(route); // Navega a la ruta correspondiente
      },
    );
  }
}

// Clase que representa cada ítem de navegación
class NavigationItem {
  final String title; // Título del ítem
  final String iconPath; // Ruta del ícono SVG
  final String route; // Ruta de navegación

  const NavigationItem._(this.title, this.iconPath, this.route);

  // Definición de los ítems de navegación
  static const home = NavigationItem._(
    AppStrings.homeTitle,
    AppStrings.homeIconPath,
    AppStrings.homeRoute,
  );
  static const search = NavigationItem._(
    AppStrings.searchTitle,
    AppStrings.searchIconPath,
    AppStrings.searchRoute,
  );
  static const favorites = NavigationItem._(
    AppStrings.favoritesTitle,
    AppStrings.favoritesIconPath,
    AppStrings.favoritesRoute,
  );
  static const message = NavigationItem._(
    AppStrings.messageTitle,
    AppStrings.messageIconPath,
    AppStrings.messageRoute,
  );
  static const profileArtist = NavigationItem._(
    AppStrings.profileArtistTitle,
    AppStrings.profileArtistIconPath,
    AppStrings.profileArtistRoute,
  );
  static const profileContractor = NavigationItem._(
    AppStrings.profileContractorTitle,
    AppStrings.profileContractorIconPath,
    AppStrings.profileContractorRoute,
  );
}
