// Fecha de creación: 26/04/2025
// Author: KingdomOfJames
//
// Descripción:
// Esta pantalla muestra las reseñas de un contratista en la aplicación. La interfaz
// permite al usuario ver información básica sobre el contratista, como su nombre y
// foto de perfil, además de listar las reseñas asociadas a su perfil.
// Se hace uso de un `ValueListenableBuilder` para gestionar el estado reactivo de
// la imagen del perfil, y se incorpora un `BottomNavigationBar` para la navegación
// entre pantallas.
//
// Recomendaciones:
// - Asegurarse de que el `userProvider`, `reviewProvider` y `messagesProvider`
//   se inyecten correctamente desde el árbol de widgets superiores.
// - Mantener el uso adecuado de `ValueListenableBuilder` para evitar la reconstrucción
//   innecesaria de toda la pantalla cuando solo cambia una parte del estado.
// - Utilizar iconos de tamaño adecuado para garantizar una experiencia de usuario
//   consistente y visualmente agradable.
//
// Características:
// - Visualización de las reseñas del contratista.
// - Foto de perfil con respaldo en caso de que no esté disponible.
// - Navegación mediante `BottomNavigationBar`.
// - Título de la pantalla "Reseñas" con icono de retroceso.
// - Manejo de estado reactivo con `ValueListenableBuilder`.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/screens/search_fun/profile_artist_ws/menuComponents/review_content_ws.dart';
import '../../../../data/provider_logics/nav_buttom_bar_components/messages/messages_provider.dart';
import '../../../../data/provider_logics/user/user_provider.dart';
import '../../../../data/provider_logics/user/review_provider.dart';
import '../../buttom_navigation_bar.dart';

class ReviewsContractorScreen extends StatelessWidget {
  final GoRouter goRouter;
  final UserProvider userProvider;
  final ReviewProvider reviewProvider;
  final MessagesProvider messagesProvider;

  ReviewsContractorScreen({
    required this.goRouter,
    required this.userProvider,
    required this.reviewProvider,
    required this.messagesProvider,
  });

  @override
  Widget build(BuildContext context) {
    // Tamaño de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final otherUserId = messagesProvider.userIdForProfilePreview;
    final profileImageUrlNotifier =
        messagesProvider.profileImageUrlForProfilesPreview;
    final userType = userProvider.userType;
    final isArtist = userType == AppStrings.artist;
    final colorScheme = ColorPalette.getPalette(context);
    final userName = messagesProvider.userNameForProfilesPreview;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
        userType: userType,
      ),
      body: Container(
        color: Colors.black,
        padding: EdgeInsets.all(screenWidth * 0.04), // padding relativo
        child: Column(
          children: [
            // Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: colorScheme[AppStrings.secondaryColor],
                    size: screenWidth * 0.07, // tamaño relativo
                  ),
                  onPressed: () {
                    context.pop();
                  },
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppStrings.reviewsTitle,
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: screenWidth * 0.065, // tamaño relativo
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.12), // espacio proporcional
              ],
            ),
            SizedBox(height: screenHeight * 0.015),
            // Perfil
            ValueListenableBuilder<String?>(
              valueListenable: profileImageUrlNotifier,
              builder: (context, profileImageUrl, child) {
                return Row(
                  children: [
                    profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(profileImageUrl),
                            radius: screenWidth * 0.09,
                          )
                        : Container(
                            width: screenWidth * 0.18,
                            height: screenWidth * 0.18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  colorScheme[AppStrings.primaryColorLight],
                            ),
                            child: SvgPicture.asset(
                              AppStrings.defaultUserImagePath,
                              fit: BoxFit.scaleDown,
                              width: screenWidth * 0.1,
                              height: screenWidth * 0.1,
                              color: colorScheme[AppStrings.essentialColor],
                            ),
                          ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          userName.value,
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor],
                            fontSize: screenWidth * 0.06,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: screenHeight * 0.01),
            // Contenido de reseñas
            Expanded(
              child: ReviewsContentWS(otherUserId: otherUserId.value),
            ),
          ],
        ),
      ),
    );
  }
}