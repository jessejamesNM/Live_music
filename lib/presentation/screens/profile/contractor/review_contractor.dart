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
    // Se obtiene el ID del usuario que está visualizando el perfil y la URL de la imagen de perfil
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
        isArtist: isArtist,
      ),
      body: Container(
        color: Colors.black, // Se establece el color de fondo de la pantalla
        padding: const EdgeInsets.all(16), // Espaciado general
        child: Column(
          children: [
            // Fila de cabecera con icono de retroceso y título de la pantalla
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color del icono
                  ),
                  onPressed: () {
                    context.pop(); // Volver a la pantalla anterior
                  },
                ),
                Text(
                  AppStrings.reviewsTitle, // Título de la pantalla
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                    fontSize: 26,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 10),
            // Muestra la imagen del perfil y el nombre del usuario
            ValueListenableBuilder<String?>(
              valueListenable: profileImageUrlNotifier,
              builder: (context, profileImageUrl, child) {
                return Row(
                  children: [
                    // Si hay una URL de imagen, se muestra en un avatar circular, si no, se muestra una imagen por defecto
                    profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? CircleAvatar(
                          backgroundImage: NetworkImage(profileImageUrl),
                          radius: 35,
                        )
                        : Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme[AppStrings.primaryColorLight],
                          ),
                          child: SvgPicture.asset(
                            AppStrings.defaultUserImagePath,
                            fit: BoxFit.scaleDown,
                            width: 40,
                            height: 40,
                            color: colorScheme[AppStrings.essentialColor],
                          ),
                        ),
                    const SizedBox(width: 8),
                    // Nombre del usuario visualizado
                    Text(
                      userName.value,
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: 24,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 5),
            // Contenido de las reseñas, donde se pasan las referencias necesarias
            Expanded(child: ReviewsContentWS(otherUserId: otherUserId.value)),
          ],
        ),
      ),
    );
  }
}
