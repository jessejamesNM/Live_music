import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  int stars;
  final String senderId;
  final String receiverId;
  final String text;
  int timestamp;
  final String date;
  final String senderProfileImageUrl;
  final String senderName;

  Review({
    required this.id,
    this.stars = 0,
    this.senderId = "",
    this.receiverId = "",
    this.text = "",
    int? timestamp,
    this.date = "",
    this.senderProfileImageUrl = "",
    this.senderName = "",
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  // Constructor para crear un Review desde un Map
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      stars: json['stars'] ?? 0,
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      date: json['date'] ?? '',
      senderProfileImageUrl: json['senderProfileImageUrl'] ?? '',
      senderName: json['senderName'] ?? '',
    );
  }

  // Constructor para crear un Review desde un documento Firestore
  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      stars: data['stars'] ?? 0,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      date: data['date'] ?? '',
      senderProfileImageUrl: data['senderProfileImageUrl'] ?? '',
      senderName: data['senderName'] ?? '',
    );
  }

  // Convertir un objeto Review a un Map que se puede almacenar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stars': stars,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'date': date,
      'senderProfileImageUrl': senderProfileImageUrl,
      'senderName': senderName,
    };
  }

  // Convertir el objeto Review a un Map para subir a Firestore
  Map<String, dynamic> toFirestore() {
    return toJson(); // El formato de almacenamiento en Firestore es el mismo
  }
}
