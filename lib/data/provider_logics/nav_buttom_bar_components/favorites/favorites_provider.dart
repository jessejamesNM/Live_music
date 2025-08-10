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
    required this.likedUsersListDao,
    required this.recentlyViewedDao,
  }) : firestore = firestoreInstance ?? FirebaseFirestore.instance,
       auth = authInstance ?? FirebaseAuth.instance {
    _initialize();
  }

  String? _selectedListName;
  final _selectedListNameController = StreamController<String?>.broadcast();

  Stream<String?> get selectedListName async* {
    yield _selectedListName;
    yield* _selectedListNameController.stream;
  }

  Map<String, StreamSubscription<DocumentSnapshot>> _likedUsersListeners = {};
  Map<String, bool> _userLikedStatus = {};

  void startLikedUsersListener(String currentUserId, String targetUserId) {
    final docRef = firestore.collection('users').doc(currentUserId);

    _likedUsersListeners[targetUserId]?.cancel();
    _likedUsersListeners[targetUserId] = docRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        docRef.set({'likedUsers': []});
        _userLikedStatus[targetUserId] = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      final likedUsers = List<String>.from(data['likedUsers'] ?? []);
      _userLikedStatus[targetUserId] = likedUsers.contains(targetUserId);
      notifyListeners();
    });
  }

  final BehaviorSubject<LikedUsersList?> _selectedList = BehaviorSubject();
  LikedUsersList? get selectedListValue => _selectedList.valueOrNull;

  void setSelectedList(LikedUsersList list) {
    _selectedList.add(list);
    notifyListeners();
  }

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
          await doc.reference.delete();
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

    final userLikedRef = firestore
        .collection("users")
        .doc(currentUserId)
        .collection("usersLiked")
        .doc(listId);

    final otherUserRef = firestore.collection("users").doc(userId);

    try {
      await otherUserRef.update({
        'userWhoLikedMeIds': FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {
      debugPrint('Error removing userWhoLikedMeIds: $e');
    }

    try {
      await otherUserRef.update({'likes': FieldValue.increment(-1)});
    } catch (e) {
      debugPrint('Error decrementing likes: $e');
    }

    DocumentSnapshot? docSnapshot;
    try {
      docSnapshot = await userLikedRef.get();
      if (!docSnapshot.exists) {
        return;
      }
    } catch (e) {
      debugPrint('Error getting userLiked document: $e');
      return;
    }

    try {
      await firestore.collection("users").doc(currentUserId).update({
        "likedUsers": FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('Error updating likedUsers: $e');
    }

    try {
      final firestoreList = List<String>.from(
        (docSnapshot.data() as Map<String, dynamic>)['likedUsersList'] ?? [],
      );

      if (firestoreList.length <= 1 && firestoreList.contains(userId)) {
        try {
          await firestore.collection("users").doc(currentUserId).update({
            "likedUsers": FieldValue.arrayRemove([listId]),
          });
        } catch (e) {
          debugPrint('Error removing list from likedUsers: $e');
        }

        try {
          await userLikedRef.delete();
        } catch (e) {
          debugPrint('Error deleting userLiked document: $e');
        }

        try {
          await likedUsersListDao.delete(listId);
        } catch (e) {
          debugPrint('Error deleting from likedUsersListDao: $e');
        }
      } else {
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
        } catch (e) {
          debugPrint('Error updating likedUsersList: $e');
        }
      }
    } catch (e) {
      debugPrint('Error processing firestoreList: $e');
    }
  }
void onUnlikeClick(String artist) async {
  if (currentUserId == null || currentUserId!.isEmpty) {
    return;
  }

  try {
    // 1. Eliminar de la lista local (Room)
    final listId = await _findListIdContainingArtist(artist);
    if (listId != null) {
      try {
        await likedUsersListDao.delete(listId);
        debugPrint('Lista eliminada localmente: $listId');
      } catch (e) {
        debugPrint('Error eliminando lista local: $e');
      }
    }

    // 2. Eliminar de Firestore (operaciones independientes)
    await _removeFromFirestoreLists(artist);
    await _decrementUserLikes(artist);
    await _removeFromLikedUsersField(artist);

    // 3. Actualizar estadísticas (independiente de lo anterior)
    await _updateStatistics(artist);

  } catch (e) {
    debugPrint('Error en onUnlikeClick: $e');
  }
}

Future<String?> _findListIdContainingArtist(String artist) async {
  final currentUserRef = firestore.collection("users").doc(currentUserId);
  final querySnapshot = await currentUserRef.collection("usersLiked").get();

  for (var doc in querySnapshot.docs) {
    try {
      final likedUsersList = doc.data()['likedUsersList'] as List?;
      if (likedUsersList != null && likedUsersList.contains(artist)) {
        return doc.id;
      }
    } catch (e) {
      continue;
    }
  }
  return null;
}

Future<void> _removeFromFirestoreLists(String artist) async {
  try {
    final currentUserRef = firestore.collection("users").doc(currentUserId);
    final querySnapshot = await currentUserRef.collection("usersLiked").get();

    for (var doc in querySnapshot.docs) {
      try {
        final likedUsersList = List<String>.from(doc.data()['likedUsersList'] ?? []);
        if (likedUsersList.contains(artist)) {
          await doc.reference.update({
            'likedUsersList': FieldValue.arrayRemove([artist])
          });
          debugPrint('Artista eliminado de lista Firestore: ${doc.id}');
        }
      } catch (e) {
        debugPrint('Error eliminando de lista ${doc.id}: $e');
      }
    }
  } catch (e) {
    debugPrint('Error accediendo a Firestore: $e');
  }
}

Future<void> _removeFromLikedUsersField(String artist) async {
  try {
    await firestore.collection("users").doc(currentUserId).update({
      "likedUsers": FieldValue.arrayRemove([artist])
    });
    debugPrint('Artista eliminado de likedUsers');
  } catch (e) {
    debugPrint('Error eliminando de likedUsers: $e');
  }
}

Future<void> _decrementUserLikes(String artist) async {
  try {
    await firestore.collection("users").doc(artist).update({
      "userWhoLikedMeIds": FieldValue.arrayRemove([currentUserId]),
      "likes": FieldValue.increment(-1)
    });
    debugPrint('Contadores actualizados en artista');
  } catch (e) {
    debugPrint('Error actualizando contadores: $e');
  }
}

Future<void> _updateStatistics(String artist) async {
  try {
    final statisticsRef = firestore
        .collection("UserStatistics")
        .doc(artist)
        .collection("phases")
        .doc("fase1")
        .collection("Statistics");

    final statisticsSnapshot = await statisticsRef.get();

    for (var doc in statisticsSnapshot.docs) {
      try {
        final userLikes = doc.data()['userLikes'];
        if (userLikes != null && userLikes is int && doc.id.toLowerCase() != 'default') {
          await doc.reference.update({'userLikes': FieldValue.increment(-1)});
          debugPrint('Estadística actualizada: ${doc.id}');
          break;
        }
      } catch (e) {
        debugPrint('Error actualizando estadística ${doc.id}: $e');
      }
    }
  } catch (e) {
    debugPrint('Error accediendo a estadísticas: $e');
  }
}
  void onLikeClick(String artist, String currentUserId) async {
    if (artist.isEmpty) {
      return;
    }

    final currentUserRef = firestore.collection("users").doc(currentUserId);
    final otherUserRef = firestore.collection("users").doc(artist);

    try {
      await currentUserRef.update({
        "likedUsers": FieldValue.arrayUnion([artist]),
      });

      await otherUserRef.update({
        "userWhoLikedMeIds": FieldValue.arrayUnion([currentUserId]),
      });

      final document = await otherUserRef.get();
      if (document.exists) {
        final userWhoLikedMeIds = List<String>.from(
          document.data()?['userWhoLikedMeIds'] ?? [],
        );
        if (userWhoLikedMeIds.contains(currentUserId)) {
          await otherUserRef.update({"userLiked": true});
        }
      }

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
          await doc.reference.update({'userLikes': FieldValue.increment(1)});
          break;
        }
      }
    } catch (e) {
      debugPrint('Error in onLikeClick: $e');
    }
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
      firestore
          .collection("users")
          .doc(currentUserId)
          .collection("usersLiked")
          .doc(listId)
          .delete()
          .catchError((e) => debugPrint('Error removing liked user list: $e'));

      likedUsersListDao.delete(listId);
    }
  }

  void listenForLikedUsersChanges(BuildContext context, String currentUserId) {
    if (currentUserId.isEmpty) {
      return;
    }

    likedUsersListener = firestore
        .collection('users')
        .doc(currentUserId)
        .collection('usersLiked')
        .snapshots()
        .listen(
          (snapshot) async {
            List<String> allUserIds = [];

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

              for (String userId in uniqueUserIds) {
                if (userId.isEmpty) continue;

                try {
                  final serviceDoc = await firestore
                      .collection('services')
                      .doc(userId)
                      .get();
                  if (!serviceDoc.exists) continue;

                  final serviceData = serviceDoc.data() as Map<String, dynamic>?;
                  final servicesMap = serviceData?['service'] as Map<String, dynamic>?;
                  
                  final name = servicesMap?['name']?.toString() ?? '';
                  final imageUrl = servicesMap?['imageUrl']?.toString() ?? '';

                  double price = 0.0;
                  final servicesSnapshot = await firestore
                      .collection('services')
                      .doc(userId)
                      .collection('service')
                      .get();
                  
                  if (servicesSnapshot.docs.isNotEmpty) {
                    final prices = servicesSnapshot.docs
                        .map((doc) => (doc.data()['price'] as num?)?.toDouble() ?? 0.0)
                        .toList();
                    price = prices.reduce(
                        (min, current) => current < min ? current : min);
                  }

                  final likedProfile = LikedProfile(
                    userId: userId,
                    profileImageUrl: imageUrl,
                    name: name,
                    price: price,
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    userLiked: true,
                  );

                  final database = await AppDatabase.getInstance();
                  await database.likedProfileDao.insert(likedProfile);
                } catch (e) {
                  debugPrint('Error getting service data for $userId: $e');
                }
              }
            }

            if (allUserIds.isNotEmpty) {
              loadProfilesByIds(allUserIds);
            } else {
              _likedProfiles.add([]);
            }
          },
          onError: (error) {
            debugPrint('Error in likedUsersListener: $error');
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
            debugPrint('Error loading profiles by IDs: $e');
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
      debugPrint('Error fetching recently viewed profiles: $e');
    }
  }

  Future<UserProfile?> getUserProfileDetails(String profileId) async {
    try {
      final serviceDoc = await firestore.collection('services').doc(profileId).get();
      if (!serviceDoc.exists) return null;

      final serviceData = serviceDoc.data() as Map<String, dynamic>?;
      final servicesMap = serviceData?['service'] as Map<String, dynamic>?;
      
      final name = servicesMap?['name']?.toString() ?? '';
      final imageUrl = servicesMap?['imageUrl']?.toString() ?? '';

      double price = 0.0;
      final servicesSnapshot = await firestore
          .collection('services')
          .doc(profileId)
          .collection('service')
          .get();
      
      if (servicesSnapshot.docs.isNotEmpty) {
        final prices = servicesSnapshot.docs
            .map((doc) => (doc.data()['price'] as num?)?.toDouble() ?? 0.0)
            .toList();
        price = prices.reduce((min, current) => current < min ? current : min);
      }

      return UserProfile(
        id: profileId,
        profileImageUrl: imageUrl,
        name: name,
        price: price,
      );
    } catch (e) {
      debugPrint('Error getting user profile details: $e');
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
            final timestamp = (data['timestamp'] is Timestamp)
                ? (data['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch;

            try {
              final serviceDoc = await firestore.collection('services').doc(profileId).get();
              if (!serviceDoc.exists) continue;

              final serviceData = serviceDoc.data() as Map<String, dynamic>?;
              final servicesMap = serviceData?['service'] as Map<String, dynamic>?;
              
              final imageUrl = servicesMap?['imageUrl']?.toString() ?? '';
              final name = servicesMap?['name']?.toString() ?? '';

              double price = 0.0;
              final servicesSnapshot = await firestore
                  .collection('services')
                  .doc(profileId)
                  .collection('service')
                  .get();
              
              if (servicesSnapshot.docs.isNotEmpty) {
                final prices = servicesSnapshot.docs
                    .map((doc) => (doc.data()['price'] as num?)?.toDouble() ?? 0.0)
                    .toList();
                price = prices.reduce((min, current) => current < min ? current : min);
              }

              perfiles.add(
                RecentlyViewedProfile(
                  userId: profileId,
                  profileImageUrl: imageUrl,
                  name: name,
                  price: price,
                  timestamp: timestamp,
                  userLiked: true,
                ),
              );
            } catch (e) {
              debugPrint('Error getting recently viewed profile data: $e');
            }
          }

          await recentlyViewedDao.insertAll(perfiles);
        });
  }

  Future<void> syncWithRoom(List<Artist> profiles) async {
    debugPrint("syncWithRoom: Starting sync with ${profiles.length} profiles");

    try {
      final database = await AppDatabase.getInstance();

      final thirtyDaysAgo =
          DateTime.now().millisecondsSinceEpoch - 30 * 24 * 60 * 60 * 1000;
      await database.recentlyViewedDao.deleteOldProfiles(thirtyDaysAgo);

      for (final artist in profiles) {
        await database.artistDao.insert(artist);
      }
    } catch (e) {
      debugPrint("Error syncing with Room: $e");
    }
  }

  Future<String?> getListNameContainingUser(String userId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) return null;

    try {
      final snapshot = await firestore
          .collection("users")
          .doc(currentUserId)
          .collection("usersLiked")
          .get();

      for (final doc in snapshot.docs) {
        final likedUsers = List<String>.from(doc['likedUsersList'] ?? []);
        if (likedUsers.contains(userId)) {
          return doc['name'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error getting list name containing user: $e');
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

    try {
      final listRef = firestore
          .collection("users")
          .doc(currentUserId)
          .collection("usersLiked")
          .doc();

      await listRef.set(listData);
    } catch (e) {
      debugPrint('Error creating favorites list: $e');
    }
  }

  void addUserToList(String listId, String userId) {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) {
      debugPrint("Current user ID is null, cannot add user to list.");
      return;
    }

    final listRef = firestore
        .collection("users")
        .doc(currentUserId)
        .collection("usersLiked")
        .doc(listId);

    listRef.update({
      "likedUsersList": FieldValue.arrayUnion([userId]),
    }).catchError((error) {
      debugPrint("Error adding user to list: $error");
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

    likedListRef.update({
      "likedUsersList": FieldValue.arrayUnion([userId]),
    }).then((_) {
      onSuccess();
    }).catchError((error) {
      onError(error as Exception);
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

      final likedListRef = firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('usersLiked')
          .doc(listId);

      final snapshot = await likedListRef.get();
      final data = snapshot.data();

      if (data == null || data['likedUsersList'] == null) {
        throw Exception('List not found');
      }

      final List<dynamic> likedUsers = List.from(data['likedUsersList']);
      if (likedUsers.length <= 1 && likedUsers.contains(userId)) {
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

    firestore
        .collection('users')
        .doc(currentUserId)
        .collection('usersLiked')
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.docs.isEmpty) return;

          final lists = await Future.wait(
            snapshot.docs.map((document) async {
              final listId = document.id;
              final name = document.get('name') as String? ?? '';
              final creationDate = document.get('creationDate') as int? ?? 0;
              final likedUsersList = List<String>.from(
                document.get('likedUsersList') ?? [],
              );

              final profileImageUrl = likedUsersList.isNotEmpty
                  ? await getServiceProfileImage(likedUsersList.first)
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

    final userRecentlyViewedRef = firestore
        .collection("users")
        .doc(currentUserId)
        .collection("recentlyViewedProfiles")
        .doc(profileId);

    userRecentlyViewedRef.set(recentlyViewedProfile).catchError((error) {
      debugPrint("Error saving recently viewed profile: $error");
    });
  }

  Future<String> getServiceProfileImage(String userId) async {
    try {
      final document = await firestore.collection("services").doc(userId).get();
      if (!document.exists) return "";
      
      final serviceData = document.data() as Map<String, dynamic>?;
      final servicesMap = serviceData?['service'] as Map<String, dynamic>?;
      
      return servicesMap?['imageUrl']?.toString() ?? "";
    } catch (e) {
      debugPrint('Error getting service profile image: $e');
      return "";
    }
  }

  Future<void> syncLikedUsersWithRoom(List<LikedUsersList> lists) async {
    try {
      for (var likedUsersList in lists) {
        await likedUsersListDao.insert(likedUsersList);
      }
    } catch (e) {
      debugPrint('Error syncing liked users with Room: $e');
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileImageUrl': profileImageUrl,
      'name': name,
      'price': price,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, price: $price, profileImageUrl: $profileImageUrl)';
  }

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