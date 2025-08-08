/// ===========================================================================
/// Created on: 2025-04-26
/// Author: KingdomOfJames
///
/// Description:
///   FavoritesProvider es un proveedor centralizado para gestionar las listas
///   de usuarios favoritos y perfiles recientemente vistos dentro de una app
///   social o de matchmaking. Este gestor interactúa con Firebase Firestore,
///   Firebase Auth y bases de datos locales (Room) para sincronizar listas,
///   actualizar estados de "like", y mantener información reactiva para la UI.
///
/// Recomendaciones:
/// - Centraliza mejor la lógica repetitiva para eliminar usuarios (DRY).
/// - Implementa manejo de errores más robusto y orientado al usuario.
/// - Considera dividir en múltiples clases para mejorar la separación de
///   responsabilidades (por ejemplo: RecentlyViewedProvider, LikesProvider).
///
/// Características clave:
/// - Escucha en tiempo real si un usuario fue "likeado".
/// - Maneja la selección de listas de usuarios favoritos.
/// - Soporte completo para añadir/eliminar usuarios de Firestore y Room.
/// - Flujo reactivo con BehaviorSubjects para reflejar cambios en la UI.
/// - Compatible con múltiples listas y múltiples vistas de datos (perfil,
///   listas de artistas, etc.).
/// ===========================================================================

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../../../sources/local/internal_data_base.dart';

class FavoritesProvider extends ChangeNotifier {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final LikedUsersListDao likedUsersListDao;
  final RecentlyViewedDao recentlyViewedDao;

  FavoritesProvider({
    FirebaseFirestore? firestoreInstance,
    FirebaseAuth? authInstance,
    required LikedUsersListDao dao,
    required RecentlyViewedDao recentlyViewedDao,
  }) : firestore = firestoreInstance ?? FirebaseFirestore.instance,
       auth = authInstance ?? FirebaseAuth.instance,
       likedUsersListDao = dao,
       recentlyViewedDao = recentlyViewedDao {
    _initialize();
  }

  String? _selectedListName;
  final _selectedListNameController = StreamController<String?>.broadcast();

  Stream<String?> get selectedListName async* {
    yield _selectedListName; // <-- esto emite el valor inmediatamente al nuevo listener
    yield* _selectedListNameController.stream;
  }

  Map<String, StreamSubscription<DocumentSnapshot>> _likedUsersListeners = {};
  Map<String, bool> _userLikedStatus = {};

  void startLikedUsersListener(String currentUserId, String targetUserId) {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId);

    _likedUsersListeners[targetUserId]
        ?.cancel(); // si ya hay uno, lo cancelamos
    _likedUsersListeners[targetUserId] = docRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        docRef.set({'likedUsers': []});
        _userLikedStatus[targetUserId] = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final likedUsers = List<String>.from(data['likedUsers'] ?? []);
      _userLikedStatus[targetUserId] = likedUsers.contains(targetUserId);
      notifyListeners();
    });
  }

  final BehaviorSubject<LikedUsersList?> _selectedList = BehaviorSubject();
  LikedUsersList? get selectedListValue => _selectedList.valueOrNull;

  // Método para establecer la lista seleccionada
  void setSelectedList(LikedUsersList list) {
    _selectedList.add(list);
    notifyListeners();
  }

  // Método para limpiar la lista seleccionada
  void clearSelectedList() {
    _selectedList.add(null);
    notifyListeners();
  }

  Future<void> removeUserFromFavorites({
    required String currentUserId,
    required String userIdToRemove,
  }) async {
    final collectionRef = firestore
        .collection('users')
        .doc(currentUserId)
        .collection('usersLiked');

    final querySnapshot = await collectionRef.get();

    for (final doc in querySnapshot.docs) {
      final likedUsersList = List<String>.from(
        doc.data()['likedUsersList'] ?? [],
      );

      if (likedUsersList.contains(userIdToRemove)) {
        likedUsersList.remove(userIdToRemove);

        if (likedUsersList.isEmpty) {
          await doc.reference
              .delete(); // Elimina el documento si la lista queda vacía
        } else {
          await doc.reference.update({'likedUsersList': likedUsersList});
        }

        notifyListeners();
        break;
      }
    }
  }

  void stopLikedUsersListener(String targetUserId) {
    _likedUsersListeners[targetUserId]?.cancel();
    _likedUsersListeners.remove(targetUserId);
    _userLikedStatus.remove(targetUserId);
    notifyListeners();
  }

  bool isUserLiked(String targetUserId) {
    return _userLikedStatus[targetUserId] ?? false;
  }

  void setSelectedListName(String? name) {
    _selectedListName = name;
    _selectedListNameController.add(name);
  }

  User? get currentUser => auth.currentUser;
  String? get currentUserId => currentUser?.uid;

  final _profileImageUrl = BehaviorSubject<String>.seeded("");
  Stream<String> get profileImageUrl => _profileImageUrl.stream;

  final _recentlyViewedProfiles =
      BehaviorSubject<List<RecentlyViewedProfile>>.seeded([]);
  Stream<List<RecentlyViewedProfile>> get recentlyViewedProfiles =>
      _recentlyViewedProfiles.stream;

  final _likedUsersLists = BehaviorSubject<List<LikedUsersList>>.seeded([]);
  // In your FavoritesProvider class
  List<LikedUsersList> get likedUsersListsValue => _likedUsersLists.value;
  Stream<List<LikedUsersList>> get likedUsersLists => _likedUsersLists.stream;

  final _selectedArtistId = BehaviorSubject<String>.seeded("");
  Stream<String> get selectedArtistId => _selectedArtistId.stream;

  final _selectedListId = BehaviorSubject<String?>();
  Stream<String?> get selectedListId => _selectedListId.stream;

  final _likedProfiles = BehaviorSubject<List<LikedProfile>>.seeded([]);
  Stream<List<LikedProfile>> get likedProfiles => _likedProfiles.stream;

  StreamSubscription<QuerySnapshot>? likedUsersListener;

  void setSelectedListId(String listId) {
    _selectedListId.add(listId);
  }

  void _initialize() {
    fetchRecentlyViewedProfilesFromRoom();

    fetchLikedUsersListsFromRoom();
    listenToLikedUsersLists();
  }

  void removeFromLikedUsersList({
    required String currentUserId,
    required String listId,
    required String userId,
  }) async {
    if (currentUserId.isEmpty || listId.isEmpty || userId.isEmpty) {
      return;
    }

    final userLikedRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("usersLiked")
        .doc(listId);

    final otherUserRef = FirebaseFirestore.instance
        .collection("users")
        .doc(userId);

    // 1. Eliminar de 'userWhoLikedMeIds' del artista
    try {
      await otherUserRef.update({
        'userWhoLikedMeIds': FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {}

    // 2. Decrementar likes del artista
    try {
      await otherUserRef.update({'likes': FieldValue.increment(-1)});
    } catch (e) {}

    // Obtener documento de la lista
    DocumentSnapshot? docSnapshot;
    try {
      docSnapshot = await userLikedRef.get();
      if (!docSnapshot.exists) {
        return;
      }
    } catch (e) {
      return;
    }

    // 3. Eliminar el userId de la lista likedUsers del usuario principal
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .update({
            "likedUsers": FieldValue.arrayRemove([userId]),
          });
    } catch (e) {}

    try {
      final firestoreList = List<String>.from(
        (docSnapshot.data() as Map<String, dynamic>)['likedUsersList'] ?? [],
      );

      if (firestoreList.length <= 1 && firestoreList.contains(userId)) {
        // Caso cuando solo hay un ID en la lista
        try {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(currentUserId)
              .update({
                "likedUsers": FieldValue.arrayRemove([listId]),
              });
        } catch (e) {}

        try {
          await userLikedRef.delete();
        } catch (e) {}

        try {
          await likedUsersListDao.delete(listId);
        } catch (e) {}
      } else {
        // Caso cuando hay múltiples IDs en la lista
        try {
          await userLikedRef.update({
            'likedUsersList': FieldValue.arrayRemove([userId]),
          });

          final local = await likedUsersListDao.getById(listId);
          if (local != null) {
            final updatedUsers = List<String>.from(local.likedUsersList)
              ..remove(userId);

            final updatedList = LikedUsersList(
              listId: local.listId,
              name: local.name,
              creationDate: local.creationDate,
              likedUsersList: updatedUsers,
              imageUrl: local.imageUrl,
            );

            await likedUsersListDao.insert(updatedList);
          }
        } catch (e) {}
      }
    } catch (e) {}
  }

  void onUnlikeClick(String artist) async {
    if (currentUserId == null || currentUserId!.isEmpty) {
      return;
    }

    final currentUserRef = firestore.collection("users").doc(currentUserId);

    try {
      // Buscar el listId en la colección usersLiked
      final querySnapshot = await currentUserRef.collection("usersLiked").get();

      String? listId;
      for (var doc in querySnapshot.docs) {
        try {
          final likedUsersList = doc.data()['likedUsersList'] as List?;
          if (likedUsersList != null && likedUsersList.contains(artist)) {
            listId = doc.id;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (listId != null && listId.isNotEmpty) {
        // Llamar a la función para eliminar al artista de la lista de "likedUsers"
        removeFromLikedUsersList(
          currentUserId: currentUserId!,
          listId: listId,
          userId: artist,
        );

        // Ahora restar -1 a "userLikes" en el primer documento que no sea "Default" o "default"
        final statisticsRef = firestore
            .collection("UserStatistics")
            .doc(artist)
            .collection("phases")
            .doc("fase1")
            .collection("Statistics");

        final statisticsSnapshot = await statisticsRef.get();

        for (var doc in statisticsSnapshot.docs) {
          final userLikes = doc.data()['userLikes'];
          if (userLikes != null &&
              userLikes is int &&
              doc.id.toLowerCase() != 'default') {
            // Restar -1 al campo userLikes
            await doc.reference.update({'userLikes': FieldValue.increment(-1)});

            break; // Solo restamos en el primer documento que cumpla la condición
          }
        }
      } else {}
    } catch (e) {}
  }

  void onLikeClick(String artist, String currentUserId) async {
    // Verify artist is not null or empty
    if (artist.isEmpty) {
      return;
    }

    // Firestore document references
    final currentUserRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId);
    final otherUserRef = FirebaseFirestore.instance
        .collection("users")
        .doc(artist);

    // Update current user's likedUsers list
    currentUserRef
        .update({
          "likedUsers": FieldValue.arrayUnion([artist]),
        })
        .then((_) {})
        .catchError((e) {});

    // Update artist's userWhoLikedMeIds list
    otherUserRef
        .update({
          "userWhoLikedMeIds": FieldValue.arrayUnion([currentUserId]),
        })
        .then((_) {
          // Check if currentUserId is in userWhoLikedMeIds
          otherUserRef.get().then((document) {
            if (document.exists) {
              final userWhoLikedMeIds = List<String>.from(
                document.data()?['userWhoLikedMeIds'] ?? [],
              );
              if (userWhoLikedMeIds.contains(currentUserId)) {
                // Update a field in the artist's document (optional)
                otherUserRef
                    .update({"userLiked": true})
                    .then((_) {})
                    .catchError((e) {});
              }
            }
          });
        })
        .catchError((e) {});

    // Ahora sumar +1 a "userLikes" en el primer documento que no sea "Default" o "default"
    final statisticsRef = FirebaseFirestore.instance
        .collection("UserStatistics")
        .doc(artist)
        .collection("phases")
        .doc("fase1")
        .collection("Statistics");

    try {
      final statisticsSnapshot = await statisticsRef.get();

      for (var doc in statisticsSnapshot.docs) {
        final userLikes = doc.data()['userLikes'];
        if (userLikes != null &&
            userLikes is int &&
            doc.id.toLowerCase() != 'default') {
          // Sumar +1 al campo userLikes
          await doc.reference.update({'userLikes': FieldValue.increment(1)});

          break; // Solo sumamos en el primer documento que cumpla la condición
        }
      }
    } catch (e) {}
  }

  void fetchLikedUsersListsFromRoom() {
    Future(() async {
      await for (final lists in likedUsersListDao.getAll()) {
        _likedUsersLists.add(lists);
      }
    });
  }

  List<String> parseLikedUsers(String likedUsersString) {
    try {
      final jsonArray = jsonDecode(likedUsersString);
      return jsonArray.cast<String>();
    } catch (e) {
      return [];
    }
  }

  void removeLikedUserList(String listId) {
    if (currentUserId != null) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .collection("usersLiked")
          .doc(listId)
          .delete()
          .then((_) {})
          .catchError((e) {});

      likedUsersListDao.delete(listId);
    }
  }

  void listenForLikedUsersChanges(BuildContext context, String currentUserId) {
    if (currentUserId.isEmpty) {
      return;
    }

    final db = FirebaseFirestore.instance;

    likedUsersListener = db
        .collection('users')
        .doc(currentUserId)
        .collection('usersLiked')
        .snapshots()
        .listen(
          (snapshot) async {
            List<String> allUserIds = []; // Para recolectar todos los IDs

            for (var document in snapshot.docs) {
              if (!document.exists) {
                continue;
              }

              final likedUsersList =
                  document.get('likedUsersList') as List<dynamic>?;

              if (likedUsersList == null || likedUsersList.isEmpty) {
                continue;
              }

              final uniqueUserIds =
                  likedUsersList.map((id) => id.toString()).toSet().toList();
              allUserIds.addAll(uniqueUserIds);

              // Procesar cada usuario para guardar en Room
              for (String userId in uniqueUserIds) {
                if (userId.isEmpty) continue;

                try {
                  final userDocument =
                      await db.collection('users').doc(userId).get();
                  if (!userDocument.exists) continue;

                  final likedProfile = LikedProfile(
                    userId: userId,
                    profileImageUrl: userDocument.get('profileImageUrl') ?? '',
                    name: userDocument.get('name') ?? '',
                    price: (userDocument.get('price') ?? 0).toDouble(),
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    userLiked: userDocument.get('userLiked') ?? false,
                  );

                  final database = await AppDatabase.getInstance();
                  await database.likedProfileDao.insert(likedProfile);
                } catch (e) {}
              }
            }

            // Después de procesar todos los documentos, actualizar la UI
            if (allUserIds.isNotEmpty) {
              loadProfilesByIds(allUserIds);
            } else {
              _likedProfiles.add([]); // Limpiar si no hay IDs
            }
          },
          onError: (error) {
            _likedProfiles.addError(error);
          },
        );
  }

  Stream<List<LikedProfile>> getProfilesByIds(List<String> userIds) async* {
    final database = await AppDatabase.getInstance();
    yield* database.likedProfileDao.getProfilesByIds(userIds);
  }

  void loadProfilesByIds(List<String> userIds) async {
    final database = await AppDatabase.getInstance();

    database.likedProfileDao
        .getProfilesByIds(userIds)
        .listen(
          (profiles) {
            _likedProfiles.add(profiles);
          },
          onError: (e) {
            _likedProfiles.add([]);
          },
        );
  }

  void removeLikedUsersListener() {
    likedUsersListener?.cancel();
    likedUsersListener = null;
  }

  void updateSelectedArtistId(String id) {
    _selectedArtistId.add(id);
  }

  Future<void> fetchRecentlyViewedProfilesFromRoom() async {
    try {
      recentlyViewedDao.getAll().listen((profiles) {
        _recentlyViewedProfiles.add(profiles);
      });
    } catch (e) {
      // Handle error
      print('$e');
    }
  }

  Future<UserProfile?> getUserProfileDetails(String profileId) async {
    try {
      final document =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(profileId)
              .get();

      if (!document.exists) {
        return null;
      }

      final data = document.data()!;
      return UserProfile(
        id: profileId,
        profileImageUrl: data['profileImageUrl']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      return null;
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
  listenAndSaveRecentlyViewedProfiles({required String currentUserId}) {
    return firestore
        .collection('users')
        .doc(currentUserId)
        .collection('recentlyViewedProfiles')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
          final List<RecentlyViewedProfile> perfiles = [];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final profileId = data['profileId']?.toString() ?? doc.id;
            final timestamp =
                (data['timestamp'] is Timestamp)
                    ? (data['timestamp'] as Timestamp)
                        .toDate()
                        .millisecondsSinceEpoch
                    : DateTime.now().millisecondsSinceEpoch;

            try {
              final profileSnap =
                  await firestore.collection('users').doc(profileId).get();
              final profileData = profileSnap.data();

              if (profileData != null) {
                final profileImageUrl =
                    profileData['profileImageUrl']?.toString() ?? '';
                final name = profileData['name']?.toString() ?? '';
                final price =
                    (profileData['price'] is num)
                        ? (profileData['price'] as num).toDouble()
                        : 0.0;
                final userLiked =
                    (profileData['userLiked'] is bool)
                        ? profileData['userLiked'] as bool
                        : false;

                perfiles.add(
                  RecentlyViewedProfile(
                    userId: profileId,
                    profileImageUrl: profileImageUrl,
                    name: name,
                    price: price,
                    timestamp: timestamp,
                    userLiked: userLiked,
                  ),
                );
              }
            } catch (e) {
              print('Error al obtener datos del perfil $profileId: $e');
            }
          }

          await recentlyViewedDao.insertAll(perfiles);
        });
  }

  Future<void> syncWithRoom(List<Artist> profiles) async {
    debugPrint(
      "syncWithRoom: Iniciando sincronización con ${profiles.length} perfiles",
    );

    try {
      final database = await AppDatabase.getInstance();

      final thirtyDaysAgo =
          DateTime.now().millisecondsSinceEpoch - 30 * 24 * 60 * 60 * 1000;
      await database.recentlyViewedDao.deleteOldProfiles(thirtyDaysAgo);

      for (final artist in profiles) {
        await database.artistDao.insert(artist);
      }
    } catch (e) {
      debugPrint(" $e");
    }
  }

  Future<String?> getListNameContainingUser(String userId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) return null;

    final snapshot =
        await firestore
            .collection("users")
            .doc(currentUserId)
            .collection("usersLiked")
            .get();

    for (final doc in snapshot.docs) {
      final likedUsers = List<String>.from(doc['likedUsersList'] ?? []);
      if (likedUsers.contains(userId)) {
        return doc['name'];
      }
    }
    return null;
  }

  Future<void> createFavoritesList(String name, String userId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) return;

    final listData = {
      "name": name,
      "creationDate": DateTime.now().millisecondsSinceEpoch,
      "likedUsersList": [userId],
    };

    final listRef =
        firestore
            .collection("users")
            .doc(currentUserId)
            .collection("usersLiked")
            .doc();

    await listRef.set(listData);
  }

  void addUserToList(String listId, String userId) {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) return;

    final listRef = firestore
        .collection("users")
        .doc(currentUserId)
        .collection("usersLiked")
        .doc(listId);

    listRef
        .update({
          "likedUsersList": FieldValue.arrayUnion([userId]),
        })
        .then((_) {})
        .catchError((error) {
          print(" $error");
        });
  }

  void addUserToLikedList(
    String listId,
    String userId,
    VoidCallback onSuccess,
    Function(Exception) onError,
  ) {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) return;

    final likedListRef = firestore
        .collection("users")
        .doc(currentUserId)
        .collection("usersLiked")
        .doc(listId);

    likedListRef
        .update({
          "likedUsersList": FieldValue.arrayUnion([userId]),
        })
        .then((_) {
          onSuccess();
        })
        .catchError((error) {
          onError(error);
        });
  }

  Future<void> removeUserFromLikedList({
    required String listId,
    required String userId,
    required VoidCallback onSuccess,
    required Function(Exception) onError,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final likedListRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('usersLiked')
          .doc(listId);

      final snapshot = await likedListRef.get();
      final data = snapshot.data();

      if (data == null || data['likedUsersList'] == null) {
        throw Exception('Lista no encontrada');
      }

      final List<dynamic> likedUsers = List.from(data['likedUsersList']);
      if (likedUsers.length <= 1 && likedUsers.contains(userId)) {
        // Solo hay uno, y es el que se intenta eliminar: no hacer nada
        onSuccess();
        return;
      }

      await likedListRef.update({
        'likedUsersList': FieldValue.arrayRemove([userId]),
      });

      onSuccess();
    } catch (e) {
      onError(e as Exception);
    }
  }

  void listenToLikedUsersLists() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('usersLiked')
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.docs.isEmpty) return;

          final lists = await Future.wait(
            snapshot.docs.map((document) async {
              final listId = document.id;
              final name = document.get('name') ?? '';
              final creationDate = document.get('creationDate') ?? 0;
              final likedUsersList = List<String>.from(
                document.get('likedUsersList') ?? [],
              );

              final profileImageUrl =
                  likedUsersList.isNotEmpty
                      ? await getUserProfileImage(likedUsersList.first)
                      : '';

              return LikedUsersList(
                listId: listId,
                name: name,
                creationDate: creationDate,
                likedUsersList: likedUsersList,
                imageUrl: profileImageUrl,
              );
            }),
          );

          syncLikedUsersWithRoom(lists);
        });
  }

  void saveRecentlyViewedProfileToFirestore(
    String currentUserId,
    String profileId,
  ) {
    final timestamp = FieldValue.serverTimestamp();

    final recentlyViewedProfile = {
      "profileId": profileId,
      "timestamp": timestamp,
    };

    final userRecentlyViewedRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("recentlyViewedProfiles")
        .doc(profileId); // El documento tendrá como ID el profileId

    userRecentlyViewedRef
        .set(
          recentlyViewedProfile,
        ) // Usa set para crear o actualizar el documento
        .then((_) {})
        .catchError((error) {
          print(" $error");
        });
  }

  Future<String> getUserProfileImage(String userId) async {
    try {
      final document = await firestore.collection("users").doc(userId).get();
      return document.get("profileImageUrl") ?? "";
    } catch (e) {
      return "";
    }
  }

  Future<void> syncLikedUsersWithRoom(List<LikedUsersList> lists) async {
    for (var likedUsersList in lists) {
      likedUsersListDao.insert(likedUsersList);
    }
  }
}

class UserProfile {
  final String id;
  final String profileImageUrl;
  final String name;
  final double price;

  UserProfile({
    required this.id,
    required this.profileImageUrl,
    required this.name,
    required this.price,
  });

  // Opcional: Método para convertir a Map (útil para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileImageUrl': profileImageUrl,
      'name': name,
      'price': price,
    };
  }

  // Opcional: Factory constructor para crear desde Map (útil para Firestore)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Opcional: Sobrescribir toString para debugging
  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, price: $price, profileImageUrl: $profileImageUrl)';
  }

  // Opcional: Implementar igualdad (==) y hashCode si necesitas comparar objetos
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.profileImageUrl == profileImageUrl &&
        other.name == name &&
        other.price == price;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        profileImageUrl.hashCode ^
        name.hashCode ^
        price.hashCode;
  }
}
