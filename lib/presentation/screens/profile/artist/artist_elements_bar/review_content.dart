// Fecha de creación: 2025-04-26
// Autor: KingdomOfJames
// Descripción: Pantalla de reseñas que muestra la puntuación promedio, el número de reseñas, y una lista de comentarios de los usuarios.
// Recomendaciones:
// 1. Asegúrate de tener datos válidos para las reseñas al cargar esta pantalla.
// 2. Si la carga de reseñas es lenta, considera implementar paginación o una carga bajo demanda para mejorar el rendimiento.
// Características:
// - Muestra una puntuación promedio con iconos de estrellas.
// - Muestra un contador dinámico de reseñas usando un Stream.
// - Presenta una lista de reseñas con información sobre el autor y su puntuación.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/messages/messages_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../../../../../data/model/reviews/review.dart';
import '../../../../../data/provider_logics/user/user_provider.dart';
import '../../../../../data/provider_logics/user/review_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:live_music/presentation/resources/colors.dart';

class ReviewsContent extends StatefulWidget {
  final UserProvider userProvider;
  final ReviewProvider reviewProvider;
  final MessagesProvider messagesProvider;

  // Constructor que recibe los proveedores necesarios para cargar las reseñas y la información del usuario.
  const ReviewsContent({
    required this.userProvider,
    required this.reviewProvider,
    required this.messagesProvider,
    super.key,
  });

  @override
  State<ReviewsContent> createState() => _ReviewsContentState();
}

class _ReviewsContentState extends State<ReviewsContent> {
  List<Review> reviews = []; // Lista que contendrá las reseñas cargadas.
  StreamSubscription<int>?
  _reviewCountSubscription; // Suscripción al stream de conteo de reseñas.

  @override
  void initState() {
    super.initState();
    _loadReviews(); // Carga las reseñas al inicio.
    final userId = widget.userProvider.currentUserId;
    widget.reviewProvider.getAverageStars(
      userId,
    ); // Obtiene la puntuación promedio de reseñas.

    // Se suscribe al stream que proporciona el número actualizado de reseñas.
    _reviewCountSubscription = widget.messagesProvider
        .getReviewCountStream(userId)
        .listen((count) {
          if (mounted) {
            // Asegura que el widget esté montado antes de actualizar el estado.
            setState(() {
              widget.messagesProvider.reviewsNumber.value = count;
            });
          }
        });
  }

  @override
  void dispose() {
    _reviewCountSubscription
        ?.cancel(); // Cancela la suscripción al stream cuando el widget se destruye.
    super.dispose();
  }

  // Función para cargar las reseñas.
  void _loadReviews() {
    final userId = widget.userProvider.currentUserId;
    widget.reviewProvider.getReviews(userId, (result) {
      if (mounted) {
        setState(() {
          reviews =
              result; // Actualiza la lista de reseñas con los resultados obtenidos.
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene la paleta de colores.
    final reviewsNumber =
        widget
            .messagesProvider
            .reviewsNumber
            .value; // Número actual de reseñas.
    final averageScore =
        widget.reviewProvider.averageStars; // Puntuación promedio de reseñas.

    return Container(
      color:
          colorScheme['primaryColor'], // Establece el color de fondo principal.
      height:
          MediaQuery.of(
            context,
          ).size.height, // Ajusta la altura al tamaño de la pantalla.
      width: double.infinity, // Ajusta el ancho al máximo disponible.
      child:
          reviews
                  .isEmpty // Si no hay reseñas, muestra un mensaje.
              ? Column(
                children: [
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    child: Text(
                      AppStrings.noReviewsYet, // Mensaje cuando no hay reseñas.
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme['secondaryColor'],
                      ),
                    ),
                  ),
                ],
              )
              // Si hay reseñas, muestra la puntuación promedio y la lista de reseñas.
              : Column(
                children: [
                  // Sección que muestra la puntuación promedio y el número de reseñas.
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Puntuación promedio con icono de estrella.
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: colorScheme['essentialColor'],
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${AppStrings.averageScore} $averageScore',
                                style: TextStyle(
                                  fontFamily: 'CustomFontFamilyBold',
                                  color: colorScheme['secondaryColor'],
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Muestra el número de reseñas con un StreamBuilder que escucha los cambios.
                        StreamBuilder<int>(
                          stream: widget.messagesProvider.getReviewCountStream(
                            widget.userProvider.currentUserId,
                          ),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? reviewsNumber;
                            return Text(
                              count == 1
                                  ? "$count ${AppStrings.review}"
                                  : "$count ${AppStrings.reviews}",
                              style: TextStyle(
                                color: colorScheme['secondaryColor'],
                                fontSize: 18,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Lista de reseñas
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          children: [
                            for (final review in reviews)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: ReviewCard(
                                  review: review.toJson(),
                                  colorScheme: colorScheme,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final Map<String, Color> colorScheme;

  // Constructor de ReviewCard, recibe la reseña y la paleta de colores.
  const ReviewCard({required this.review, required this.colorScheme, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: colorScheme[AppStrings.primaryColorLight],
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            // Información del autor de la reseña.
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    review["senderProfileImageUrl"], // Foto del perfil del autor.
                  ),
                  radius: 22.5,
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review["senderName"], // Nombre del autor de la reseña.
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      // Muestra las estrellas de la reseña.
                      children: List.generate(
                        review["stars"] as int,
                        (index) => Icon(
                          Icons.star,
                          color: colorScheme[AppStrings.essentialColor],
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                review["text"], // Texto de la reseña.
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
