/*
  ------------------------------------------------------------
  Archivo: message_repository.dart
  Fecha de creación: 26 de abril de 2025
  Autor: KingdomOfJames

  Descripción de la pantalla:
  Esta clase es el repositorio de mensajería que maneja la lógica
  de almacenamiento, recuperación y sincronización de mensajes
  entre una base de datos local y Firebase Realtime Database.
  
  Características:
  - Obtiene los nicknames de los usuarios para construir las rutas de conversación.
  - Carga mensajes desde Firebase y los guarda localmente.
  - Permite eliminar todos los mensajes de una conversación.
  - Convierte entre entidades de base de datos locales y modelos de dominio.

  Recomendaciones:
  - Evitar uso de print en producción (cambiar por sistema de logs o Crashlytics).
  - Manejar excepciones específicas, no capturar genéricamente 'catch (e)'.
  - Implementar control de errores más robusto para conversiones de datos.
  - Considerar paginación para grandes cantidades de mensajes.

  ------------------------------------------------------------
*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../model/messages/message.dart';
import '../../sources/local/internal_data_base.dart';

/// Repositorio para manejar mensajes
class MessageRepository {
  late MessageDao messageDao; // DAO para acceso local a mensajes
  late DatabaseReference firebaseDb; // Referencia a Firebase Realtime Database
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance; // Instancia de Firestore

  /// Constructor del repositorio
  MessageRepository({required this.messageDao, required this.firebaseDb});

  /// Obtiene los nicknames de dos usuarios dados sus IDs
  Future<List<String>> getNicknames(String userId, String otherUserId) async {
    final senderDoc = await firestore.collection("users").doc(userId).get();
    final receiverDoc =
        await firestore.collection("users").doc(otherUserId).get();

    final String senderNickname = senderDoc.data()?["nickname"] ?? "Unknown";
    final String receiverNickname =
        receiverDoc.data()?["nickname"] ?? "Unknown";

    return [senderNickname, receiverNickname];
  }

  /// Obtiene la referencia de la conversación en Firebase
  Future<DatabaseReference> getConversationReference(
    String userId,
    String otherUserId,
  ) async {
    final nicknames = await getNicknames(userId, otherUserId);
    final myNickname = nicknames[0];
    final otherNickname = nicknames[1];

    final conversationId1 = "conversation $myNickname-$otherNickname";
    final conversationId2 = "conversation $otherNickname-$myNickname";

    final conversationRef1 = firebaseDb.child(conversationId1);
    final conversationRef2 = firebaseDb.child(conversationId2);

    // Se verifica si existe la segunda conversacion; si no, se usa la primera
    final snapshot = await conversationRef2.limitToFirst(1).once();
    if (snapshot.snapshot.exists) {
      return conversationRef2;
    } else {
      return conversationRef1;
    }
  }

  /// Elimina todos los mensajes entre dos usuarios
  Future<void> deleteAllMessages(String userId, String otherUserId) async {
    await messageDao.deleteAllMessages(userId, otherUserId);
  }

  /// Obtiene mensajes de la base de datos local por emisor y receptor
  Future<List<Message>> getMessagesBySenderAndReceiver(
    String senderId,
    String receiverId,
  ) async {
    final messageEntities = await messageDao.getMessagesBySenderAndReceiver(
      senderId,
      receiverId,
    );
    final messages = messageEntities.map((e) => e.toMessage()).toList();
    return messages;
  }

  /// Guarda una lista de mensajes en la base de datos local
  Future<void> saveMessagesToRoom(List<Message> messages) async {
    final messageEntities = messages.map((m) => m.toMessageEntity()).toList();
    await messageDao.insertAll(messageEntities);
  }

  /// Carga mensajes desde Firebase y los guarda localmente
  Future<List<Message>> loadMessagesFromFirebase(
    String userId,
    String otherUserId,
  ) async {
    try {
      final conversationRef = await getConversationReference(
        userId,
        otherUserId,
      );
      final snapshot = await conversationRef.get();

      final firebaseMessages = <Message>[];

      if (snapshot.exists) {
        final messagesMap = snapshot.value as Map<dynamic, dynamic>;
        messagesMap.forEach((key, value) {
          try {
            final messageData = Map<String, dynamic>.from(value);
            final message = Message(
              id: messageData['id'] ?? key.toString(),
              currentUserId: messageData['currentUserId'] ?? userId,
              type: messageData['type'] ?? 'text',
              messageText: messageData['message'] ?? '',
              senderId: messageData['senderId'] ?? userId,
              receiverId: messageData['receiverId'] ?? otherUserId,
              url: messageData['url'],
              timestamp:
                  messageData['timestamp'] is int
                      ? messageData['timestamp']
                      : int.tryParse(messageData['timestamp'].toString()) ??
                          DateTime.now().millisecondsSinceEpoch,
              messageRead: messageData['messageRead'] ?? false,
            );
            firebaseMessages.add(message);
          } catch (_) {
            // Se omite error individual de parseo para mayor robustez
          }
        });
      }

      await saveMessagesToRoom(firebaseMessages);

      return firebaseMessages;
    } catch (e) {
      // Error general en carga de mensajes
      rethrow;
    }
  }
}

/// Extensión que convierte de entidad local a modelo de dominio
extension on MessageEntity {
  Message toMessage() {
    return Message(
      id: id,
      currentUserId: '', // Se puede asignar correctamente al usar en contexto
      type: type,
      messageText: content,
      senderId: senderId,
      receiverId: receiverId,
      url: (type == 'image' || type == 'video') ? content : null,
      timestamp: timestamp,
      messageRead: messageRead,
    );
  }
}

/// Extensión que convierte de modelo de dominio a entidad local
extension on Message {
  MessageEntity toMessageEntity() {
    return MessageEntity(
      id: id,
      type: type,
      content: (type == 'image' || type == 'video') ? url ?? '' : messageText,
      senderId: senderId,
      receiverId: receiverId,
      timestamp: timestamp,
      messageRead: messageRead,
    );
  }
}
