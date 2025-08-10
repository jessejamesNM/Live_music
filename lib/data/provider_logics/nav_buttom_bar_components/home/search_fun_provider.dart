// Created on: 2025-04-26
// Author: KingdomOfJames
// Description:
// This code implements the logic for searching and matching users based on their nickname and name.
// The main functionality includes searching users from a Firestore database, calculating the similarity between
// the search string and user information, and displaying the results with user details (such as name, nickname,
// profile image, and price).
// The match calculation prioritizes exact matches on nicknames over names and also filters out blocked users.
// Characteristics:
// - Fetches user data from Firestore.
// - Uses a similarity algorithm to compare user names and nicknames to the search query.
// - Sorts the results based on match criteria.
// - Displays user profile details, including profile image and pricing.
// - Filters blocked users.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../user/user_provider.dart';
import 'package:flutter/cupertino.dart';

enum MatchSource { NICKNAME, NAME }

// Representa la información de un usuario coincidente.
class UserMatchInfo {
  final String userId;
  final String name;
  final MatchSource matchSource;
  final int primaryMatchingLetters;
  final int primaryNonMatchingLetters;
  final int nickMatchingLetters;
  final int nickNonMatchingLetters;

  UserMatchInfo({
    required this.userId,
    required this.name,
    required this.matchSource,
    required this.primaryMatchingLetters,
    required this.primaryNonMatchingLetters,
    required this.nickMatchingLetters,
    required this.nickNonMatchingLetters,
  });
}

// Representa a un usuario con su ID, apodo, nombre y tipo de usuario.
class User {
  final String userId;
  final String nickname;
  final String name;
  final String userType;

  User(this.userId, this.nickname, this.name, this.userType);
}

// Contiene los datos completos de un usuario, como el ID, nombre, apodo, imagen de perfil y precio.
class UserData {
  final String userId;
  final String name;
  final String nickname;
  final String profileImageUrl;
  final double price;

  UserData({
    required this.userId,
    required this.name,
    required this.nickname,
    required this.profileImageUrl,
    required this.price,
  });
}

// Clase que maneja la lógica de búsqueda de usuarios y proporciona los detalles.
class SearchFunProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserData> userDataList = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  bool get isLoading => _isLoading;
  bool get hasSearched => _hasSearched;

  // Método para buscar usuarios en Firestore basado en una cadena de búsqueda.
  Future<void> searchUsers(String searchString) async {
    _isLoading = true;
    _hasSearched = true;
    notifyListeners();

    try {
      final users = await _getArtistsFromFirestore();
      final matchingUsers = _findMatchingUsers(
        users,
        searchString.toLowerCase(),
      );

      await _loadUserDetails(matchingUsers);
    } catch (e) {
      userDataList.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método que consulta Firestore para obtener una lista de usuarios del tipo 'artist'.
  Future<List<User>> _getArtistsFromFirestore() async {
    try {
      final query =
          await _firestore
              .collection('users')
              .where('userType', isEqualTo: 'artist')
              .get();

      return query.docs
          .where(
            (doc) =>
                doc.data().containsKey('nickname') &&
                doc.data().containsKey('name'),
          )
          .map(
            (doc) => User(
              doc.id,
              doc.get('nickname'),
              doc.get('name'),
              doc.get('userType'),
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Método que encuentra usuarios que coinciden con la cadena de búsqueda.
  List<UserMatchInfo> _findMatchingUsers(List<User> users, String lowerSearch) {
    final matches =
        users
            .map((user) => _calculateUserMatch(user, lowerSearch))
            .whereType<UserMatchInfo>()
            .toList()
          ..sort(_compareMatches);
    return matches;
  }

  // Calcula el grado de coincidencia entre un usuario y la cadena de búsqueda.
  UserMatchInfo? _calculateUserMatch(User user, String lowerSearch) {
    final nickLower = user.nickname.toLowerCase();
    final nameLower = user.name.toLowerCase();

    final nickSimilarity = _calculateSimilarity(lowerSearch, nickLower);
    final nameSimilarity = _calculateSimilarity(lowerSearch, nameLower);

    if (nickSimilarity == null && nameSimilarity == null) {
      return null;
    }

    final source =
        nickSimilarity != null ? MatchSource.NICKNAME : MatchSource.NAME;
    final match = nickSimilarity ?? nameSimilarity!;

    final nickScore = nickSimilarity ?? Pair(0, double.maxFinite.toInt());

    return UserMatchInfo(
      userId: user.userId,
      name: user.name,
      matchSource: source,
      primaryMatchingLetters: match.first,
      primaryNonMatchingLetters: match.second,
      nickMatchingLetters: nickScore.first,
      nickNonMatchingLetters: nickScore.second,
    );
  }

  // Compara dos coincidencias de usuarios basándose en los criterios de coincidencia.
  int _compareMatches(UserMatchInfo a, UserMatchInfo b) {
    final sourceCompare = b.matchSource.index.compareTo(a.matchSource.index);
    if (sourceCompare != 0) return sourceCompare;

    final primaryMatchCompare = b.primaryMatchingLetters.compareTo(
      a.primaryMatchingLetters,
    );
    if (primaryMatchCompare != 0) return primaryMatchCompare;

    final primaryNonMatchCompare = a.primaryNonMatchingLetters.compareTo(
      b.primaryNonMatchingLetters,
    );
    if (primaryNonMatchCompare != 0) return primaryNonMatchCompare;

    final nickMatchCompare = b.nickMatchingLetters.compareTo(
      a.nickMatchingLetters,
    );
    if (nickMatchCompare != 0) return nickMatchCompare;

    return a.nickNonMatchingLetters.compareTo(b.nickNonMatchingLetters);
  }

  // Carga los detalles completos de los usuarios que coinciden.
  Future<void> _loadUserDetails(List<UserMatchInfo> matchingUsers) async {
    userDataList.clear();

    for (final match in matchingUsers) {
      try {
        final doc =
            await _firestore.collection('users').doc(match.userId).get();
        if (doc.exists &&
            doc.data()!.containsKey('nickname') &&
            doc.data()!.containsKey('name')) {
          userDataList.add(
            UserData(
              userId: match.userId,
              name: doc.get('name'),
              nickname: doc.get('nickname'),
              profileImageUrl: doc.get('profileImageUrl') ?? '',
              price: (doc.get('price') as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
      } catch (e) {
        // Manejo de errores de carga de datos de usuario.
      }
    }
  }

  // Calcula el grado de similitud entre la cadena de búsqueda y el nombre o apodo.
  Pair<int, int>? _calculateSimilarity(String search, String target) {
    final searchLength = search.length;
    final targetLength = target.length;
    var matchingLetters = 0;
    var nonMatchingLetters = 0;

    if (target.contains(search)) {
      matchingLetters = searchLength;
      nonMatchingLetters = 0;
    } else {
      for (var i = 0; i < searchLength; i++) {
        if (i < targetLength) {
          if (search[i] == target[i])
            matchingLetters++;
          else
            nonMatchingLetters++;
        } else {
          nonMatchingLetters++;
        }
      }
      if (targetLength > searchLength) {
        nonMatchingLetters += targetLength - searchLength;
      }
    }

    final allowedNonMatching = (0.8 * matchingLetters).floor();
    final result =
        nonMatchingLetters <= allowedNonMatching
            ? Pair(matchingLetters, nonMatchingLetters)
            : null;
    return result;
  }

  // Filtra los usuarios bloqueados, eliminándolos de la lista.
  Future<List<String>> filterBlockedUsers(
    UserProvider userProvider,
    String currentUserId,
    List<String> userIds,
  ) async {
    final filtered = <String>[];

    for (final userId in userIds) {
      final isBlocked = await userProvider.isBlocked(currentUserId, userId);
      final iAmBlocked = await userProvider.iAmBlocked(currentUserId, userId);

      if (!isBlocked && !iAmBlocked) {
        filtered.add(userId);
      }
    }

    return filtered;
  }
}

// Clase que representa un par de elementos genéricos.
class Pair<T1, T2> {
  final T1 first;
  final T2 second;

  Pair(this.first, this.second);
}
