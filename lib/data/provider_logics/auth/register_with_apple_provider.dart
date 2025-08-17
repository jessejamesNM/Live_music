
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
const String _kProviderId = 'apple.com';
 
 class RegisterWithAppleProvider extends AuthProvider {
 RegisterWithAppleProvider() : super(_kProviderId);
 
 // Métodos estáticos para credenciales
 static OAuthCredential credential(String accessToken) {
 return AppleAuthCredential._credential(accessToken);
 }
 
 static OAuthCredential credentialWithIDToken(
 String idToken,
 String rawNonce,
 AppleFullPersonName appleFullPersonName,
 ) {
 return AppleAuthCredential._credentialWithIDToken(
 idToken, 
 rawNonce, 
 appleFullPersonName
 );
 }
 
 // Propiedades estáticas
 static String get APPLE_SIGN_IN_METHOD => _kProviderId;
 static String get PROVIDER_ID => _kProviderId;
 
 // Instancia de Firebase
 final FirebaseAuth _auth = FirebaseAuth.instance;
 final FirebaseFirestore _firestore = FirebaseFirestore.instance;
 
 // Método principal de registro corregido
 Future<void> signInWithApple({
 required BuildContext context,
 required UserProvider userProvider,
 required GoRouter goRouter,
 required String userType,
 dynamic services,
 }) async {
 try {
 // 1. Generar nonce para seguridad
 final rawNonce = _generateNonce();
 final nonce = _sha256ofString(rawNonce);
 
 // 2. Solicitar credenciales de Apple
 final appleCredential = await SignInWithApple.getAppleIDCredential(
 scopes: [
 AppleIDAuthorizationScopes.email,
 AppleIDAuthorizationScopes.fullName,
 ],
 nonce: nonce,
 );
 
 // 3. Verificar token
 if (appleCredential.identityToken == null) {
 throw Exception("No se pudo obtener el token de identidad de Apple");
 }
 
 // 4. Crear credencial para Firebase
 final oauthCredential = OAuthProvider(_kProviderId).credential(
 idToken: appleCredential.identityToken,
 rawNonce: rawNonce,
 accessToken: appleCredential.authorizationCode,
 );
 
 // 5. Autenticar con Firebase
 final authResult = await _auth.signInWithCredential(oauthCredential);
 final user = authResult.user;
 if (user == null) throw Exception("Autenticación fallida");
 
 // 6. Manejar registro en Firestore
 await _handleUserRegistration(
 user: user,
 userType: userType,
 services: services,
 userProvider: userProvider,
 context: context,
 goRouter: goRouter,
 );
 
 } on SignInWithAppleAuthorizationException catch (e) {
 if (e.code != AuthorizationErrorCode.canceled) {
 _showError(context, "Error Apple: ${e.message}");
 }
 } on FirebaseAuthException catch (e) {
 _showError(context, "Error Firebase: ${e.message}");
 } catch (e) {
 _showError(context, "Error inesperado: $e");
 }
 }
 
 // Métodos auxiliares
 Future<void> _handleUserRegistration({
 required User user,
 required String userType,
 required UserProvider userProvider,
 required BuildContext context,
 required GoRouter goRouter,
 dynamic services,
 }) async {
 final userDoc = _firestore.collection('users').doc(user.uid);
 final docSnapshot = await userDoc.get();
 
 if (docSnapshot.exists) {
 await _handleExistingUser(
 userDoc: userDoc,
 docSnapshot: docSnapshot,
 userType: userType,
 context: context,
 goRouter: goRouter,
 services: services,
 );
 } else {
 await _registerNewUser(
 userDoc: userDoc,
 user: user,
 userType: userType,
 services: services,
 );
 }
 
 userProvider.saveAccountCreationDate();
 
 // Navegación basada en el tipo de usuario
 _navigateBasedOnUserType(userType, goRouter);
 }
 
 void _navigateBasedOnUserType(String userType, GoRouter goRouter) {
 if (userType == 'contractor') {
 goRouter.go('/age-terms'); // Pantalla para contratistas
 } else if (userType == 'artist') {
 goRouter.go('/age-terms'); // Pantalla para artistas
 } else {
 goRouter.go('/age-terms'); // Pantalla por defecto para otros tipos
 }
 }
 
 Future<void> _handleExistingUser({
 required DocumentReference userDoc,
 required DocumentSnapshot docSnapshot,
 required String userType,
 required BuildContext context,
 required GoRouter goRouter,
 dynamic services,
 }) async {
 final isRegistered = docSnapshot.get('isRegistered') ?? false;
 final existingUserType = docSnapshot.get('userType');
 
 if (isRegistered) {
 if (existingUserType != userType) {
 _showUserTypeMismatchDialog(context, goRouter);
 } else {
 _showAlreadyRegisteredDialog(context, goRouter);
 }
 } else {
 await userDoc.update({
 'isRegistered': true,
 'userType': userType,
 'name': docSnapshot.get('name') ?? 'No name',
 if (services != null) 'services': services,
 });
 }
 }
 
 Future<void> _registerNewUser({
 required DocumentReference userDoc,
 required User user,
 required String userType,
 dynamic services,
 }) async {
 await userDoc.set({
 'isRegistered': true,
 'userType': userType,
 'email': user.email,
 'name': user.displayName ?? 'No name',
 'isVerified': true,
 if (services != null) 'services': services,
 });
 }
 
 String _generateNonce([int length = 32]) {
 const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
 return List.generate(length, (_) => charset[Random.secure().nextInt(charset.length)]).join();
 }
 
 String _sha256ofString(String input) {
 return sha256.convert(utf8.encode(input)).toString();
 }
 
 void _showError(BuildContext context, String message) {
 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
 }
 
 void _showAlreadyRegisteredDialog(BuildContext context, GoRouter goRouter) {
 showDialog(
 context: context,
 builder: (context) => AlertDialog(
 title: const Text('Cuenta ya registrada'),
 content: const Text('Esta cuenta ya está registrada. ¿Quieres iniciar sesión?'),
 actions: [
 TextButton(
 onPressed: () => Navigator.pop(context),
 child: const Text('No'),
 ),
 TextButton(
 onPressed: () {
 goRouter.go('/login');
 Navigator.pop(context);
 },
 child: const Text('Sí'),
 ),
 ],
 ),
 );
 }
 
 void _showUserTypeMismatchDialog(BuildContext context, GoRouter goRouter) {
 showDialog(
 context: context,
 builder: (context) => AlertDialog(
 title: const Text('Tipo de usuario incorrecto'),
 content: const Text('Estás intentando acceder como un tipo de usuario diferente al registrado.'),
 actions: [
 TextButton(
 onPressed: () {
 goRouter.go('/login');
 Navigator.pop(context);
 },
 child: const Text('Aceptar'),
 ),
 ],
 ),
 );
 }
 }
 
 // Clases base necesarias
 abstract class AuthProvider {
 final String providerId;
 AuthProvider(this.providerId);
 }
 
 class AppleAuthCredential extends OAuthCredential {
 AppleAuthCredential._({
 String? accessToken,
 String? rawNonce,
 String? idToken,
 AppleFullPersonName? appleFullPersonName,
 }) : super(
 providerId: 'apple.com',
 signInMethod: 'apple.com',
 accessToken: accessToken,
 rawNonce: rawNonce,
 idToken: idToken,
 );
 
 factory AppleAuthCredential._credential(String accessToken) {
 return AppleAuthCredential._(accessToken: accessToken);
 }
 
 factory AppleAuthCredential._credentialWithIDToken(
 String idToken,
 String rawNonce,
 AppleFullPersonName appleFullPersonName,
 ) {
 return AppleAuthCredential._(
 idToken: idToken,
 rawNonce: rawNonce,
 appleFullPersonName: appleFullPersonName,
 );
 }
 }
 
 class AppleFullPersonName {
 final String? givenName;
 final String? familyName;
 final String? middleName;
 final String? nickname;
 final String? namePrefix;
 final String? nameSuffix;
 
 AppleFullPersonName({
 this.givenName,
 this.familyName,
 this.middleName,
 this.nickname,
 this.namePrefix,
 this.nameSuffix,
 });
 }