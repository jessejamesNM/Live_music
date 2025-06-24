/// ------------------------------------------------------
/// Fecha de creación: 26/04/2025
/// Autor: KingdomOfJames
/// Descripción: Este código gestiona la lógica relacionada con el manejo de datos del usuario en la aplicación.
/// La clase `UserProvider` se encarga de interactuar con Firebase Firestore y Firebase Auth para obtener, actualizar y gestionar
/// los datos del usuario, como el tipo de usuario, la autenticación, la imagen de perfil, las búsquedas de usuarios,
/// y la gestión de la ubicación del usuario. Además, maneja funcionalidades relacionadas con la cuenta del usuario,
/// como la verificación del correo electrónico, la obtención de la fecha de creación de la cuenta y la actualización de los
/// datos en Firestore y en la base de datos local.
///
/// Recomendaciones:
/// - Asegúrese de manejar adecuadamente la autenticación y la verificación de los usuarios para evitar errores en el flujo de datos.
/// - Se recomienda implementar un sistema de manejo de errores más robusto para las operaciones de red y base de datos.
/// - Considerar agregar un mecanismo de caché para los datos del usuario para mejorar la experiencia de usuario, especialmente
///   en áreas de conexión lenta.
/// - Usar un sistema de control de acceso adecuado para evitar filtraciones de información sensible del usuario.
///
/// Características:
/// - Gestión del estado de los datos del usuario, como nombre, tipo de usuario, imagen de perfil y más.
/// - Soporte para operaciones de autenticación con Firebase y almacenamiento de información del usuario en Firestore.
/// - Funcionalidades adicionales como la verificación de correo electrónico y la obtención de la ubicación geográfica.
/// - Integración con una base de datos local para almacenar imágenes y perfiles.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/sources_repositories/imageRepository.dart';
import '../../sources/local/internal_data_base.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  final CachedDataDao _cachedDataDao;

  UserProvider({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required CachedDataDao cachedDataDao,
  }) : _firestore = firestore,
       _auth = auth,

       _cachedDataDao = cachedDataDao;

  // Variables de estado
  String _userType = 'Cargando...';
  String get userType => _userType;
  String? _deletionRequest;

  String _userName = 'Cargando...';
  String get userName => _userName;

  String _nickname = '';
  String get nickname => _nickname;

  String? _profileImageUrl;
  String? get profileImageUrl => _profileImageUrl;

  List<User> _searchResults = [];
  List<User> get searchResults => _searchResults;

  String _userId = '';
  String get userId => _userId;

  String _otherUserId = '';
  String get otherUserId => _otherUserId;

  bool _addFavorite = false;
  bool get addFavorite => _addFavorite;

  bool _addLike = false;
  bool get addLike => _addLike;

  List<String> _imageList = [];
  List<String> get imageList => _imageList;

  String? _menuSelection;
  String? get menuSelection => _menuSelection;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  String? _mode;
  String? _oobCode;
  bool _isVerified = false;

  String? get mode => _mode;
  String? get oobCode => _oobCode;
  bool get isVerified => _isVerified;

  // Agregar un método para actualizar el userType
  void setUserType(String newUserType) {
    _userType = newUserType;
    notifyListeners(); // Notifica a los widgets que dependen de este provider
  }

  set setNickname(String newNickname) {
    _nickname = newNickname;
    notifyListeners(); // Notifica a los listeners que el valor ha cambiado
  }

  // Setters públicos
  set userName(String value) {
    _userName = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  // Setters públicos
  set profileImageUrl(String? value) {
    _profileImageUrl = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  set searchResults(List<User> value) {
    _searchResults = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  set userId(String value) {
    _userId = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  String? get deletionRequest => _deletionRequest;

  set deletionRequest(String? request) {
    _deletionRequest = request;
    notifyListeners(); // Notificamos a los escuchadores cuando cambia el valor
  }

  set otherUserId(String value) {
    _otherUserId = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }


  set addFavorite(bool value) {
    _addFavorite = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  set addLike(bool value) {
    _addLike = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  set imageList(List<String> value) {
    _imageList = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  set menuSelection(String? value) {
    _menuSelection = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  set isAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  set mode(String? value) {
    _mode = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  set oobCode(String? value) {
    _oobCode = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  set isVerified(bool value) {
    _isVerified = value;
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  void initialize(Uri? data) {
    if (data != null) {
      _mode = data.queryParameters['mode'];
      _oobCode = data.queryParameters['oobCode'];
      notifyListeners();
    }
  }

  // Función para verificar el correo electrónico del usuario.
  Future<void> verifyEmail() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && _oobCode != null) {
      // Si el usuario está autenticado y el código de verificación es válido,
      // actualiza el campo 'isVerified' en Firestore.
      final userDocRef = _firestore.collection('users').doc(currentUser.uid);
      await userDocRef.update({'isVerified': true});
      _isVerified = true;
      notifyListeners(); // Notifica a los listeners que la verificación ha sido completada.
    }
  }

  // Esta función guarda la fecha de creación de la cuenta del usuario en Firestore.
  void saveAccountCreationDate() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);
      await userDocRef.update({
        'accountCreationDate': FieldValue.serverTimestamp(),
      });
    }
  }

  // Función para registrar a un nuevo usuario. Si el registro es exitoso, notifica a los listeners.
  Future<bool> registerUser(
    String email,
    String password,
    String role,
    String userName,
    String lastName,
  ) async {
    final success = await registerUser(
      email,
      password,
      role,
      userName,
      lastName,
    );
    if (success) {
      notifyListeners(); // Notifica a los listeners si el registro fue exitoso.
    }
    return success;
  }

  final String openCageApiKey = '36b67e51dc224a05afa8db6d5ef376f3';

  // Obtiene la ubicación del dispositivo y luego la dirección.
  Future<void> getCountryAndState() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await getAddressFromOpenCage(position.latitude, position.longitude);
    } catch (e) {
      print("Error obteniendo ubicación: $e");
    }
  }

  // Llama a OpenCage API para obtener país y estado.
  Future<void> getAddressFromOpenCage(double lat, double lon) async {
    try {
      final url =
          'https://api.opencagedata.com/geocode/v1/json?q=$lat+$lon&key=$openCageApiKey&language=es&pretty=1';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          final components = data['results'][0]['components'];
          String country = components['country'] ?? "desconocido";
          String state = components['state'] ?? "desconocido";

          // Normaliza (a minúsculas y sin acentos)
          country = removeAccents(country.toLowerCase());
          state = removeAccents(state.toLowerCase());

          await saveLocationToFirebase(country, state);
        }
      } else {
        print("Error de OpenCage API: ${response.body}");
      }
    } catch (e) {
      print("Error al llamar OpenCage: $e");
    }
  }

  // Guarda la ubicación en Firestore.
  Future<void> saveLocationToFirebase(String country, String state) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        Map<String, String> locationData = {'country': country, 'state': state};

        await firestore
            .collection("users")
            .doc(userId)
            .set(locationData, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error guardando en Firebase: $e");
    }
  }

  // Elimina acentos
  String removeAccents(String input) {
    const accents = 'áéíóúüñÁÉÍÓÚÜÑ';
    const replacements = 'aeiouunAEIOUUN';

    return input.characters.map((char) {
      final index = accents.indexOf(char);
      return index != -1 ? replacements[index] : char;
    }).join();
  }

  // Función pública para verificar si el tipo de usuario es 'Artist'.
  bool isUserTypeArtist(String userType) {
    return userType == 'Artist';
  }

  // Función para obtener el tipo de usuario desde Firestore.
  Future<void> fetchUserType() async {
    final user = _auth.currentUser;
    if (user == null) {
      return; // Si el usuario no está autenticado, no realiza nada.
    }

    try {
      final userDoc = await _firestore.collection("users").doc(user.uid).get();
      final userTypeValue = userDoc.data()?["userType"] as String?;

      if (userTypeValue != null) {
        _userType = userTypeValue;
      } else {
        _userType = ""; // Si no se encuentra un valor, se establece como vacío.
      }

      notifyListeners(); // Notifica a los listeners si el tipo de usuario ha cambiado.
    } catch (e) {
      // Si hay un error al obtener el tipo de usuario, se captura.
      _userType = "";
      notifyListeners();
    }
  }

  // Función para cambiar la selección del menú.
  void setMenuSelection(String selection) {
    _menuSelection = selection;
    notifyListeners(); // Notifica a los listeners sobre el cambio de selección.
  }

  // Función para obtener la URL de la imagen de perfil de Firestore.
  Future<void> fetchProfileImageUrl(String userId) async {
    try {
      final doc = await _firestore.collection("users").doc(userId).get();
      final url = doc.data()?["profileImageUrl"] as String?;

      _profileImageUrl = url;
      notifyListeners(); // Notifica a los listeners sobre el cambio de la URL de la imagen de perfil.
    } catch (e) {
      // Si hay un error al obtener la URL de la imagen, se captura.
      _profileImageUrl = null;
      notifyListeners();
    }
  }

  // Función para obtener y guardar la fecha de creación de la cuenta.
  Future<String> getAndSaveAccountCreationDate() async {
    final user = _auth.currentUser;
    if (user == null) {
      return "Usuario no autenticado"; // Si el usuario no está autenticado, retorna un mensaje.
    }

    final creationTimestamp = user.metadata.creationTime;
    if (creationTimestamp == null) {
      return "Fecha no disponible"; // Si no hay fecha de creación disponible, retorna un mensaje.
    }

    final formattedDate =
        "${creationTimestamp.day}/${creationTimestamp.month}/${creationTimestamp.year}";

    try {
      await _firestore.collection("users").doc(user.uid).update({
        "dateAccountCreate": creationTimestamp.millisecondsSinceEpoch,
      });
    } catch (e) {
      // Si hay un error al guardar la fecha de creación, se captura.
    }

    return formattedDate; // Retorna la fecha formateada.
  }

  // Función para obtener el nickname del usuario desde Firestore.
  Future<String?> getNicknameFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection("users").doc(userId).get();
      return doc.data()?["nickname"] as String?;
    } catch (e) {
      // Si hay un error al obtener el nickname, se captura.
      return null;
    }
  }

  // Función para obtener el perfil del usuario desde la base de datos local (Room).
  Future<Profile?> getProfileFromLocalDB(String userId) async {
    try {
      final db = await AppDatabase.getInstance();
      return await db.profileDao.getProfileById(userId);
    } catch (e) {
      // Si hay un error al obtener el perfil desde la base de datos local, se captura.
      return null;
    }
  }

  // Función para obtener y guardar el perfil del usuario desde Firestore a la base de datos local.
  Future<void> fetchAndSaveUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection("users").doc(userId).get();

      final name = doc.data()?["name"] as String?;
      final profileImageUrl = doc.data()?["profileImageUrl"] as String?;
      final isOfficial = doc.data()?["isOfficial"] as bool? ?? false;
      final nickname = doc.data()?["nickname"] as String?;

      if (name == null || nickname == null) {
        throw Exception("Nombre o nickname no encontrado");
      }

      final profile = Profile(
        userId: userId,
        profileImageUrl: profileImageUrl,
        name: name,
        nickname: nickname,
        isOfficial: isOfficial,
      );

      final db = await AppDatabase.getInstance();
      await db.profileDao.insertOrUpdate(profile);
    } catch (e) {
      // Si hay un error al obtener o guardar el perfil, se captura.
    }
  }

  // Función para obtener las imágenes del usuario desde la base de datos local.
  Future<void> getLocalImages(String userId) async {
    try {
      final db = await AppDatabase.getInstance();
      final localImages = await db.imageDao.getImagesByUser(userId);
      _imageList = localImages.map((img) => img.imageUrl).toList();
      notifyListeners(); // Notifica a los listeners sobre la actualización de la lista de imágenes.
    } catch (e) {
      // Si hay un error al obtener las imágenes desde la base de datos local, se captura.
    }
  }

  // Recuperar imágenes desde S3, vaciar la base de datos local y guardar las nuevas imágenes
  Future<void> fetchAndSaveImages(
    String userId,
    ImageRepository imageRepository,
  ) async {
    await imageRepository.deleteImagesByUser(
      userId,
    ); // Vaciar la base de datos local
    await imageRepository.fetchAndSaveImages(
      userId,
    ); // Llenar con nuevas imágenes
    await imageRepository.getLocalImages(
      userId,
    ); // Actualizar la lista en la interfaz de usuario
  }

  // Función para desbloquear a un usuario
  Future<void> unblockUser(String currentUserId, String userIdToUnblock) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Eliminar el ID del usuario bloqueado de la lista "blockedUsers" del usuario actual
      await firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([userIdToUnblock]),
      });

      // Eliminar el ID del usuario actual de la lista "usersWhoBlockedMe" del usuario bloqueado
      await firestore.collection('users').doc(userIdToUnblock).update({
        'usersWhoBlockedMe': FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {
      // Manejo de errores al desbloquear al usuario
    }
  }

  // Función para bloquear a un usuario
  void blockUser(String currentUserId, String otherUserId) {
    final db = FirebaseFirestore.instance;

    // Añadir otherUserId a la lista "blockedUsers" del usuario actual
    final currentUserRef = db.collection('users').doc(currentUserId);
    currentUserRef
        .update({
          'blockedUsers': FieldValue.arrayUnion([otherUserId]),
        })
        .catchError((e) {
          // Manejo de errores al añadir a "blockedUsers"
        });

    // Añadir currentUserId a la lista "usersWhoBlockedMe" del usuario bloqueado
    final otherUserRef = db.collection('users').doc(otherUserId);
    otherUserRef
        .update({
          'usersWhoBlockedMe': FieldValue.arrayUnion([currentUserId]),
        })
        .catchError((e) {
          // Manejo de errores al añadir a "usersWhoBlockedMe"
        });
  }

  // Función para actualizar el valor de otherUserId
  void updateOtherUserId(ValueNotifier<String> otherUserId) {
    otherUserId.value = '';
  }





  // Establecer el ID de otro usuario
  void setOtherUserId(String id) {
    _otherUserId = id;
    loadUserData(id);
  }

  // Cargar datos del usuario desde Firebase y guardar en la base de datos local
  void loadUserData(String userId) {
    final userRef = FirebaseFirestore.instance.collection("users").doc(userId);
    userRef.snapshots().listen((document) {
      if (document.exists) {
        final name = document.get("name") ?? "Nombre no disponible";
        final imageUrl = document.get("profileImageUrl") ?? "";
        final nickname = document.get("nickname") ?? "Sin apodo";

        // Guardar en la base de datos local
        _cachedDataDao.insert(
          CachedData(id: userId, content: "$name|$imageUrl"),
        );

        setNickname = nickname;
        userName = name;
        profileImageUrl = imageUrl;
      }
    });
  }

  // Obtener datos del usuario desde la base de datos local
  void getUserData(String userId) {
    _cachedDataDao.getById(userId).then((cachedData) {
      if (cachedData != null) {
        final parts = cachedData.content.split("|");
        userName = parts[0];
        profileImageUrl = parts[1];
      }
    });
  }

  // Autenticar al usuario
  void authenticateUser(ValueNotifier<bool> isAuthenticated) {
    isAuthenticated.value = true;
  }

  // Verificar si el usuario actual está bloqueado por otro usuario
  Future<bool> iAmBlocked(String currentUserId, String otherUserId) async {
    try {
      final currentUserDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(currentUserId)
              .get();

      final usersWhoBlockedMe =
          currentUserDoc.get("blockedUsers") as List<String>? ?? [];

      return usersWhoBlockedMe.contains(otherUserId);
    } catch (e) {
      // Manejo de errores
      return false;
    }
  }

  // Verificar si el usuario actual ha bloqueado a otro usuario
  Future<bool> isBlocked(String currentUserId, String otherUserId) async {
    try {
      final otherUserDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(otherUserId)
              .get();

      final blockedUsers =
          otherUserDoc.get("usersWhoBlockedMe") as List<String>? ?? [];

      return blockedUsers.contains(currentUserId);
    } catch (e) {
      // Manejo de errores
      return false;
    }
  }

  // Guardar el tipo de usuario en las preferencias compartidas
  Future<void> saveUserType(String userType) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("user_type", userType);
  }

  // Obtener el tipo de usuario desde las preferencias compartidas
  Future<String> getUserTypeFromPrefs() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString("user_type") ?? "contractor";
  }

  // Añadir estrellas a un usuario
  void addStars(String userId, int stars) {
    final firestore = FirebaseFirestore.instance;
    firestore
        .collection("UserStatistics")
        .doc(userId)
        .collection("phases")
        .doc("fase1")
        .collection("Statistics")
        .limit(1)
        .get()
        .then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            final documentPath = querySnapshot.docs.first.reference.path;
            final documentRef = firestore.doc(documentPath);

            documentRef.get().then((doc) {
              final currentStars = doc["stars"] ?? 0;
              documentRef.update({"stars": currentStars + stars});
            });
          }
        });
  }
// Añadir likes a un usuario
void addLikes(String userId) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  // Obtener el ID del usuario actual desde Firebase Auth
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Verificar que hay un usuario autenticado
  if (currentUserId == null) {
    print('No hay usuario autenticado');
    return;
  }

  QuerySnapshot querySnapshot = await firestore
      .collection("UserStatistics")
      .doc(userId)
      .collection("phases")
      .doc("fase1")
      .collection("Statistics")
      .limit(1)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    DocumentSnapshot firstDocument = querySnapshot.docs.first;
    String documentPath = firstDocument.reference.path;
    DocumentReference documentRef = firestore.doc(documentPath);
    DocumentReference userRef = firestore.collection("users").doc(userId);

    DocumentSnapshot document = await documentRef.get();
    if (document.exists) {
      List<String> userWhoLikedMeIds = [];

      DocumentSnapshot userDocument = await userRef.get();
      userWhoLikedMeIds = List<String>.from(
        userDocument.get("userWhoLikedMeIds") ?? [],
      );

      int currentLikes = (document.get("userLikes") ?? 0) as int;

      if (!userWhoLikedMeIds.contains(currentUserId)) {
        await documentRef.update({"userLikes": currentLikes + 1});
        await userRef.update({
          "userWhoLikedMeIds": FieldValue.arrayUnion([currentUserId]),
        });
      }
    }
  }
}

  // Subir estadísticas de usuario
  Future<void> uploadStatistics(String userId, int startDateMillis) async {
    final firestore = FirebaseFirestore.instance;
    final phaseStart = startDateMillis;
    final phaseDuration = Duration(days: 14).inMilliseconds;
    final phaseEnd = phaseStart + phaseDuration;
    final phaseId = "${formatDate(phaseStart)}--${formatDate(phaseEnd)}";

    final phasesColl = firestore
        .collection("UserStatistics")
        .doc(userId)
        .collection("phases");
    final phaseNames = ["fase1", "fase2", "fase3", "fase4", "faseFinal"];

    for (var name in phaseNames) {
      final statsRef = phasesColl.doc(name).collection("Statistics");
      final snap = await statsRef.get();

      if (snap.docs.isEmpty) {
        await statsRef.doc("Default").set({"Default": "default"});
        continue;
      }

      if (snap.docs.length >= 2 && snap.docs.any((d) => d.id == "Default")) {
        final defaultDoc = snap.docs.singleWhere((d) => d.id == "Default");
        await defaultDoc.reference.delete();
      }
    }

    final statsF1 = phasesColl.doc("fase1").collection("Statistics");
    final allF1 = await statsF1.get();
    final realF1 = allF1.docs.where((d) => d.id != "Default").toList();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (realF1.isNotEmpty) {
      final doc = realF1.first;
      final data = doc.data();
      final visits = (data["visits"] ?? 0) as int;
      final endRecovered = (data["phaseEndDate"] ?? 0) as int;
      final initialTs = (data["timestamp"] ?? now) as int;

      if (now < endRecovered) {
        final newVisits = visits + 1;
        final itemValue =
            (data["visits"] ?? 0) * 1 +
            (data["favorites"] ?? 0) * 10 +
            (data["stars"] ?? 0) * 10 +
            (data["userLikes"] ?? 0) * 5;

        await doc.reference.update({
          "visits": newVisits,
          "timestamp": initialTs,
          "phaseEndDate": endRecovered,
          "itemValue": itemValue,
        });
      } else {
        await statsF1.doc(phaseId).set({
          "visits": 1,
          "timestamp": now,
          "phaseEndDate": phaseEnd,
          "favorites": 0,
          "userLikes": 0,
          "stars": 0,
        });
      }
    } else {
      await statsF1.doc(phaseId).set({
        "visits": 1,
        "timestamp": now,
        "phaseEndDate": phaseEnd,
        "favorites": 0,
        "userLikes": 0,
        "stars": 0,
      });
    }

    await _moveOldestDocumentIfNeeded(userId);
  }

  Future<void> _moveOldestDocumentIfNeeded(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final phases = ["fase1", "fase2", "fase3", "fase4", "faseFinal"];
    final userRef = firestore.collection("users").doc(userId);

    double total = 0;
    for (var name in phases) {
      final snap =
          await firestore
              .collection("UserStatistics")
              .doc(userId)
              .collection("phases")
              .doc(name)
              .collection("Statistics")
              .get();
      for (var d in snap.docs) {
        total += (d.data()["itemValue"] ?? 0.0).toDouble();
      }
    }
    await userRef.update({"userValue": total});

    for (var i = 0; i < phases.length - 1; i++) {
      final cur = phases[i], next = phases[i + 1];
      final snap =
          await firestore
              .collection("UserStatistics")
              .doc(userId)
              .collection("phases")
              .doc(cur)
              .collection("Statistics")
              .get();

      final realDocs = snap.docs.where((d) => d.id != "Default").toList();
      if (realDocs.length > 1) {
        realDocs.sort((a, b) {
          final ta = (a.data()["timestamp"] ?? 0) as int;
          final tb = (b.data()["timestamp"] ?? 0) as int;
          return ta.compareTo(tb);
        });
        final oldest = realDocs.first;
        final data = Map<String, dynamic>.from(oldest.data());
        data["itemValue"] = (data["itemValue"] as double) * 0.8425;

        final dest = firestore
            .collection("UserStatistics")
            .doc(userId)
            .collection("phases")
            .doc(next)
            .collection("Statistics")
            .doc(oldest.id);

        await dest.set(data);
        await oldest.reference.delete();
      }
    }
  }

  String formatDate(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final format = DateFormat('dd-MM-yyyy');
    return format.format(date);
  }
}
