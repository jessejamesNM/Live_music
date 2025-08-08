// ============================================================================
// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
//
// Descripción:
// Este código gestiona la lógica de mensajería para una aplicación,
// utilizando Firebase para la autenticación de usuarios y Firestore para almacenar
// información relacionada con los mensajes. Incluye funcionalidades para manejar
// la selección de imágenes, la actualización de perfiles, la comprobación de la
// ubicación actual del usuario y la interacción con las fechas de disponibilidad.
// Además, ofrece un sistema para bloquear/desbloquear usuarios y gestionar
// la visibilidad de las notificaciones.
//
// Recomendaciones:
// - Asegúrese de que el sistema de permisos de ubicación esté correctamente
// configurado para evitar problemas de acceso a la ubicación del usuario.
// - Verifique que las dependencias de Firebase estén correctamente instaladas
// y configuradas en el proyecto.
// - Controle el uso de la memoria cuando se manejen archivos grandes como
// imágenes, ya que puede afectar el rendimiento de la aplicación.
//
// Características:
// - Autenticación de usuario mediante Firebase Auth.
// - Almacenamiento de mensajes y otros datos en Firebase Firestore.
// - Selección y visualización de imágenes del perfil de usuario.
// - Manejo de la ubicación del usuario y opción de compartirla.
// - Funcionalidad de bloqueo/desbloqueo de usuarios.
// - Visibilidad de notificaciones y actualizaciones de estados.
// =============================================================================

import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:live_music/data/model/messages/conversation_copy_with.dart';
import 'package:live_music/presentation/widgets/chat/map_preview_chat.dart';
import 'dart:async';
import '../../../model/messages/conversation_temp_data.dart';
import '../../../model/messages/message.dart';
import '../../../repositories/render_http_client/images/upload_message_image.dart';
import '../../../repositories/sources_repositories/messageRepository.dart';
import '../../../sources/local/internal_data_base.dart';
import '../widgets/get_conversation_reference.dart'; // Asegúrate de ajustar el nombre del paquete y la ruta según tu proyecto
import 'package:logging/logging.dart';
import '../widgets/utils/pair.dart';
import 'package:live_music/presentation/resources/strings.dart';
class MessagesProvider extends ChangeNotifier {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final conversationReference = ConversationReference();
  late MessageRepository messageRepository;

  MessagesProvider({required this.messageRepository});

  final Logger logger = Logger('FirebaseListener');

  final Map<String, StreamSubscription> _activeListeners = {};
  final ValueNotifier<String> _notificationUserToken = ValueNotifier<String>(
    "",
  );

  ValueNotifier<String> get notificationUserToken => _notificationUserToken;

  // Estado para los IDs de los mensajes
  final ValueNotifier<List<String>> _messageIds = ValueNotifier<List<String>>(
    [],
  );

  ValueNotifier<List<String>> get messageIds => _messageIds;

  // Referencias a Firebase
  final DatabaseReference db = FirebaseDatabase.instance.ref();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final Future<AppDatabase> roomDb = AppDatabase.getInstance();
  final ValueNotifier<File?> _selectedImageFile = ValueNotifier<File?>(null);

  ValueNotifier<File?> get selectedImageFile => _selectedImageFile;

  void updateSelectedImageFile(File file) {
    _selectedImageFile.value = file;
  }

  void clearSelectedImageFile() {
    _selectedImageFile.value = null;
  }

  ValueNotifier<bool> _isBottomSheetVisibleForProfile = ValueNotifier<bool>(
    false,
  );

  ValueNotifier<bool> get isBottomSheetVisibleForProfile =>
      _isBottomSheetVisibleForProfile;

  final ValueNotifier<bool> _hasMessages = ValueNotifier<bool>(false);
  final ValueNotifier<String> _usernameForContractorReviewContent =
      ValueNotifier<String>("");

  ValueNotifier<String> get usernameForContractorReviewContent =>
      _usernameForContractorReviewContent;

  void setUsernameForContractorReviewContent(String username) {
    _usernameForContractorReviewContent.value = username;
  }

  ValueNotifier<bool> get hasMessages => _hasMessages;

  final ValueNotifier<String?> _profileImageUrlForProfilesPreview =
      ValueNotifier<String?>(null);

  final ValueNotifier<String?> _userIdForReviewContentContractor =
      ValueNotifier<String?>(null);
  ValueNotifier<String?> get userIdForReviewContentContractor =>
      _userIdForReviewContentContractor;
  void setUserIdForReviewContentContractor(String? userId) {
    _userIdForReviewContentContractor.value = userId;
  }

  ValueNotifier<String?> get profileImageUrlForProfilesPreview =>
      _profileImageUrlForProfilesPreview;

  final ValueNotifier<String> _userNameForProfilesPreview =
      ValueNotifier<String>("");

  ValueNotifier<String> get userNameForProfilesPreview =>
      _userNameForProfilesPreview;

  final ValueNotifier<String> _nicknameForProfilesPreview =
      ValueNotifier<String>("");

  ValueNotifier<String> get nicknameForProfilesPreview =>
      _nicknameForProfilesPreview;

  final ValueNotifier<String> _userCountry = ValueNotifier<String>("");

  ValueNotifier<String> get userCountry => _userCountry;

  final ValueNotifier<String> _userIdForProfilePreview = ValueNotifier<String>(
    "",
  );

  ValueNotifier<String> get userIdForProfilePreview => _userIdForProfilePreview;

  final ValueNotifier<String> _userState = ValueNotifier<String>("");

  ValueNotifier<String> get userState => _userState;

  final ValueNotifier<String> _lastTimeAppUsing = ValueNotifier<String>("");

  ValueNotifier<String> get lastTimeAppUsing => _lastTimeAppUsing;

  final ValueNotifier<String> _accountCreationDate = ValueNotifier<String>("");

  ValueNotifier<String> get accountCreationDate => _accountCreationDate;

  final ValueNotifier<int> _reviewsNumber = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  ValueNotifier<bool> get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading.value = value;
  }

  ValueNotifier<int> get reviewsNumber => _reviewsNumber;

  // Estado para los mensajes
  final ValueNotifier<List<dynamic>> _messages = ValueNotifier<List<dynamic>>(
    [],
  );

  ValueNotifier<List<dynamic>> get messages => _messages;

  final ValueNotifier<bool> _isArtist = ValueNotifier<bool>(false);

  ValueNotifier<bool> get isArtist => _isArtist;
  Future<void> saveBusyDays(
    String userId,
    List<DateTime> busyDays,
    VoidCallback onComplete,
  ) async {
    final userRef = firestore.collection("users").doc(userId);

    // Convertir DateTime a String para guardar en Firestore
    final busyDaysString =
        busyDays.map((date) => DateFormat('yyyy-MM-dd').format(date)).toList();

    // Actualizar Firestore con la lista completa
    await userRef
        .update({"busyDays": busyDaysString})
        .then((_) {
          onComplete();
        })
        .catchError((exception) {});
  }

  Future<void> loadBusyDays(
    String userId,
    Function(List<DateTime>) onComplete,
  ) async {
    final userRef = firestore.collection("users").doc(userId);

    await userRef
        .get()
        .then((document) {
          if (document.exists) {
            // Convertir List<String> a List<DateTime>
            final busyDaysString = List<String>.from(
              document.get("busyDays") ?? [],
            );
            final busyDays =
                busyDaysString
                    .map((date) => DateFormat('yyyy-MM-dd').parse(date))
                    .toList();
            onComplete(busyDays);
          } else {
            onComplete([]);
          }
        })
        .catchError((exception) {
          print("$exception");
          onComplete([]);
        });
  }

  Future<void> loadProfileImage(
    String otherUserId,
    Function(String?) callback,
  ) async {
    if (otherUserId.isNotEmpty) {
      try {
        var db = FirebaseFirestore.instance;
        var userRef = db.collection("users").doc(otherUserId);
        var document = await userRef.get();

        if (document.exists) {
          final data = document.data();
          final profileImageUrl = data?["profileImageUrl"] as String?;
          callback(profileImageUrl);
        } else {
          callback(null);
        }
      } catch (e) {
        debugPrint("$e");
        callback(null);
      }
    } else {
      callback(null);
    }
  }

  Future<void> updateArtistName(
    String otherUserId,
    Function(String) callback,
  ) async {
    if (otherUserId.isNotEmpty) {
      try {
        var db = FirebaseFirestore.instance;
        var userRef = db.collection("users").doc(otherUserId);
        var document = await userRef.get();

        callback(document.get("name") ?? "Nombre no disponible");
      } catch (e) {
        callback("Error al obtener el nombre");
      }
    }
  }

  Future<File?> pickMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickMedia(imageQuality: 85);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  void checkOnlineStatusAndBlock(
    String otherUserId,
    Function(bool, bool) callback,
  ) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      // No hay usuario autenticado, manejar este caso según necesites
      callback(false, true); // Por ejemplo, considerar como offline y bloqueado
      return;
    }

    var firestore = FirebaseFirestore.instance;

    firestore.collection("users").doc(otherUserId).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final blockedUsersRaw = data?["blockedUsers"];
        List<dynamic> blockedUsers = [];

        if (blockedUsersRaw is List) {
          blockedUsers = blockedUsersRaw;
        }

        callback(
          data?["userUsingApp"] ?? false,
          blockedUsers.contains(currentUserId),
        );
      }
    });

    firestore.collection("users").doc(currentUserId).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        // Puedes manejar actualizaciones del usuario actual aquí si es necesario
      }
    });
  }

  Future<void> getCurrentLocationForChat(
    MessagesProvider provider,
    Function(Map<String, double>?) callback,
  ) async {
    final location = await provider.getCurrentLocation();
    callback(location);
  }

  void showLocationBottomSheetModal(
    BuildContext context,
    double latitude,
    double longitude,
    Map<String, Color?> colorScheme,
    VoidCallback onSend,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme[AppStrings.primaryColor],
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme[AppStrings.primaryColor],
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.shareLocationQuestion,
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme[AppStrings.secondaryColor],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme[AppStrings.essentialColor]!,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: MapPreviewChat(
                    latitude: latitude,
                    longitude: longitude,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppStrings.cancel,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme[AppStrings.essentialColor],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: onSend,
                    child: Text(
                      AppStrings.send,
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  void cancelAllActiveListeners() {
    _activeSubscriptions.forEach((_, sub) => sub.cancel());
    _activeSubscriptions.clear();
  }

  void clearAllConversations() {
    _messages.value = []; // Limpiar la lista de mensajes/conversaciones
    notifyListeners();
  }

  Future<void> unblockUser(String currentUserId, String userIdToUnblock) async {
    final db = FirebaseFirestore.instance;

    // Create a batch to perform both operations atomically
    final batch = db.batch();

    // Reference to current user's document
    final currentUserRef = db.collection('users').doc(currentUserId);

    // Remove blocked user from current user's blockedUsers list
    batch.update(currentUserRef, {
      'blockedUsers': FieldValue.arrayRemove([userIdToUnblock]),
    });

    // Reference to the user being unblocked
    final unblockedUserRef = db.collection('users').doc(userIdToUnblock);

    // Remove current user from unblocked user's usersWhoBlockedMe list
    batch.update(unblockedUserRef, {
      'usersWhoBlockedMe': FieldValue.arrayRemove([currentUserId]),
    });

    // Commit the batch
    await batch.commit();
  }

  Stream<int> getReviewCountStream(String userId) {
    return firestore
        .collection("reviews")
        .doc(userId)
        .collection("Reviews")
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<List<Map<String, dynamic>>> getFirstThreeReviews(String userId) async {
    final completer = Completer<List<Map<String, dynamic>>>();

    try {
      final querySnapshot =
          await firestore
              .collection("reviews")
              .doc(userId)
              .collection("Reviews")
              .orderBy('timestamp', descending: true)
              .limit(3)
              .get();

      final reviews =
          querySnapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();

      completer.complete(reviews);
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  void updateProfilePreview(
    String? profileImageUrl,
    String userName,
    String nickname,
  ) {
    _profileImageUrlForProfilesPreview.value = profileImageUrl;
    _userNameForProfilesPreview.value = userName;
    _nicknameForProfilesPreview.value = nickname;
  }

  Future<void> checkIfMessagesExist(String userId, String otherUserId) async {
    // Add 'await' to resolve the Future from getConversationReference
    final conversationRef = await messageRepository.getConversationReference(
      userId,
      otherUserId,
    );
    // Now conversationRef is the actual reference object, not a Future
    final snapshot = await conversationRef.get();
    _hasMessages.value = snapshot.children.any((child) {
      return child.child("senderId").value == otherUserId;
    });
  }

  // Método para obtener la ubicación actual
  Future<Map<String, double>?> getCurrentLocation() async {
    // Verificar permisos
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // El servicio de ubicación no está habilitado
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permisos denegados
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permisos denegados permanentemente
      return null;
    }

    // Obtener la ubicación actual
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Alta precisión
      );

      // Devolver la latitud y longitud como un Map
      return {'latitude': position.latitude, 'longitude': position.longitude};
    } catch (e) {
      // Manejar errores
      print("$e");
      return null;
    }
  }

  void loadUserData(String userId) {
    firestore.collection("users").doc(userId).get().then((document) {
      if (document.exists) {
        _userCountry.value = document.get("country") ?? "Desconocido";
        _userState.value = document.get("state") ?? "Desconocido";
        _userIdForProfilePreview.value = userId;

        final accountCreationTimestamp =
            document.get("accountCreationDate") as Timestamp?;
        _accountCreationDate.value =
            accountCreationTimestamp != null
                ? DateFormat(
                  "dd/MM/yy",
                ).format(accountCreationTimestamp.toDate())
                : "Desconocido";

        _userNameForProfilesPreview.value =
            document.get("name") ?? "Desconocido";

        final lastTimeAppUsingTimestamp =
            document.get("lastTimeAppUsing") as Timestamp?;
        _lastTimeAppUsing.value =
            lastTimeAppUsingTimestamp != null
                ? formatLastTimeAppUsing(lastTimeAppUsingTimestamp.toDate())
                : "No disponible";

        // 💡 Aquí se obtiene el nickname
        _nicknameForProfilesPreview.value =
            document.get("nickname") ?? "Sin nickname";

        // 🖼️ Aquí se obtiene la URL de la imagen de perfil
        _profileImageUrlForProfilesPreview.value = document.get(
          "profileImageUrl",
        );
      }
    });
  }

  String formatLastTimeAppUsing(DateTime lastDate) {
    final now = DateTime.now();
    final difference = now.difference(lastDate);

    final isSameDay =
        now.year == lastDate.year &&
        now.month == lastDate.month &&
        now.day == lastDate.day;

    if (isSameDay) {
      // Fue hoy → solo hora
      return DateFormat("hh:mm a", 'es_MX').format(lastDate);
    } else if (difference.inDays < 7) {
      // Dentro de la última semana → día de la semana y hora
      final dayName = DateFormat.EEEE('es_MX').format(lastDate);
      final hour = DateFormat("hh:mm a", 'es_MX').format(lastDate);
      return "$dayName, $hour";
    } else {
      // Más de una semana → solo fecha
      return DateFormat("dd/MM/yy").format(lastDate);
    }
  }

  void onChangeArtist(bool artist) {
    _isArtist.value = artist;
  }

  void toggleBottomSheetVisibility(bool artist) {
    _isArtist.value = artist;
    _isBottomSheetVisibleForProfile.value =
        !_isBottomSheetVisibleForProfile.value;
  }

  Stream<List<Conversation>> get conversations async* {
    if (currentUserId == null) {
      yield [];
    } else {
      final db = await roomDb;
      yield* db.conversationDao.getConversationsByCurrentUserId(currentUserId!);
    }
  }

  Map<String, List<Message>> groupMessagesByDay(List<Message> messages) {
    final Map<String, List<Message>> groupedMessages = {};
    final dateFormat = DateFormat("yyyy-MM-dd");

    for (final message in messages) {
      final day = dateFormat.format(
        DateTime.fromMillisecondsSinceEpoch(message.timestamp),
      );
      groupedMessages.putIfAbsent(day, () => []).add(message);
    }
    return groupedMessages;
  }

  List<dynamic> createOrderedListWithDaySeparators(List<Message> messages) {
    // Agrupar los mensajes por día
    final groupedMessages = groupMessagesByDay(messages);

    // Crear la lista ordenada con separadores de día
    final orderedList = <dynamic>[];
    final today = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dayOfWeekFormat = DateFormat('EEEE', 'es_ES');

    // Ordenar los días de forma descendente
    final sortedDays =
        groupedMessages.keys.toList()..sort((a, b) => b.compareTo(a));

    for (final day in sortedDays) {
      final messagesOfDay = groupedMessages[day]!;

      // Parsear la fecha del día actual
      final messageDate = DateFormat('yyyy-MM-dd').parse(day);

      // Determinar el texto del separador de día
      final dayLabel =
          isSameDay(today, messageDate)
              ? 'Hoy'
              : isYesterday(today, messageDate)
              ? 'Ayer'
              : isWithinLastWeek(today, messageDate)
              ? dayOfWeekFormat.format(messageDate)
              : dateFormat.format(messageDate);

      // Ordenar los mensajes del día por timestamp de forma descendente
      final sortedMessagesOfDay =
          messagesOfDay.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Agregar primero los mensajes y luego el separador
      orderedList.addAll(sortedMessagesOfDay);
      orderedList.add(dayLabel);
    }

    return orderedList;
  }

  bool isYesterday(DateTime today, DateTime other) {
    final yesterday = today.subtract(Duration(days: 1));
    return isSameDay(yesterday, other);
  }

  bool isWithinLastWeek(DateTime today, DateTime other) {
    final oneWeekAgo = today.subtract(Duration(days: 7));
    return other.isAfter(oneWeekAgo) && other.isBefore(today);
  }

  void addMessageAndSort(Message message) {
    _messages.value = createOrderedListWithDaySeparators([
      ..._messages.value.whereType<Message>(),
      message,
    ]);
  }

  void loadMessagesFromRoom(String senderId, String receiverId) {
    messageRepository
        .getMessagesBySenderAndReceiver(senderId, receiverId)
        .then((messages) {
          _messages.value = createOrderedListWithDaySeparators(messages);
          notifyListeners();
        })
        .catchError((e) {
          _messages.value = [];
          notifyListeners();
        });
  }

  Future<void> getFcmToken(String otherUserId) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();

      if (docSnapshot.exists) {
        _notificationUserToken.value =
            docSnapshot.data()?['fcmToken'] as String? ?? "";
      } else {
        _notificationUserToken.value = "";
      }
    } catch (e) {
      print('$e');
      _notificationUserToken.value = "";
    }
  }

  @override
  void dispose() {
    _activeListeners.forEach((_, sub) => sub.cancel());
    _activeListeners.clear();
    super.dispose();
  }

  void deleteAllMessages(String userId, String otherUserId) async {
    try {
      // Borrar mensajes de Firebase
      final conversationRef = await conversationReference
          .getConversationReference(userId, otherUserId);
      final collectionPath = conversationRef.path;
      final collectionRef = FirebaseFirestore.instance.collection(
        collectionPath,
      );
      final snapshot = await collectionRef.get();

      for (final doc in snapshot.docs) {
        await collectionRef.doc(doc.id).delete();
      }

      // Borrar mensajes de Room
      await messageRepository.messageDao.deleteAllMessages(userId, otherUserId);
    } catch (e) {
      print('Error al eliminar mensajes: $e');
    }
  }

  void syncMessagesWithFirebase(String userId, String otherUserId) async {
    try {
      // Assuming messageRepository is available and has loadMessagesFromFirebase method
      await messageRepository.loadMessagesFromFirebase(userId, otherUserId);
    } catch (e) {
      print('$e');
    }
  }

  Future<void> setupFirebaseListener(String userId, String otherUserId) async {
    cancelSpecificListener(userId, otherUserId);
    try {
      final startTimestamp = DateTime.now().millisecondsSinceEpoch;
      final conversationRef = await conversationReference
          .getConversationReference(userId, otherUserId);
      setupListenerForPath(
        conversationRef,
        startTimestamp,
        userId,
        otherUserId,
      );
    } catch (e) {
      logger.severe('Error al configurar el listener: $e');
    }
  }

  void setupListenerForPath(
    DatabaseReference conversationRef,
    int startTimestamp,
    String userId,
    String otherUserId,
  ) {
    // Streams sin suscribir
    final streamAdd =
        conversationRef
            .orderByChild('timestamp')
            .startAt(startTimestamp.toDouble())
            .onChildAdded;

    final streamChange =
        conversationRef
            .orderByChild('timestamp')
            .startAt(startTimestamp.toDouble())
            .onChildChanged;

    // 1) Crea el group
    final group = StreamGroup<DatabaseEvent>();
    // 2) Añade los streams
    group.add(streamAdd);
    group.add(streamChange);
    // 3) Suscríbete a su stream combinado
    final subscription = group.stream.listen(
      (event) {
        handleMessageSnapshot(
          event.snapshot,
          userId,
          otherUserId,
          conversationRef,
        );
      },
      onError: (e) {
        logger.severe('Error en merged listener: $e');
      },
    );

    _activeListeners['${userId}_$otherUserId'] = subscription;
  }

  void handleMessageSnapshot(
    DataSnapshot snapshot,
    String userId,
    String otherUserId,
    DatabaseReference conversationRef,
  ) async {
    // Mapeo manual de campos desde Firebase
    final message = Message(
      id: snapshot.key ?? "", // Usar el key de Firebase como ID único
      currentUserId: userId,
      type: snapshot.child("type").value as String? ?? "",
      messageText: snapshot.child("message").value as String? ?? "",
      senderId: snapshot.child("senderId").value as String? ?? "",
      receiverId: snapshot.child("receiverId").value as String? ?? "",
      url: snapshot.child("url").value as String?,
      timestamp: snapshot.child("timestamp").value as int? ?? 0,
      messageRead: snapshot.child("messageRead").value as bool? ?? false,
    );
    final String conversationPath = conversationRef.path;
    // Si el mensaje NO es del usuario actual, actualizar en Firebase
    if (message.senderId != userId && !message.messageRead) {
      messagesAsRead(conversationPath, userId);
    }

    // Esperar un pequeño tiempo antes de añadir el mensaje
    await Future.delayed(const Duration(milliseconds: 150));

    // Ahora sí, agregar o actualizar el mensaje localmente en tu aplicación
    _addOrUpdateMessage(message);
    syncMessagesWithFirebase(currentUserId!, otherUserId);
  }

  void _addOrUpdateMessage(Message message) {
    final currentMessages =
        (_messages.value)
            .whereType<Message>() // solo elementos que realmente sean Message
            .toList();

    // Buscar el índice del mensaje existente
    final existingMessageIndex = currentMessages.indexWhere(
      (element) => element.id == message.id,
    );

    if (existingMessageIndex != -1) {
      // Actualizar el mensaje existente
      currentMessages[existingMessageIndex] = message;
    } else {
      // Añadir el nuevo mensaje al INICIO de la lista
      currentMessages.insert(0, message);
    }

    // Actualizar la lista de mensajes sin ordenar (se mantienen en orden de inserción)
    _messages.value = currentMessages;
  }

  void cancelSpecificListener(String userId, String otherUserId) {
    final key = '${userId}_$otherUserId';
    _activeListeners[key]?.cancel();
    _activeListeners.remove(key);
    logger.info('Listener cancelado: $key');
  }

  void clearAllFirebaseListeners() {
    _activeListeners.forEach((key, sub) {
      sub.cancel();
      logger.info('Listener cancelado: $key');
    });
    _activeListeners.clear();
    logger.info('Todos los listeners cancelados');
  }

  Future<int> countUnreadMessages(
    String conversationId,
    String currentUserId,
  ) async {
    DatabaseReference conversationRef = FirebaseDatabase.instance.ref().child(
      conversationId,
    );
    DataSnapshot dataSnapshot = await conversationRef.get();
    int messagesUnReaded = 0;
    for (DataSnapshot snapshot in dataSnapshot.children) {
      String receiverId = snapshot.child("receiverId").value as String;
      bool messageRead = snapshot.child("messageRead").value as bool;

      if (receiverId == currentUserId && messageRead == false) {
        messagesUnReaded++;
      }
    }
    return messagesUnReaded;
  }

  String formatTimestampChats(int timestamp) {
    DateTime currentTime = DateTime.now();
    DateTime timestampDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime currentDate = DateTime.now();

    DateFormat sdfToday = DateFormat('HH:mm');
    DateFormat sdfYesterday = DateFormat("'Ayer' HH:mm");
    DateFormat sdfDayOfWeek = DateFormat('EEEE');
    DateFormat sdfFullDate = DateFormat('dd/MM/yyyy');

    Duration diff = currentTime.difference(timestampDate);
    int diffInDays = diff.inDays;

    if (diffInDays == 0 && isSameDay(timestampDate, currentDate)) {
      return "Hoy ${sdfToday.format(timestampDate)}";
    } else if (diffInDays == 1 &&
        isSameDay(timestampDate, getPreviousDay(currentDate))) {
      return "Ayer ${sdfYesterday.format(timestampDate)}";
    } else if (diffInDays >= 2 && diffInDays < 7) {
      return sdfDayOfWeek.format(timestampDate);
    } else {
      return sdfFullDate.format(timestampDate);
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  DateTime getPreviousDay(DateTime date) {
    return date.subtract(Duration(days: 1));
  }

  String formatTimestamp(int messageTimestamp) {
    DateTime currentTime = DateTime.now();
    DateTime messageDate = DateTime.fromMillisecondsSinceEpoch(
      messageTimestamp,
    );

    Duration diff = currentTime.difference(messageDate);
    int diffInHours = diff.inHours;
    int diffInDays = diff.inDays;

    if (diffInHours < 24) {
      DateFormat timeFormat = DateFormat('h:mm a');
      return timeFormat.format(messageDate);
    } else if (diffInDays < 2) {
      return "Ayer";
    } else if (diffInDays < 7) {
      DateFormat dayFormat = DateFormat('EEEE');
      return dayFormat.format(messageDate);
    } else {
      DateFormat dateFormat = DateFormat('dd/MM/yyyy');
      return dateFormat.format(messageDate);
    }
  }

  Future<void> syncConversationsFromFirebase(String userId) async {
    try {
      final nickname = await getNickname(userId);
      final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

      final DataSnapshot snapshot = await rootRef.get();
      final db = await roomDb;

      if (snapshot.exists) {
        for (final DataSnapshot child in snapshot.children) {
          final String? conversationName = child.key;

          // Solo procesar si el nombre contiene el nickname
          if (conversationName != null && conversationName.contains(nickname)) {
            ConversationTempData conversationData = await processCollection(
              child,
              userId,
            );

            final userInfo = await getUserInfoFromFirestore(
              conversationData.userId,
            );
            final int messagesUnread = await countUnreadMessages(
              conversationName,
              userId,
            );
            final String formattedTimestamp = formatTimestamp(
              conversationData.timestamp,
            );
            final String userNickname = await getNickname(
              conversationData.userId,
            );
            final bool isArtist = await checkIfArtist(conversationData.userId);

            final conversation = Conversation(
              currentUserId: userId,
              nickname: userNickname,
              otherUserId: conversationData.userId,
              lastMessage: conversationData.lastMessage,
              timestamp: conversationData.timestamp,
              profileImage: userInfo.second,
              name: userInfo.first,
              messagesUnread: messagesUnread,
              conversationName: conversationName,
              formattedTimestamp: formattedTimestamp,
              artist: isArtist,
            );

            await db.conversationDao.insertOrUpdate(conversation);
          }
        }
      }
    } catch (e) {
      debugPrint("syncConversationsFromFirebase error: $e");
    }
  }

  Future<void> syncAllConversationsWithNickname(String userId) async {
    try {
      final nickname = await getNickname(userId);
      final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

      final DataSnapshot snapshot = await rootRef.get();
      final db = await roomDb;

      if (snapshot.exists) {
        for (final DataSnapshot child in snapshot.children) {
          final String? conversationName = child.key;

          // Solo procesar si el nombre contiene el nickname
          if (conversationName != null && conversationName.contains(nickname)) {
            ConversationTempData conversationData = await processCollection(
              child,
              userId,
            );

            final userInfo = await getUserInfoFromFirestore(
              conversationData.userId,
            );
            final int messagesUnread = await countUnreadMessages(
              conversationName,
              userId,
            );
            final String formattedTimestamp = formatTimestamp(
              conversationData.timestamp,
            );
            final String userNickname = await getNickname(
              conversationData.userId,
            );
            final bool isArtist = await checkIfArtist(conversationData.userId);

            final conversation = Conversation(
              currentUserId: userId,
              nickname: userNickname,
              otherUserId: conversationData.userId,
              lastMessage: conversationData.lastMessage,
              timestamp: conversationData.timestamp,
              profileImage: userInfo.second,
              name: userInfo.first,
              messagesUnread: messagesUnread,
              conversationName: conversationName,
              formattedTimestamp: formattedTimestamp,
              artist: isArtist,
            );

            await db.conversationDao.insertOrUpdate(conversation);
          }
        }
      }
    } catch (e) {
      debugPrint("syncAllConversationsWithNickname error: $e");
    }
  }

  Future<void> deleteConversation(String userId) async {
    try {
      final db =
          await roomDb; // Asegúrate de que roomDb es una instancia de la base de datos
      await db.conversationDao.deleteConversation(
        userId,
      ); // Verifica que deleteConversation existe en conversationDao
    } catch (e) {
      print("$e");
    }
  }

  final Map<String, StreamSubscription> _activeSubscriptions = {};

  Future<void> setupConversationListener(String userId) async {
    try {
      String nickname = await getNickname(userId);
      print("se inicializa");
      // 🔹 NUEVO PASO: sincronizar desde Firebase a Room
      await syncConversationsFromFirebase(userId);

      // 1) Cargar conversaciones ya existentes desde Room y conectar listeners
      await setupListenersForExistingConversations(userId);

      // 2) Configuración de listeners en tiempo real para nuevos mensajes
      final lastTimestamps = await loadLastTimestampsFromDb(userId);

      lastTimestamps.forEach((conversationName, lastTs) {
        // Cancelar listener anterior si existe
        _activeSubscriptions[conversationName]?.cancel();

        final ref = FirebaseDatabase.instance
            .ref(conversationName)
            .orderByChild('timestamp')
            .startAt(lastTs + 1);

        bool isInitialData = true;

        final subscription = ref.onChildAdded.listen((event) {
          if (isInitialData) {
            // Ignorar los datos iniciales (ya fueron procesados)
            isInitialData = false;
            return;
          }
          handleNewCollection(event.snapshot, userId, nickname);
        });

        _activeSubscriptions[conversationName] = subscription;
      });
    } catch (e) {
      debugPrint("setupConversationListener error: $e");
    }
  }

  Future<Map<String, int>> loadLastTimestampsFromDb(String userId) async {
    final db = await roomDb;
    final List<Conversation> conversations = await db.conversationDao
        .getConversationsListByCurrentUserId(userId);

    // Mapeo nombre de conversación a su último timestamp
    return {
      for (var convo in conversations) convo.conversationName: convo.timestamp,
    };
  }

  Future<String> getNickname(String userId) async {
    DocumentSnapshot documentSnapshot =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();
    return documentSnapshot.get("nickname") ?? "";
  }

  Future<bool> checkIfArtist(String userId) async {
    try {
      DocumentSnapshot document =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(userId)
              .get();
      if (document.exists) {
        String userType = document.get("userType")?.trim().toLowerCase() ?? "";
        return userType == "artist";
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("$e");
      return false;
    }
  }

  void handleNewCollection(
    DataSnapshot snapshot,
    String userId,
    String nickname,
  ) async {
    try {
      String? collectionName = snapshot.key;
      if (collectionName == null || !collectionName.contains(nickname)) return;

      ConversationTempData conversationData = await processCollection(
        snapshot,
        userId,
      );
      Pair<String, String?> userInfo = await getUserInfoFromFirestore(
        conversationData.userId,
      );
      int messagesUnread = await countUnreadMessages(collectionName, userId);
      String formattedTimestamp = formatTimestamp(conversationData.timestamp);
      String userNickname = await getNickname(conversationData.userId);
      bool isArtist = await checkIfArtist(conversationData.userId);

      Conversation conversation = Conversation(
        currentUserId: userId,
        nickname: userNickname,
        otherUserId: conversationData.userId,
        lastMessage: conversationData.lastMessage,
        timestamp: conversationData.timestamp,
        profileImage: userInfo.second,
        name: userInfo.first,
        messagesUnread: messagesUnread,
        conversationName: collectionName,
        formattedTimestamp: formattedTimestamp,
        artist: isArtist,
      );

      final db = await roomDb;
      await db.conversationDao.insertOrUpdate(conversation);
    } catch (e) {
      debugPrint("$e");
    }
  }

  Future<ConversationTempData> processCollection(
    DataSnapshot snapshot,
    String userId,
  ) async {
    Iterable<DataSnapshot> messages = snapshot.children;
    DataSnapshot lastMessage = messages.last;

    String senderId = lastMessage.child("senderId").value as String? ?? "";
    String receiverId = lastMessage.child("receiverId").value as String? ?? "";
    int timestamp = lastMessage.child("timestamp").value as int? ?? 0;
    String type = lastMessage.child("type").value as String? ?? "text";

    // Determinar el mensaje a mostrar según el tipo
    String lastMessageText;
    switch (type) {
      case "image":
        lastMessageText = "te ha enviado una imagen";
        break;
      case "video":
        lastMessageText = "te ha enviado un video";
        break;
      case "location":
        lastMessageText = "te ha compartido su ubicación";
        break;
      default: // text
        lastMessageText = lastMessage.child("message").value as String? ?? "";
    }

    String otherUserId = senderId != userId ? senderId : receiverId;
    return ConversationTempData(
      userId: otherUserId,
      timestamp: timestamp,
      lastMessage: lastMessageText,
    );
  }

  Future<Pair<String, String?>> getUserInfoFromFirestore(String userId) async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(userId)
              .get();

      final data = doc.data() as Map<String, dynamic>?;

      final name = data?["name"] as String? ?? "";
      final profileImageUrl = data?["profileImageUrl"] as String?;

      return Pair(name, profileImageUrl);
    } catch (e) {
      debugPrint("$e");
      return Pair("", null);
    }
  }

  void messagesAsRead(String collectionPath, String userId) {
    DatabaseReference mensajesRef = FirebaseDatabase.instance.ref().child(
      collectionPath,
    );

    mensajesRef
        .orderByChild("receiverId")
        .equalTo(userId)
        .once()
        .then((DatabaseEvent event) {
          DataSnapshot snapshot = event.snapshot;
          snapshot.children.forEach((DataSnapshot child) {
            child.ref.child("messageRead").set(true);
          });
        })
        .catchError((error) {
          debugPrint("$error");
        });
  }

  Future<void> setupListenersForExistingConversations(String userId) async {
    final db = await roomDb;
    List<Conversation> conversations = await db.conversationDao
        .getConversationsListByCurrentUserId(userId);

    // Cancelar listeners anteriores
    _activeListeners.forEach((_, sub) => sub.cancel());
    _activeListeners.clear();

    for (var conversation in conversations) {
      DatabaseReference conversationRef = FirebaseDatabase.instance.ref().child(
        conversation.conversationName,
      );

      final subAdd = conversationRef.onChildAdded.listen((event) {
        updateConversation(event.snapshot, conversation, userId);
      });
      final subChange = conversationRef.onChildChanged.listen((event) {
        updateConversation(event.snapshot, conversation, userId);
      });

      // Guardar ambos listeners
      _activeListeners['${conversation.conversationName}_add'] = subAdd;
      _activeListeners['${conversation.conversationName}_change'] = subChange;
    }
  }

  Future<void> updateConversation(
    DataSnapshot snapshot,
    Conversation conversation,
    String userId,
  ) async {
    try {
      int timestamp = snapshot.child("timestamp").value as int? ?? 0;

      // 1. Obtén la conversación actual de Room
      final db = await roomDb;
      final current = await db.conversationDao.getConversationById(
        conversation.otherUserId,
      );

      // 2. Solo actualiza si el mensaje es más nuevo
      if (current == null || timestamp >= current.timestamp) {
        String type = snapshot.child("type").value as String? ?? "text";
        String messageText = snapshot.child("message").value as String? ?? "";

        String lastMessage;
        switch (type) {
          case "image":
            lastMessage = "te ha enviado una imagen";
            break;
          case "video":
            lastMessage = "te ha enviado un video";
            break;
          case "location":
            lastMessage = "te ha compartido su ubicación";
            break;
          default:
            lastMessage = messageText;
        }

        int messagesUnread = await countUnreadMessages(
          conversation.conversationName,
          userId,
        );
        String formattedTimestamp = formatTimestamp(timestamp);

        Conversation updatedConversation = conversation.copyWith(
          lastMessage: lastMessage,
          timestamp: timestamp,
          messagesUnread: messagesUnread,
          formattedTimestamp: formattedTimestamp,
        );

        syncMessagesWithFirebase(userId, conversation.otherUserId);

        await db.conversationDao.insertOrUpdate(updatedConversation);
      }
    } catch (e) {
      debugPrint("$e");
    }
  }

  Future<void> sendLocation(
    BuildContext context,
    double latitude,
    double longitude,
    String senderId,
    String receiverId,
  ) async {
    final locationMessage = "$latitude,$longitude";
    await sendMessage(
      context,
      locationMessage,
      null,
      senderId,
      receiverId,

      isLocation: true,
    );
  }

  Future<void> sendMessage(
    BuildContext context,
    String message,
    File? mediaFile,
    String senderId,
    String receiverId, {
    bool isLocation = false,
    bool messageRead = false,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final db = FirebaseDatabase.instance.ref();

    final senderDoc = await firestore.collection("users").doc(senderId).get();
    final receiverDoc =
        await firestore.collection("users").doc(receiverId).get();

    final otherNickname = receiverDoc.get("nickname") ?? "Unknown";
    final myNickname = senderDoc.get("nickname") ?? "Unknown";
    final conv1 = "conversation $myNickname-$otherNickname";
    final conv2 = "conversation $otherNickname-$myNickname";
    final ref1 = db.child(conv1);
    final ref2 = db.child(conv2);

    final exists2 = (await ref2.limitToFirst(1).get()).exists;
    final convRef = exists2 ? ref2 : ref1;

    String type;
    if (isLocation) {
      type = "location";
    } else if (mediaFile != null) {
      // Detectar automáticamente si es video o imagen
      final extension = mediaFile.path.toLowerCase().split('.').last;
      type =
          (extension == 'mp4' || extension == 'mov' || extension == 'avi')
              ? "video"
              : "image";
    } else {
      type = "text";
    }

    final data = await _createMessageData(
      context,
      type,
      message,
      mediaFile,
      senderId,
      receiverId,
    );

    if (data.isNotEmpty) {
      await convRef.push().set(data).then((_) {}).catchError((e) {
        print("$e");
      });
    }
  }

  Future<Map<String, dynamic>> _createMessageData(
    BuildContext context,
    String messageType,
    String message,
    File? mediaFile,
    String senderId,
    String receiverId,
  ) async {
    switch (messageType) {
      case "image":
      case "video":
        if (mediaFile == null) return {};
        final url = await uploadMessageMedia(senderId, mediaFile);
        if (url == null) {
          print("Error al subir archivo multimedia");
          return {};
        }
        return {
          "type": messageType,
          "senderId": senderId,
          "url": url,
          "receiverId": receiverId,
          "timestamp": ServerValue.timestamp,
          "messageRead": false,
        };
      case "location":
        return {
          "type": "location",
          "message": message,
          "senderId": senderId,
          "receiverId": receiverId,
          "timestamp": ServerValue.timestamp,
          "messageRead": false,
        };
      default:
        return {
          "type": "text",
          "message": message,
          "senderId": senderId,
          "receiverId": receiverId,
          "timestamp": ServerValue.timestamp,
          "messageRead": false,
        };
    }
  }

  Future<String?> uploadMessageMedia(String userId, File mediaFile) async {
    try {
      final uploadResp = await RetrofitClientMessages().apiServiceMessages
          .uploadMessageMedia(mediaFile, userId);

      if (uploadResp.url != null) {
        return uploadResp.url;
      } else {
        print('${uploadResp.error}');
        return null;
      }
    } catch (e) {
      print('$e');
      return null;
    }
  }

  Future<Uint8List> readAsBytes(Uri uri) async {
    final file = File(uri.toFilePath());
    return await file.readAsBytes();
  }
}