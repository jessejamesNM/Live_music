// ─────────────────────────────────────────────────────────────────────────────
// Created: 2025-04-26
// Author: KingdomOfJames
// Description:
// This provider manages the initial onboarding process for a user after registration.
// It handles the selection of the user's musical specialty, genres, countries and states
// they can work in, price settings, and uploading images related to their work or profile.
// It interacts heavily with Firebase Authentication and Firestore,
// and ensures navigation flow based on completed user data.
//
// Recommendations:
// - Split some functionalities (like image uploading) into separate providers/services
//   to respect the Single Responsibility Principle (SRP) and keep this class more focused.
// - Consider adding try-catch blocks and better error handling to all async operations.
// - Replace nested `WidgetsBinding.instance.addPostFrameCallback` with cleaner state control.
// - Apply more granular state management if the provider grows too large.
//
// Key Features:
// - Show splash screens and welcome messages during first app launch.
// - Select and save a specialty (musical event type).
// - Manage musical genres the user can work with.
// - Select and save countries and states where the user can operate.
// - Upload and save work and profile images to the server.
// - Ensure proper navigation based on user data completeness.
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:live_music/data/repositories/render_http_client/images/upload_work_image.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../repositories/render_http_client/images/upload_profile_image.dart';
import '../user/user_provider.dart';
import 'package:go_router/go_router.dart';

class BeginningProvider with ChangeNotifier {
  String? selectedEvent;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _showLoading = true;
  bool _showReadyMessage = false;
  bool _showWelcomeMessage = false;

  bool get showLoading => _showLoading;
  bool get showReadyMessage => _showReadyMessage;
  bool get showWelcomeMessage => _showWelcomeMessage;

  BeginningProvider() {
    _init();
  }
  String? _routeToGo;

  String? get routeToGo => _routeToGo;

  void setRouteToGo(String route) {
    _routeToGo = route;
    notifyListeners();
  }

  Future<void> _init() async {
    await Future.delayed(Duration(seconds: 3));
    _showLoading = false;
    _showReadyMessage = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.microtask(() => notifyListeners());
        });
      });
    });
    await Future.delayed(Duration(seconds: 1, milliseconds: 500));
    _showReadyMessage = false;
    _showWelcomeMessage = true;
    Future.microtask(() => notifyListeners());
  }

  Future<void> updatePrice(String tarifa) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId != null) {
      final priceInt = int.tryParse(tarifa) ?? 0;
      await db.collection('users').doc(currentUserId).update({
        'price': priceInt,
      });
    }
  }

  void selectEvent(String event) {
    if (selectedEvent == event) {
      selectedEvent = null;
    } else {
      selectedEvent = event;
    }
    Future.microtask(() => notifyListeners());
  }

  void saveSpecialty(BuildContext context, GoRouter goRouter) {
    if (selectedEvent != null && currentUserId != null) {
      db.collection(AppStrings.usersCollection).doc(currentUserId).update({
        AppStrings.specialtyField: selectedEvent,
      });
      goRouter.go(AppStrings.priceScreenRoute);
    }
  }

  List<String> _selectedGenres = [];

  List<String> get selectedGenres => _selectedGenres;

  void toggleGenre(String genre) {
    if (_selectedGenres.contains(genre)) {
      _selectedGenres.remove(genre);
    } else {
      _selectedGenres.add(genre);
    }
    notifyListeners();
  }

  Future<void> saveGenres(BuildContext context, GoRouter goRouter) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await db.collection('users').doc(user.uid).update({
          'genres': _selectedGenres,
        });
        goRouter.go("/eventspecializationscreen");
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Usuario no autenticado')));
    }
  }

  List<String> _selectedCountries = [];
  List<String> _selectedStates = [];
  bool _countryExpanded = false;
  bool _stateExpanded = false;
  bool _includeAllStatesOption = false;
  String _selectedCountry = '';
  String _selectedState = '';
  List<String> get selectedCountries => _selectedCountries;
  List<String> get selectedStates => _selectedStates;
  bool get countryExpanded => _countryExpanded;
  bool get stateExpanded => _stateExpanded;
String get selectedCountry => _selectedCountry;
String get selectedState => _selectedState;
  List<String> get countries => ["mexico", "united states"];
  List<String> get statesMexico =>
      AppStrings.statesMX; // Instanciado desde AppStrings
  List<String> get statesUS =>
      AppStrings.statesUS; // Instanciado desde AppStrings

  List<String> _getStates() {
    switch (_selectedCountries.length == 1 ? _selectedCountries[0] : null) {
      case "mexico":
        return _includeAllStatesOption
            ? ["Todos los estados"] + statesMexico
            : statesMexico;
      case "united states":
        return _includeAllStatesOption
            ? ["Todos los estados"] + statesUS
            : statesUS;
      default:
        return [];
    }
  }

  List<String> _getOneStates() {
    switch (_selectedCountry.isNotEmpty ? _selectedCountry : null) {
      case "mexico":
        return statesMexico;
      case "united states":
        return statesUS;
      default:
        return [];
    }
  }
  void removeState(String state) {
    _selectedStates.remove(state);
    notifyListeners();
  }

  List<String> get states => _getStates();
  List<String> get oneStates => _getOneStates();
  void removeCountry(String country) {
    _selectedCountries.remove(country);
    // Si se quita un país, reiniciar los estados seleccionados
    _selectedStates.clear();
    notifyListeners();
  }

  void setIncludeAllStatesOption(bool value) {
    _includeAllStatesOption = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
void selectOneCountry(String country) {
  if (_selectedCountry.isEmpty || _selectedCountry != country) {
    _selectedCountry = country; // reemplaza cualquier valor previo
    _selectedStates.clear();        // limpiar estados al cambiar país
  }
  notifyListeners();
}

  void selectCountry(String country) {
    if (_selectedCountries.contains(country)) {
      _selectedCountries.remove(country);
    } else {
      _selectedCountries.add(country);
    }
    notifyListeners();
  }
void selectOneState(String state) {
  if (_selectedState == state) {
    _selectedState = '';
  } else {
    _selectedState = state;
  }
  notifyListeners();
}
  void selectState(String state) {
    if (_selectedStates.contains(state)) {
      _selectedStates.remove(state);
    } else {
      _selectedStates.add(state);
    }
    notifyListeners();
  }

  void toggleCountryExpanded() {
    _countryExpanded = !_countryExpanded;
    notifyListeners();
  }

  void toggleStateExpanded() {
    _stateExpanded = !_stateExpanded;
    notifyListeners();
  }

  Future<void> saveSelectionStateAndCountry(
    BuildContext context,
    GoRouter goRouter,
  ) async {
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;
    final currentUserId = auth.currentUser?.uid;

    if (currentUserId == null) return;

    try {
      // 1. ACTUALIZACIÓN (siempre se hace)
      await db.collection("users").doc(currentUserId).update({
        "country": _selectedCountry, // Campo singular (string)
        "state": _selectedState, // Campo singular (string)
      });

      // 2. VERIFICACIÓN (para navegación)
      final userDoc = await db.collection("users").doc(currentUserId).get();
      final userData = userDoc.data();

      final hasCountry = (userData?['country'] as String?)?.isNotEmpty ?? false;
      final hasState = (userData?['state'] as String?)?.isNotEmpty ?? false;

      // 3. NAVEGACIÓN (según verificación)
      if (hasCountry && hasState) {
        goRouter.go(AppStrings.welcomeScreenRoute);
      } else {
        goRouter.go(AppStrings.countryStateScreenRoute);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar la selección: ${e.toString()}"),
        ),
      );
    }
  }
Future<void> saveSelection(BuildContext context, GoRouter goRouter) async {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;
  final currentUserId = auth.currentUser?.uid;

  if (currentUserId == null) return;

  try {
    // Verificamos si hay más de 1 país seleccionado
    final isMultipleCountries = _selectedCountries.length > 1;

    // Si hay más de un país, forzamos que se guarde "Todos los estados"
    final statesToSave = isMultipleCountries
        ? ['Todos los estados']
        : _selectedStates;

    // Guardamos en Firestore
    await db.collection(AppStrings.usersCollection).doc(currentUserId).update(
      {
        AppStrings.countries: _selectedCountries,
        AppStrings.states: statesToSave,
      },
    );

    // Verificación y navegación
    final userDoc = await db.collection("users").doc(currentUserId).get();
    final userData = userDoc.data();

    final hasCountries =
        (userData?[AppStrings.countries] as List?)?.isNotEmpty ?? false;
    final hasStates =
        (userData?[AppStrings.states] as List?)?.isNotEmpty ?? false;

    if (hasCountries && hasStates) {
      goRouter.go(AppStrings.welcomeScreenRoute);
    } else {
      goRouter.go(AppStrings.countryStateScreenRoute);
    }
  } catch (e) {
    // Manejo de errores (puedes mostrar un SnackBar o log)
    debugPrint("Error al guardar selección: $e");
  }
}
  Future<String?> uploadWorkImageToServer(
    BuildContext context,
    File file,
    String userId,
  ) async {
    try {
      final uploadResponse = await RetrofitInstanceForWorks().apiServiceForWorks
          .uploadImage(file, userId);
      if (uploadResponse.url != null) {
        return uploadResponse.url;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> saveWorkImageUrl(String userId, String uploadedImageUrl) async {
    DocumentReference userRef = db.collection('users').doc(userId);
    DocumentSnapshot document = await userRef.get();

    if (document.exists) {
      await userRef.update({
        'workImageUrls': FieldValue.arrayUnion([uploadedImageUrl]),
      });
    } else {
      await userRef.set({
        'workImageUrls': [uploadedImageUrl],
      });
    }
  }

  Future<List<String>?> loadWorkImageUrls(String userId) async {
    DocumentSnapshot document = await db.collection('users').doc(userId).get();
    final data = document.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('workImageUrls')) {
      return List<String>.from(data['workImageUrls']);
    } else {
      return null;
    }
  }

  Future<String?> uploadProfileImage(
    BuildContext context,
    File file,
    String userId,
  ) async {
    try {
      final uploadResponse = await RetrofitClient().apiService
          .uploadProfileImage(file, userId);
      if (uploadResponse.url != null) {
        return uploadResponse.url;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> saveProfileImageUrl(
    String userId,
    String uploadedImageUrl,
  ) async {
    DocumentReference userRef = db.collection('users').doc(userId);
    DocumentSnapshot document = await userRef.get();

    if (document.exists) {
      await userRef.update({'profileImageUrl': uploadedImageUrl});
    } else {
      await userRef.set({'profileImageUrl': uploadedImageUrl});
    }
  }

  Future<String?> loadProfileImageUrl(String userId) async {
    DocumentSnapshot document = await db.collection('users').doc(userId).get();
    final data = document.data() as Map<String, dynamic>?;
    return data?['profileImageUrl'] as String?;
  }

  String validateNickname(String name) {
    String trimmedName = name.trim();
    bool hasInvalidChars = !RegExp(r'^[a-zA-ZñÑ0-9_]*$').hasMatch(trimmedName);
    bool isEmpty = trimmedName.isEmpty;
    bool hasSpaces = trimmedName.contains(' ');
    bool lengthValid = trimmedName.length >= 3 && trimmedName.length <= 22;

    if (isEmpty) {
      return 'El apodo no puede estar vacío';
    } else if (hasSpaces) {
      return 'El apodo no puede contener espacios';
    } else if (hasInvalidChars) {
      return 'El apodo solo puede contener letras, números, guiones bajos y la letra ñ';
    } else if (!lengthValid) {
      return 'El apodo debe contener entre 3 y 22 caracteres';
    } else {
      return '';
    }
  }

  Future<bool> isNicknameAvailable(String name) async {
    QuerySnapshot querySnapshot =
        await db.collection('users').where('nickname', isEqualTo: name).get();
    return querySnapshot.docs.isEmpty;
  }

  Future<void> saveNickname(
    String nickname,
    BuildContext context,
    GoRouter goRouter,
    String routeToGo,
  ) async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userRef = db.collection('users').doc(user.uid);
      try {
        await userRef.update({'nickname': nickname});
        goRouter.go(routeToGo);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar el apodo')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Usuario no autenticado')));
    }
  }

Future<void> checkAndSaveUserLocation(
  BuildContext context,
  GoRouter goRouter,
) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .get();

  if (userDoc.exists && userDoc.data()?['country'] != null) return;

  final permissionStatus = await Permission.location.status;

  if (permissionStatus.isGranted) {
    await _handleLocationAccess(context, currentUser.uid);
  } else if (permissionStatus.isDenied) {
    final newStatus = await Permission.location.request();
    if (newStatus.isGranted) {
      await _handleLocationAccess(context, currentUser.uid);
    } else {
      goRouter.go(AppStrings.countryStateScreenRoute);
    }
  } else if (permissionStatus.isPermanentlyDenied) {
    Navigator.pushNamed(context, AppStrings.countryStateScreenRoute);
  }
}
void clearStates() {
  selectedStates.clear();
  notifyListeners();
}
Future<void> _handleLocationAccess(
  BuildContext context,
  String userId,
) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final enableLocation = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ubicación requerida'),
          content: const Text('Necesitamos acceso a tu ubicación para continuar'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: const Text('Activar'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (enableLocation != true) {
        Navigator.pop(context);
        return;
      }

      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Navigator.pop(context);
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Navigator.pop(context);

    if (placemarks.isEmpty || placemarks.first.country == null) {
      _redirectToManualLocationInput(context);
      return;
    }

    final place = placemarks.first;

    String country = normalize(place.country ?? '');
    String state = normalize(place.administrativeArea ?? '');

    // Mapeo manual
    state = getFullStateName(country, state);

    if (country.isEmpty) {
      _redirectToManualLocationInput(context);
      return;
    }

    print("Ubicación normalizada: $country, $state");

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'country': country,
      'state': state,
      'locationSource': 'automatic',
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    Navigator.pop(context);
    _redirectToManualLocationInput(context);
  }
}

void _redirectToManualLocationInput(BuildContext context) {
  Navigator.pushNamed(context, AppStrings.countryStateScreenRoute);
}

String normalize(String input) {
  final withNoDiacritics = input
      .toLowerCase()
      .replaceAllMapped(RegExp(r'[áàäâã]'), (_) => 'a')
      .replaceAllMapped(RegExp(r'[éèëê]'), (_) => 'e')
      .replaceAllMapped(RegExp(r'[íìïî]'), (_) => 'i')
      .replaceAllMapped(RegExp(r'[óòöôõ]'), (_) => 'o')
      .replaceAllMapped(RegExp(r'[úùüû]'), (_) => 'u')
      .replaceAllMapped(RegExp(r'ñ'), (_) => 'n');
  return withNoDiacritics
      .split(' ')
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String getFullStateName(String country, String inputState) {
  final estadosMX = {
    "Baja California": "Baja California",
    "Baja California Sur": "Baja California Sur",
    "Campeche": "Campeche",
    "Chiapas": "Chiapas",
    "Chihuahua": "Chihuahua",
    "Coahuila": "Coahuila",
    "Colima": "Colima",
    "Durango": "Durango",
    "Estado De Mexico": "Estado de Mexico",
    "Guanajuato": "Guanajuato",
    "Guerrero": "Guerrero",
    "Hidalgo": "Hidalgo",
    "Jalisco": "Jalisco",
    "Michoacan": "Michoacan",
    "Morelos": "Morelos",
    "Nayarit": "Nayarit",
    "Nuevo Leon": "Nuevo Leon",
    "Oaxaca": "Oaxaca",
    "Puebla": "Puebla",
    "Queretaro": "Queretaro",
    "Quintana Roo": "Quintana Roo",
    "San Luis Potosi": "San Luis Potosi",
    "Sinaloa": "Sinaloa",
    "Sonora": "Sonora",
    "Tabasco": "Tabasco",
    "Tamaulipas": "Tamaulipas",
    "Tlaxcala": "Tlaxcala",
    "Veracruz": "Veracruz",
    "Yucatan": "Yucatan",
    "Zacatecas": "Zacatecas",
  };

  final estadosUS = {
    "Alabama": "Alabama",
    "Alaska": "Alaska",
    "Arizona": "Arizona",
    "Arkansas": "Arkansas",
    "California": "California",
    "Colorado": "Colorado",
    "Connecticut": "Connecticut",
    "Delaware": "Delaware",
    "Florida": "Florida",
    "Georgia": "Georgia",
    "Hawaii": "Hawai",
    "Idaho": "Idaho",
    "Illinois": "Illinois",
    "Indiana": "Indiana",
    "Iowa": "Iowa",
    "Kansas": "Kansas",
    "Kentucky": "Kentucky",
    "Louisiana": "Luisiana",
    "Maine": "Maine",
    "Maryland": "Maryland",
    "Massachusetts": "Massachusetts",
    "Michigan": "Michigan",
    "Minnesota": "Minnesota",
    "Mississippi": "Misisipi",
    "Missouri": "Misuri",
    "Montana": "Montana",
    "Nebraska": "Nebraska",
    "Nevada": "Nevada",
    "New Hampshire": "Nuevo Hampshire",
    "New Jersey": "Nueva Jersey",
    "New Mexico": "Nuevo Mexico",
    "New York": "Nueva York",
    "North Carolina": "Carolina del Norte",
    "North Dakota": "Dakota del Norte",
    "Ohio": "Ohio",
    "Oklahoma": "Oklahoma",
    "Oregon": "Oregon",
    "Pennsylvania": "Pensilvania",
    "Rhode Island": "Rhode Island",
    "South Carolina": "Carolina del Sur",
    "South Dakota": "Dakota del Sur",
    "Tennessee": "Tennessee",
    "Texas": "Texas",
    "Utah": "Utah",
    "Vermont": "Vermont",
    "Virginia": "Virginia",
    "Washington": "Washington",
    "West Virginia": "Virginia Occidental",
    "Wisconsin": "Wisconsin",
    "Wyoming": "Wyoming",
  };

  final normalized = inputState.trim();

  if (country == "Mexico" && estadosMX.containsKey(normalized)) {
    return estadosMX[normalized]!;
  }
  if (country == "United States" && estadosUS.containsKey(normalized)) {
    return estadosUS[normalized]!;
  }

  return normalized;
}
  Future<void> checkUserLocation(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final userDoc = await db.collection('users').doc(user.uid).get();

      // Si el documento no existe o no tiene país
      if (!userDoc.exists || userDoc.get('country') == null) {
        await _handleLocationAccess(context, user.uid);
        return;
      }

      final country = userDoc.get('country')?.toString().trim() ?? '';

      if (country.isEmpty) {
        await _handleLocationAccess(context, user.uid);
      } else {
        // Verificar si la ubicación es muy antigua (> 30 días)
        final lastUpdate = userDoc.get('lastLocationUpdate') as Timestamp?;
        if (lastUpdate == null ||
            DateTime.now().difference(lastUpdate.toDate()).inDays > 30) {
          await _handleLocationAccess(context, user.uid);
        }
      }
    } catch (e) {
      await _handleLocationAccess(context, user.uid);
    }
  }

  String validateName(String name) {
    String trimmedName = name.trim();
    bool hasDoubleSpace = name.contains('  ');
    bool lengthValid = trimmedName.length >= 6 && trimmedName.length <= 22;

    if (hasDoubleSpace && !lengthValid) {
      return 'No se permite espacio doble en el nombre y el nombre debe contener entre 6 y 22 dígitos';
    } else if (hasDoubleSpace) {
      return 'No se permite espacio doble en el nombre';
    } else if (!lengthValid) {
      return 'El nombre debe contener entre 6 y 22 dígitos';
    } else {
      return '';
    }
  }

  Future<void> saveName(
    String groupName,
    BuildContext context,
    GoRouter goRouter,
    String routeToGo,
  ) async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userRef = db.collection('users').doc(user.uid);
      await userRef
          .update({'name': groupName})
          .then((_) {
            // Usando el router.go para navegar
            goRouter.go(routeToGo);
          })
          .catchError((e) {});
    }
  }

  Future<String?> getEmail() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc =
            await db.collection('users').doc(currentUser.uid).get();
        return userDoc.get('email');
      } catch (e) {
        return "Error al obtener el correo electrónico.";
      }
    } else {
      return "Usuario no autenticado.";
    }
  }
}
