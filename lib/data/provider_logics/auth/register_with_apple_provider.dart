
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class RegisterWithAppleProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signInWithApple(
    BuildContext context,
    UserProvider userProvider,
    GoRouter goRouter,
    String userType, {
    dynamic services,
  }) async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null) {
        throw Exception("identityToken es null");
      }

      // Decodificar token JWT
      final jwtParts = identityToken.split('.');
      if (jwtParts.length != 3) {
        throw Exception("identityToken malformado.");
      }

      final payloadBase64 = base64.normalize(jwtParts[1]);
      final payloadJson = utf8.decode(base64Url.decode(payloadBase64));
      final payloadMap = json.decode(payloadJson);

      final aud = payloadMap['aud'];
      final tokenNonce = payloadMap['nonce'];
      final email = payloadMap['email'];
      final sub = payloadMap['sub'];

      // Validar nonce y aud
      if (tokenNonce != nonce) {
        throw Exception("Nonce mismatch");
      }
      if (aud != "com.jesse.live-music") {
        throw Exception("Aud mismatch");
      }

      final expSeconds = payloadMap['exp'];
      if (expSeconds == null) {
        throw Exception("Token sin expiración");
      } else {
        final expDate = DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);
        final now = DateTime.now();
        if (now.isAfter(expDate)) {
          throw Exception("Token expirado");
        }
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential authResult = await _auth.signInWithCredential(oauthCredential);
      final User? user = authResult.user;

      if (user == null) {
        throw Exception("Usuario Firebase null");
      }

      final userDocRef = _firestore.collection(AppStrings.usersCollection).doc(user.uid);
      final doc = await userDocRef.get();

      if (doc.exists) {
        final isRegistered = doc.data()?[AppStrings.isRegisteredField] ?? false;
        final existingUserType = doc.data()?[AppStrings.userTypeField];

        if (isRegistered) {
          if (existingUserType != userType) {
            _showUserTypeMismatchDialog(context, goRouter);
          } else {
            _showAlreadyRegisteredDialog(context, goRouter);
          }
        } else {
          await userDocRef.update({
            AppStrings.isRegisteredField: true,
            AppStrings.userTypeField: userType,
            AppStrings.registerNameField: user.displayName ?? AppStrings.noName,
            if (services != null) 'services': services,
          });
          userProvider.saveAccountCreationDate();
          _goToCorrectScreen(userType, goRouter);
        }
      } else {
        await userDocRef.set({
          AppStrings.isRegisteredField: true,
          AppStrings.userTypeField: userType,
          AppStrings.emailField: user.email,
          AppStrings.registerNameField: user.displayName ?? AppStrings.noName,
          AppStrings.isVerifiedField: true,
          if (services != null) 'services': services,
        });
        userProvider.saveAccountCreationDate();
        _goToCorrectScreen(userType, goRouter);
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      _showErrorSnack(context);
    } on FirebaseAuthException catch (e) {
      _showErrorSnack(context);
    } catch (e, stack) {
      _showErrorSnack(context);
    }
  }

  void _showErrorSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.appleSignInFailed)),
    );
  }

  String _generateNonce([int length = 32]) {
    final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _showAlreadyRegisteredDialog(BuildContext context, GoRouter goRouter) {
    final colorScheme = ColorPalette.getPalette(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme[AppStrings.primaryColor],
        title: Text(
          AppStrings.accountRegisteredTitle,
          style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
        ),
        content: Text(
          AppStrings.accountRegisteredContent,
          style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.no, style: TextStyle(color: colorScheme[AppStrings.secondaryColor])),
          ),
          TextButton(
            onPressed: () {
              goRouter.go(AppStrings.loginOptionsScreenRoute);
              Navigator.of(context).pop();
            },
            child: Text(AppStrings.yes, style: TextStyle(color: colorScheme[AppStrings.secondaryColor])),
          ),
        ],
      ),
    );
  }

  void _showUserTypeMismatchDialog(BuildContext context, GoRouter goRouter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.unblockUserTitle),
        content: const Text(AppStrings.unblockUserMessage),
        actions: [
          TextButton(
            onPressed: () {
              goRouter.go(AppStrings.loginOptionsScreenRoute);
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.accept),
          ),
        ],
      ),
    );
  }

  void _goToCorrectScreen(String userType, GoRouter goRouter) {
    goRouter.go(AppStrings.ageTermsScreenRoute);
  }
}