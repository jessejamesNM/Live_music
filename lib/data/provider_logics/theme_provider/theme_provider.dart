import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AppTheme { light, dark, system }

class ThemeProvider with ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AppTheme _currentTheme = AppTheme.system;
  bool _isLoading = true;

  ThemeProvider({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  AppTheme get currentTheme => _currentTheme;
  bool get isLoading => _isLoading;

  /// Inicializa el tema leyendo desde Firebase o usa el sistema por defecto
  Future<void> initializeTheme() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          final themePref = userDoc.data()?['themePreference'];

          switch (themePref) {
            case 'light':
              _currentTheme = AppTheme.light;
              break;
            case 'dark':
              _currentTheme = AppTheme.dark;
              break;
            default:
              _currentTheme = AppTheme.system;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambia el tema y lo guarda en Firebase
  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final themeValue = theme.name; // usa name en lugar del switch
        await _firestore.collection('users').doc(currentUser.uid).set({
          'themePreference': themeValue,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Devuelve el ThemeMode para el MaterialApp
  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }
}
