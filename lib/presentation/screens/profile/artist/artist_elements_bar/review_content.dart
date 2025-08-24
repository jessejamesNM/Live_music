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
import 'package:firebase_auth/firebase_auth.dart';
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
  List<Review> reviews = [];
  StreamSubscription<int>? _reviewCountSubscription;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    widget.reviewProvider.getAverageStars(userId);

    _reviewCountSubscription =
        widget.messagesProvider.getReviewCountStream(userId).listen((count) {
      if (mounted) {
        setState(() {
          widget.messagesProvider.reviewsNumber.value = count;
        });
      }
    });
  }

  @override
  void dispose() {
    _reviewCountSubscription?.cancel();
    super.dispose();
  }

  void _loadReviews() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    widget.reviewProvider.getReviews(userId, (result) {
      if (mounted) {
        setState(() {
          reviews = result;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final reviewsNumber = widget.messagesProvider.reviewsNumber.value;
    final averageScore = widget.reviewProvider.averageStars;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final padding = screenWidth * 0.04;
    final iconSize = screenWidth * 0.06;
    final titleFontSize = screenWidth * 0.05;
    final subtitleFontSize = screenWidth * 0.045;
    final textFontSize = screenWidth * 0.04;
    final reviewPadding = screenWidth * 0.03;

    return Container(
      color: colorScheme['primaryColor'],
      height: screenHeight,
      width: double.infinity,
      child: reviews.isEmpty
          ? Column(
              children: [
                SizedBox(height: screenHeight * 0.02),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppStrings.noReviewsYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: colorScheme['secondaryColor'],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: colorScheme['essentialColor'],
                              size: iconSize,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${AppStrings.averageScore} $averageScore',
                                style: TextStyle(
                                  fontFamily: 'CustomFontFamilyBold',
                                  color: colorScheme['secondaryColor'],
                                  fontSize: titleFontSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: widget.messagesProvider.getReviewCountStream(
                            FirebaseAuth.instance.currentUser?.uid ?? ''),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? reviewsNumber;
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              count == 1
                                  ? "$count ${AppStrings.review}"
                                  : "$count ${AppStrings.reviews}",
                              style: TextStyle(
                                color: colorScheme['secondaryColor'],
                                fontSize: subtitleFontSize,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Column(
                        children: reviews
                            .map((review) => Padding(
                                  padding: EdgeInsets.only(bottom: reviewPadding),
                                  child: ReviewCard(
                                    review: review.toJson(),
                                    colorScheme: colorScheme,
                                    screenWidth: screenWidth,
                                  ),
                                ))
                            .toList(),
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
  final double screenWidth;

  const ReviewCard({
    required this.review,
    required this.colorScheme,
    required this.screenWidth,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconSize = screenWidth * 0.05;
    final nameFontSize = screenWidth * 0.045;
    final textFontSize = screenWidth * 0.04;
    final paddingSize = screenWidth * 0.03;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: colorScheme[AppStrings.primaryColorLight],
      child: Padding(
        padding: EdgeInsets.all(paddingSize),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    review["senderProfileImageUrl"] ?? '',
                  ),
                  radius: iconSize * 1.1,
                ),
                SizedBox(width: screenWidth * 0.02),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        review["senderName"] ?? '',
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                          fontSize: nameFontSize,
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        review["stars"] ?? 0,
                        (index) => Icon(
                          Icons.star,
                          color: colorScheme[AppStrings.essentialColor],
                          size: iconSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.02),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                review["text"] ?? '',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor],
                  fontSize: textFontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
