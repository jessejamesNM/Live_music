/*
 * Fecha de creación: 2025-04-26
 * Autor: KingdomOfJames
 * 
 * Descripción:
 * La clase `NicknameService` es responsable de obtener los apodos ("nicknames") de dos usuarios a partir de la base de datos de Firestore. 
 * Este servicio consulta los documentos de los usuarios en la colección "users" y extrae los valores correspondientes a los apodos. 
 * Si no se encuentra un apodo, se devuelve un valor por defecto ("Unknown").
 *
 * Recomendaciones:
 * - Verifica que los documentos de los usuarios existan y contengan los campos esperados antes de intentar acceder a ellos.
 * - Asegúrate de manejar correctamente posibles excepciones de conexión con Firestore.
 * - Considera agregar más validaciones para verificar la integridad de los datos antes de retornar los apodos.
 *
 * Características:
 * - Obtención de apodos de dos usuarios a partir de su ID en Firestore.
 * - Si no se encuentra un apodo, se devuelve un valor por defecto ("Unknown").
 * - Utiliza la colección "users" de Firestore y espera la respuesta asíncrona de la base de datos.
 */
import 'package:cloud_firestore/cloud_firestore.dart';

class NicknameService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance; // Instancia de Firestore

  // Método que obtiene los apodos de dos usuarios dados sus IDs
  Future<List<String>> getNicknames(String userId, String otherUserId) async {
    // Obtener los documentos de los usuarios desde Firestore
    final senderDoc = await firestore.collection("users").doc(userId).get();
    final receiverDoc =
        await firestore.collection("users").doc(otherUserId).get();

    // Obtener los apodos de los documentos de los usuarios
    // Si no se encuentra un apodo, se asigna el valor "Unknown" por defecto
    final String senderNickname = senderDoc.data()?["nickname"] ?? "Unknown";
    final String receiverNickname =
        receiverDoc.data()?["nickname"] ?? "Unknown";

    // Retornar los apodos en una lista
    return [senderNickname, receiverNickname];
  }
}
