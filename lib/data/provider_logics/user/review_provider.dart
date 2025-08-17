// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
//
// Descripción:
// Esta clase `ReviewProvider` es responsable de gestionar las reseñas de usuarios en la aplicación.
// Permite la creación, actualización, eliminación y obtención de reseñas, así como la verificación de si
// un usuario ha dejado una reseña a otro. También calcula el promedio de estrellas y escucha los cambios
// en las reseñas en tiempo real.
//
// Recomendaciones:
// - Asegúrate de que la clase `ReviewRepository` esté bien implementada, ya que es crucial para el almacenamiento
//   y recuperación de las reseñas de la base de datos.
// - Es recomendable que la lógica de presentación y la lógica de negocio (como la manipulación de reseñas)
//   se mantengan separadas. Este código maneja la lógica de negocio de manera eficiente.
//
// Características:
// - Maneja las reseñas entre dos usuarios en una aplicación.
// - Permite obtener el promedio de estrellas de un usuario.
// - Soporta la creación, actualización y eliminación de reseñas.
// - Escucha en tiempo real los cambios en las reseñas de un usuario.
// - Utiliza Firebase Firestore para almacenar y recuperar datos.
// - Integra una capa de lógica de negocio que interactúa con una base de datos a través de `ReviewRepository`.
// - Permite actualizar reseñas solo después de un día desde la última modificación.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/reviews/review.dart';
import '../../repositories/sources_repositories/reviewResitory.dart';
import '../../sources/local/internal_data_base.dart';

class ReviewProvider with ChangeNotifier {
  late ReviewRepository reviewRepository;

  ReviewProvider({required this.reviewRepository});

  StreamSubscription<QuerySnapshot>? reviewListener;
  List<Review> _reviews = [];
  List<Review> get reviews => _reviews;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _myReviewExist = false;
  bool get myReviewExist => _myReviewExist;

  double _averageStars = 0.0;
  double get averageStars => _averageStars;

  // Verifica si el usuario ha dejado una reseña a otro usuario
  void checkIfMyReviewExists(String currentUserId, String otherUserId) async {
    _myReviewExist = await reviewRepository.doesReviewExist(
      otherUserId,
      currentUserId,
    );
    notifyListeners();
  }

  // Elimina una reseña específica
  void deleteReview(String reviewId, String receiverId) async {
    await reviewRepository.deleteReview(reviewId, receiverId);
  }

  // Calcula el promedio de estrellas de un usuario basado en las reseñas que tiene
  void getAverageStars(String? receiverId) {
    if (receiverId == null || receiverId.isEmpty) {
      _averageStars = 0.0;
      notifyListeners();
      return;
    }

    try {
      final reviewsRef = FirebaseFirestore.instance
          .collection("reviews")
          .doc(receiverId)
          .collection("Reviews");

      reviewsRef
          .get()
          .then((querySnapshot) {
            final totalStars = querySnapshot.docs.fold<int>(0, (int sum, doc) {
              try {
                final stars = doc.get('stars');
                if (stars is int) {
                  return sum + stars;
                } else if (stars is double) {
                  return sum + stars.round();
                } else if (stars is num) {
                  return sum + stars.toInt();
                }
                return sum;
              } catch (e) {
                return sum;
              }
            });

            final reviewCount = querySnapshot.size;
            _averageStars = reviewCount > 0 ? (totalStars / reviewCount) : 0.0;
            notifyListeners();
          })
          .catchError((_) {
            _averageStars = 0.0;
            notifyListeners();
          });
    } catch (e) {
      _averageStars = 0.0;
      notifyListeners();
    }
  }

  // Obtiene las primeras tres reseñas de un usuario
  void getFirstThreeReviews(
    String userId,
    Function(List<Map<String, dynamic>>) onSuccess,
    Function(Exception) onFailure,
  ) {
    if (userId.isEmpty) {
      onSuccess([]);
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final reviewsRef = firestore
        .collection("reviews")
        .doc(userId)
        .collection("Reviews");

    reviewsRef
        .limit(3)
        .get()
        .then((querySnapshot) {
          final reviews = querySnapshot.docs.map((doc) => doc.data()).toList();
          onSuccess(reviews);
        })
        .catchError((error) {
          if (error.toString().contains("not-found")) {
            onSuccess([]);
          } else {
            onFailure(error);
          }
        });
  }

  // Envía una nueva reseña de un usuario a otro
  void sendReview(int stars, String text, String senderId, String receiverId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final date = dateFormat.format(DateTime.now());
    final firestore = FirebaseFirestore.instance;
    final reviewsRef = firestore.collection("reviews").doc(receiverId);
    final senderRef = firestore.collection("users").doc(senderId);

    senderRef
        .get()
        .then((senderDoc) {
          if (senderDoc.exists) {
            final senderName = senderDoc.get('name') ?? 'Unknown';
            final senderProfileImageUrl =
                senderDoc.get('profileImageUrl') ?? '';

            reviewsRef.set({'placeholder': true}, SetOptions(merge: true));
            final reviewData = {
              'stars': stars,
              'senderId': senderId,
              'receiverId': receiverId,
              'text': text,
              'timestamp': timestamp,
              'date': date,
              'lastUpdate': timestamp,
              'senderName': senderName,
              'senderProfileImageUrl': senderProfileImageUrl,
            };

            reviewsRef
                .collection('Reviews')
                .add(reviewData)
                .then((_) {
                  checkIfMyReviewExists(senderId, receiverId);
                })
                .catchError((error) {
                  print("$error");
                });
          } else {
            print("");
          }
        })
        .catchError((error) {
          print("$error");
        });
  }

  // Actualiza una reseña existente
  void updateReview(
    String reviewId,
    String newText,
    int newStars,
    String receiverId,
    Function(bool, String) onResult,
  ) {
    final firestore = FirebaseFirestore.instance;
    final reviewRef = firestore
        .collection("reviews")
        .doc(receiverId)
        .collection("Reviews")
        .doc(reviewId);
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    reviewRef
        .get()
        .then((doc) {
          if (doc.exists) {
            final lastUpdate = doc.get('lastUpdate') ?? 0;
            final timeDifference = currentTime - lastUpdate;
            final oneDayInMillis = 24 * 60 * 60 * 1000;

            if (timeDifference >= oneDayInMillis) {
              reviewRef
                  .update({
                    'text': newText,
                    'stars': newStars,
                    'lastUpdate': currentTime,
                  })
                  .then((_) {
                    onResult(true, "Review updated successfully");
                  })
                  .catchError((error) {
                    onResult(false, "Error updating review");
                  });
            } else {
              onResult(
                false,
                "You have already modified the review, wait to do it again",
              );
            }
          } else {
            onResult(false, "Review document not found for update");
          }
        })
        .catchError((error) {
          onResult(false, "Error checking review document");
        });
  }

  // Obtiene todas las reseñas de un usuario
  Future<void> getReviews(
    String receiverId,
    Function(List<Review>) onResult,
  ) async {
    try {
      final reviewsRef = firestore
          .collection('reviews')
          .doc(receiverId)
          .collection('Reviews');

      final querySnapshot = await reviewsRef.get();

      final reviews =
          querySnapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();

      onResult(reviews);
    } catch (e) {
      print('Error getting reviews: $e');
      onResult([]);
    }
  }

  Future<List<ReviewEntity>> getReviewsFromRoom(String receiverId) async {
    return reviewRepository.getReviewsFromRoom(receiverId);
  }

  Review toReview(ReviewEntity reviewEntity) {
    return Review(
      id: reviewEntity.id,
      stars: reviewEntity.stars,
      senderId: reviewEntity.senderId,
      receiverId: reviewEntity.receiverId,
      text: reviewEntity.text,
      timestamp: reviewEntity.timestamp,
      date: reviewEntity.date,
      senderName: reviewEntity.senderName,
      senderProfileImageUrl: reviewEntity.senderProfileImageUrl,
    );
  }

  // Escucha los cambios en las reseñas de un usuario en tiempo real
  void listenForReviewChanges(String otherUserId) {
    reviewListener?.cancel();

    final firestore = FirebaseFirestore.instance;
    final reviewsRef = firestore
        .collection("reviews")
        .doc(otherUserId)
        .collection("Reviews");

    reviewListener = reviewsRef.snapshots().listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          reviewRepository.fetchAndSaveReviewsFromFirestore(otherUserId).then((
            _,
          ) async {
            final updatedReviews = await reviewRepository.getReviewsFromRoom(
              otherUserId,
            );
            _reviews = updatedReviews.map((e) => toReview(e)).toList();
            notifyListeners();
          });
        }
      },
      onError: (error) {
        print(" $error");
      },
    );
  }

  // Actualiza la lista de reseñas cuando cambia la base de datos
  void updateReviews(List<ReviewEntity> reviewEntities) {
    _reviews = reviewEntities.map((e) => toReview(e)).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    reviewListener?.cancel();
    super.dispose();
  }
}
