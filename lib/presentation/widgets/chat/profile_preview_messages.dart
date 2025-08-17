/*
 * ────────────────────────────────────────────────────────────────────────
 * Fecha de creación: 26 de abril de 2025
 * Autor: KingdomOfJames
 *
 * Descripción general de la pantalla:
 * - Esta pantalla muestra una vista previa del perfil de un usuario o artista.
 * - Permite ver información básica como nombre, país, estado, última conexión y fecha de creación de la cuenta.
 * - Si el usuario es un artista, se ofrece un botón para ver su perfil completo.
 * - También muestra un resumen de las reseñas recibidas, con opción de ver todas.
 *
 * Recomendaciones:
 * - Cargar todos los datos antes de mostrar la pantalla para mejorar la UX.
 * - Considerar un controlador de estado (Riverpod, Bloc) si se vuelve muy dinámico.
 * - Optimizar para pantallas pequeñas (altura flexible).
 * - Evitar cargar datos directamente en el build si la lista crece mucho.

 * Características:
 * - Uso de `Provider` para cargar datos del usuario, reviews y mensajes.
 * - Animación de aparición con `AnimatedVisibility`.
 * - Integración con `GoRouter` para navegación a otras pantallas.
 * - Manejo de estado con `ValueListenableBuilder`.
 * - Diseño responsivo y adaptado al tema de la app.

 * Comentarios generales:
 * - El código está bien estructurado en cuanto a separación de responsabilidades.
 * - Es recomendable manejar la carga de datos de manera externa al build para escalar mejor.
 * - Algunos métodos como `_fetchReviews` podrían ser pasados a otro archivo para mayor limpieza.
 * - Excelente uso de componentes reutilizables (`ReviewCard`).
 * ────────────────────────────────────────────────────────────────────────
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/data/provider_logics/user/review_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/messages/messages_provider.dart';
import '../animated_visibility.dart';

// Pantalla principal de vista previa de perfil
class ProfilePreviewScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String? profileImageUrl;
  final bool artist;
  final bool isBottomSheetVisibleForProfile;
  final GoRouter goRouter;
  final MessagesProvider messagesProvider;

  const ProfilePreviewScreen({
    required this.userId,
    required this.userName,
    this.profileImageUrl,
    required this.artist,
    required this.isBottomSheetVisibleForProfile,
    required this.goRouter,
    required this.messagesProvider,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    // Proveedores para obtener datos
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final screenHeight = MediaQuery.of(context).size.height;

    // Cargar datos iniciales
    messagesProvider.loadUserData(userId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        alignment: Alignment.bottomCenter,
        child: AnimatedVisibility(
          visible: isBottomSheetVisibleForProfile,
          child: Container(
            height: screenHeight * 0.65,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme[AppStrings.primarySecondColor],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Cabecera del perfil (foto + nombre + nickname)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage:
                          profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null,
                      backgroundColor:
                          colorScheme[AppStrings.primaryColorLight],
                      child:
                          profileImageUrl == null
                              ? Icon(
                                Icons.person,
                                color: colorScheme[AppStrings.essentialColor],
                              )
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<String>(
                            valueListenable:
                                messagesProvider.userNameForProfilesPreview,
                            builder: (context, value, child) {
                              return Text(
                                value,
                                style: TextStyle(
                                  color: colorScheme[AppStrings.secondaryColor],
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          ValueListenableBuilder<String>(
                            valueListenable:
                                messagesProvider.nicknameForProfilesPreview,
                            builder: (context, value, child) {
                              return Text(
                                value,
                                style: TextStyle(
                                  color: colorScheme[AppStrings.secondaryColor],
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme[AppStrings.essentialColor],
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                Divider(
                  color: colorScheme[AppStrings.secondaryColor],
                  thickness: 2,
                ),

                // Información básica del usuario
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.information,
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        color: colorScheme[AppStrings.secondaryColor],
                        thickness: 1.5,
                      ),

                      // País y estado
                      ValueListenableBuilder<String>(
                        valueListenable: messagesProvider.userCountry,
                        builder: (context, country, child) {
                          return ValueListenableBuilder<String>(
                            valueListenable: messagesProvider.userState,
                            builder: (context, state, child) {
                              return ListTile(
                                leading: Icon(
                                  Icons.location_on,
                                  color: colorScheme[AppStrings.essentialColor],
                                  size: 25,
                                ),
                                title: Text(
                                  '${AppStrings.from}: $country, $state',
                                  style: TextStyle(
                                    color:
                                        colorScheme[AppStrings.secondaryColor],
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      Divider(
                        color: colorScheme[AppStrings.secondaryColor],
                        thickness: 1.5,
                      ),

                      // Última vez que usó la app
                      ValueListenableBuilder<String>(
                        valueListenable: messagesProvider.lastTimeAppUsing,
                        builder: (context, lastTime, child) {
                          return ListTile(
                            leading: Icon(
                              Icons.visibility,
                              color: colorScheme[AppStrings.essentialColor],
                              size: 25,
                            ),
                            title: Text(
                              '${AppStrings.lastTime}: $lastTime',
                              style: TextStyle(
                                color: colorScheme[AppStrings.secondaryColor],
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),

                      Divider(
                        color: colorScheme[AppStrings.secondaryColor],
                        thickness: 1.5,
                      ),

                      // Fecha de creación de la cuenta
                      ValueListenableBuilder<String>(
                        valueListenable: messagesProvider.accountCreationDate,
                        builder: (context, creationDate, child) {
                          return ListTile(
                            leading: Icon(
                              Icons.person,
                              color: colorScheme[AppStrings.essentialColor],
                              size: 25,
                            ),
                            title: Text(
                              '${AppStrings.accountCreatedOn}: $creationDate',
                              style: TextStyle(
                                color: colorScheme[AppStrings.secondaryColor],
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),

                      Divider(
                        color: colorScheme[AppStrings.secondaryColor],
                        thickness: 1.5,
                      ),
                    ],
                  ),
                ),

                // Botón para ver el perfil completo si es artista
                if (artist)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 14,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: colorScheme[AppStrings.secondaryColor],
                        backgroundColor: colorScheme[AppStrings.essentialColor],
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        userProvider.setOtherUserId(userId);
                        goRouter.push(AppStrings.profileArtistScreenWSRoute);
                      },
                      child: Text(AppStrings.viewFullProfile),
                    ),
                  ),

                Divider(
                  color: colorScheme[AppStrings.secondaryColor],
                  thickness: 1.5,
                ),
                const SizedBox(height: 14),

                // Sección de reseñas
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchReviews(reviewProvider, userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colorScheme[AppStrings.essentialColor],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          AppStrings.errorLoadingReviews,
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          AppStrings.noReviewsAvailable,
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                      );
                    } else {
                      final reviews = snapshot.data!;
                      return Column(
                        children: [
                          // Contador de reseñas
                          StreamBuilder<int>(
                            stream: messagesProvider.getReviewCountStream(
                              userId,
                            ),
                            builder: (context, countSnapshot) {
                              final reviewsCount = countSnapshot.data ?? 0;
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    reviewsCount == 1
                                        ? '$reviewsCount ${AppStrings.review}'
                                        : '$reviewsCount ${AppStrings.reviews}',
                                    style: TextStyle(
                                      color:
                                          colorScheme[AppStrings
                                              .secondaryColor],
                                      fontSize: 18,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (artist) {
                                        messagesProvider
                                            .setUserIdForReviewContentContractor(
                                              userId,
                                            );
                                        userProvider.setMenuSelection(
                                          AppStrings.reviewsContentWs,
                                        );
                                        userProvider.setOtherUserId(userId);
                                        goRouter.push(
                                          AppStrings.profileArtistScreenRoute,
                                        );
                                        userProvider.loadUserData(userId);
                                      } else {
                                        goRouter.push(
                                          AppStrings.reviewsScreenRoute,
                                        );
                                      }
                                    },
                                    child: Text(
                                      AppStrings.showAll,
                                      style: TextStyle(
                                        color:
                                            colorScheme[AppStrings
                                                .essentialColor],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          // Tarjetas individuales de reseñas
                          ...reviews
                              .map(
                                (review) => ReviewCard(
                                  review: review,
                                  colorScheme: colorScheme,
                                ),
                              )
                              .toList(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Método auxiliar para cargar las primeras tres reseñas del usuario
  Future<List<Map<String, dynamic>>> _fetchReviews(
    ReviewProvider reviewProvider,
    String userId,
  ) async {
    try {
      final reviews = await messagesProvider.getFirstThreeReviews(userId);
      return reviews;
    } catch (e) {
      throw e;
    }
  }
}

// Widget para mostrar cada reseña individual
class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final Map<String, Color> colorScheme;

  const ReviewCard({required this.review, required this.colorScheme, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: colorScheme[AppStrings.primaryColorLight],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          review['text'] ?? '',
          style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
        ),
      ),
    );
  }
}
