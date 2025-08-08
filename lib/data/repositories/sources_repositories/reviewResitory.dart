/// ==============================================================================
/// Fecha de creación: 26 de abril de 2025
/// Autor: KingdomOfJames
///
/// Descripción de la pantalla:
/// Esta clase `ReviewRepository` gestiona las operaciones relacionadas con las
/// revisiones (reviews) de usuarios. Sincroniza datos entre Firestore (nube)
/// y una base de datos local mediante DAO (Data Access Object).
///
/// Características:
/// - Verificar si una revisión existe localmente.
/// - Obtener revisiones desde Firestore y guardarlas localmente.
/// - Obtener revisiones desde la base de datos local.
/// - Guardar nuevas revisiones localmente.
/// - Eliminar revisiones tanto localmente como en Firestore.
///
/// Recomendaciones:
/// - Evitar exponer errores detallados en consola en producción.
/// - Implementar manejo de errores más robusto (ej.: mostrar Snackbars o mensajes de error controlados).
/// - Validar la estructura de los documentos de Firestore antes de mapearlos.
///
/// ==============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../sources/local/internal_data_base.dart';

class ReviewRepository {
  final ReviewDao reviewDao; // Acceso a la base de datos local
  final FirebaseFirestore
  firestore; // Acceso a la base de datos en la nube (Firestore)

  ReviewRepository({required this.reviewDao, required this.firestore});

  /// Verificar si una revisión ya existe en la base de datos local.
  /// Útil para evitar duplicados.
  Future<bool> doesReviewExist(String receiverId, String senderId) async {
    final review = await reviewDao.getReviewByReceiverAndSender(
      receiverId,
      senderId,
    );
    return review != null;
  }

  /// Obtener todas las revisiones desde Firestore para un receptor específico
  /// y guardarlas en la base de datos local.
  Future<void> fetchAndSaveReviewsFromFirestore(String receiverId) async {
    try {
      // Referencia a las revisiones del receptor en Firestore
      final reviewsRef = firestore
          .collection("reviews")
          .doc(receiverId)
          .collection("Reviews");

      // Obtener todos los documentos (revisiones)
      final snapshot = await reviewsRef.get();

      // Convertir cada documento a un ReviewEntity local
      final reviews =
          snapshot.docs.map((document) {
            final review = ReviewEntity(
              id: document.id,
              senderId: document['senderId'],
              receiverId: document['receiverId'],
              senderName: document['senderName'],
              senderProfileImageUrl: document['senderProfileImageUrl'],
              stars: document['stars'],
              text: document['text'],
              timestamp: document['timestamp'],
              date: document['date'],
            );
            return review;
          }).toList();

      // Insertar o actualizar cada revisión en la base de datos local
      for (var review in reviews) {
        await reviewDao.insertOrUpdate(review);
      }
    } catch (e) {
      // Error manejado de manera silenciosa para no exponer detalles sensibles
      // En producción se recomienda usar un sistema de logs controlados o reportes de error
    }
  }

  /// Obtener todas las revisiones locales de un receptor.
  Future<List<ReviewEntity>> getReviewsFromRoom(String receiverId) async {
    return await reviewDao.getReviewsByReceiver(receiverId);
  }

  /// Guardar una revisión en la base de datos local.
  Future<void> saveReviewToRoom(ReviewEntity review) async {
    await reviewDao.insertOrUpdate(review);
  }

  /// Eliminar una revisión de la base de datos local y también de Firestore.
  Future<void> deleteReview(String reviewId, String receiverId) async {
    // Primero eliminar de la base de datos local
    await reviewDao.deleteReviewById(reviewId);

    // Luego eliminar de Firestore
    await firestore
        .collection("reviews")
        .doc(receiverId)
        .collection("Reviews")
        .doc(reviewId)
        .delete();
  }
}
