/*
 * Fecha de creación: 2025-04-26
 * Autor: KingdomOfJames
 * 
 * Descripción:
 * Esta clase `ConversationReference` es responsable de obtener la referencia de una conversación entre dos usuarios en Firebase. 
 * Utiliza los apodos o "nicknames" de los usuarios para construir dos posibles identificadores de conversación y verificar cuál de ellos 
 * ya existe en la base de datos de Firebase. Esto permite que la aplicación obtenga la conversación correcta para los dos usuarios 
 * especificados, sin necesidad de crear múltiples conversaciones redundantes.
 *
 * Recomendaciones:
 * - Asegúrate de que los apodos de los usuarios sean únicos y válidos para evitar conflictos en los identificadores de las conversaciones.
 * - Considera agregar un control adicional para verificar si ambos apodos existen antes de intentar obtener la referencia de la conversación.
 *
 * Características:
 * - Obtención de los "nicknames" de los usuarios mediante el servicio `NicknameService`.
 * - Generación de dos posibles rutas de conversación para cubrir ambas combinaciones de apodos.
 * - Verificación de la existencia de la conversación en Firebase.
 * - Optimización en el acceso a la base de datos mediante el uso de `limitToFirst(1)` para reducir la carga.
 */

import 'package:firebase_database/firebase_database.dart';
import 'get_nicknames.dart';

/// Clase que maneja la obtención de la referencia de una conversación entre dos usuarios.
class ConversationReference {
  /// Instancia de Firebase Database para realizar consultas a la base de datos.
  final DatabaseReference firebaseDb = FirebaseDatabase.instance.ref();

  /// Instancia del servicio para obtener los apodos (nicknames) de los usuarios.
  final NicknameService nicknameService =
      NicknameService(); // Crear una instancia del servicio

  /// Método que obtiene la referencia de la conversación entre dos usuarios.
  /// Devuelve la referencia de la conversación que ya existe en la base de datos.
  Future<DatabaseReference> getConversationReference(
    String userId, // ID del primer usuario
    String otherUserId, // ID del segundo usuario
  ) async {
    // Obtener los apodos (nicknames) de los dos usuarios usando el servicio correspondiente
    final nicknames = await nicknameService.getNicknames(
      userId, // ID del primer usuario
      otherUserId, // ID del segundo usuario
    );

    // Asignar los apodos de los dos usuarios a las variables correspondientes
    final myNickname = nicknames[0]; // Apodo del primer usuario
    final otherNickname = nicknames[1]; // Apodo del segundo usuario

    // Crear dos posibles identificadores de conversación utilizando los apodos
    final conversationId1 =
        "conversation $myNickname-$otherNickname"; // Primer formato de ID de conversación
    final conversationId2 =
        "conversation $otherNickname-$myNickname"; // Segundo formato de ID de conversación

    // Crear las referencias correspondientes en la base de datos de Firebase para cada ID
    final conversationRef1 = firebaseDb.child(conversationId1);
    final conversationRef2 = firebaseDb.child(conversationId2);

    // Verificar si la segunda referencia de conversación ya existe en la base de datos
    final snapshot = await conversationRef2.limitToFirst(1).once();

    // Si la referencia de conversación 2 existe, devolverla
    if (snapshot.snapshot.exists) {
      return conversationRef2;
    } else {
      // Si no existe, devolver la referencia de conversación 1
      return conversationRef1;
    }
  }
}
