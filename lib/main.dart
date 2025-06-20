import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:live_music/data/provider_logics/auth/register_wigh_google_provider.dart'
    show RegisterWithGoogleProvider;
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/profile/profile_provider.dart';
import 'package:live_music/data/repositories/providers_repositories/user_repository.dart';
import 'package:live_music/data/repositories/sources_repositories/imageRepository.dart';
import 'package:live_music/data/repositories/sources_repositories/messageRepository.dart';
import 'package:live_music/data/repositories/sources_repositories/reviewResitory.dart';
import 'package:live_music/data/widgets/firebase_utils.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/screens/beginning/after_access/age_and_legal_data.dart';
import 'package:live_music/presentation/screens/beginning/after_access/contractor_data/name_screen.dart';
import 'package:live_music/presentation/screens/beginning/before_access/selection_screen.dart';
import 'package:live_music/presentation/screens/beginning/after_access/artist_data/country_and_state.dart';
import 'package:live_music/presentation/screens/beginning/after_access/artist_data/group_name.dart';
import 'package:live_music/presentation/screens/beginning/after_access/artist_data/musical_genres.dart';
import 'package:live_music/presentation/screens/beginning/after_access/artist_data/nickname.dart';
import 'package:live_music/presentation/screens/beginning/after_access/artist_data/price.dart';
import 'package:live_music/presentation/screens/beginning/after_access/artist_data/profileImage.dart';
import 'package:live_music/presentation/screens/beginning/after_access/artist_data/specialization.dart';
import 'package:live_music/presentation/screens/beginning/after_access/artist_data/user_can_work_country.dart';
import 'package:live_music/presentation/screens/beginning/after_access/forgot_password.dart';
import 'package:live_music/presentation/screens/beginning/after_access/verified_email.dart';
import 'package:live_music/presentation/screens/beginning/after_access/welcome.dart';
import 'package:live_music/presentation/screens/beginning/before_access/access_options/auth_mail/sign_in_mail/sign_in_mail.dart';
import 'package:live_music/presentation/screens/beginning/before_access/access_options/auth_mail/sign_up_mail/sign_up_artist.dart';
import 'package:live_music/presentation/screens/beginning/before_access/access_options/auth_mail/sign_up_mail/sign_up_contractor.dart';
import 'package:live_music/presentation/screens/beginning/before_access/access_options/sign_in/sign_in.dart';
import 'package:live_music/presentation/screens/beginning/before_access/access_options/sign_up/Sign_up_artist.dart';
import 'package:live_music/presentation/screens/beginning/before_access/access_options/sign_up/sign_up_contractor.dart';
import 'package:live_music/presentation/screens/beginning/before_access/waiting_confirmation.dart';
import 'package:live_music/presentation/screens/home/home.dart';
import 'package:live_music/presentation/screens/liked_artist/liked_artist.dart';
import 'package:live_music/presentation/screens/liked_artist/liked_users_list.dart';
import 'package:live_music/presentation/screens/liked_artist/recently_viewed.dart';
import 'package:live_music/presentation/screens/messages/chat.dart';
import 'package:live_music/presentation/screens/messages/image_preview.dart';
import 'package:live_music/presentation/screens/messages/messages.dart';
import 'package:live_music/presentation/screens/profile/artist/profile_artist.dart';
import 'package:live_music/presentation/screens/profile/contractor/contractor_profile.dart';
import 'package:live_music/presentation/screens/profile/settings/components/my_account.dart';
import 'package:live_music/presentation/screens/profile/contractor/review_contractor.dart';
import 'package:live_music/presentation/screens/profile/settings/components/blocked_accounts.dart';
import 'package:live_music/presentation/screens/profile/settings/components/change_password.dart';
import 'package:live_music/presentation/screens/profile/settings/components/delete_account/confirm_identity.dart';
import 'package:live_music/presentation/screens/profile/settings/components/delete_account/delete_account.dart';
import 'package:live_music/presentation/screens/profile/settings/components/delete_account/final_confirmation.dart';
import 'package:live_music/presentation/screens/profile/settings/components/help.dart';
import 'package:live_music/presentation/screens/profile/settings/components/suggestions.dart';
import 'package:live_music/presentation/screens/profile/settings/settings_screen.dart';
import 'package:live_music/presentation/screens/search/search.dart';
import 'package:live_music/presentation/screens/search_fun/profile_artist_ws/profile_artist_ws.dart';
import 'package:live_music/presentation/screens/search_fun/search_fun.dart';
import 'package:live_music/presentation/widgets/loading.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/provider_logics/beginning/beginning_provider.dart';
import 'data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import 'data/provider_logics/nav_buttom_bar_components/home/home_provider.dart';
import 'data/provider_logics/nav_buttom_bar_components/messages/messages_provider.dart';
import 'data/provider_logics/nav_buttom_bar_components/search/search_provider.dart'
    show SearchProvider;
import 'data/provider_logics/user/user_provider.dart';
import 'data/provider_logics/user/reset_password.dart';
import 'data/provider_logics/user/review_provider.dart';
import 'data/repositories/render_http_client/images/upload_profile_image.dart';
import 'data/repositories/render_http_client/images/upload_work_image.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/widgets/handle_deep_link.dart';
import 'data/provider_logics/nav_buttom_bar_components/home/search_fun_provider.dart';
import 'firebase_options.dart';
import 'package:live_music/data/sources/local/internal_data_base.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar orientación vertical antes de cualquier inicialización
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa la base de datos local
  final appDatabase = await AppDatabase.getInstance();
  final recentlyViewedDao = appDatabase.recentlyViewedDao;
  // Obtén el DAO de mensajes
  final messageDao = appDatabase.messageDao;

  // Inicializa SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Inicializa ReviewRepository
  final reviewRepository = ReviewRepository(
    reviewDao: appDatabase.reviewDao,
    firestore: FirebaseFirestore.instance,
  );

  // Inicializa DatabaseReference para Firebase Realtime Database
  final firebaseDb = FirebaseDatabase.instance.ref();

  // Inicializa MessageRepository
  final messageRepository = MessageRepository(
    messageDao: messageDao,
    firebaseDb: firebaseDb,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) => UserProvider(
                auth: FirebaseAuth.instance,
                firestore: FirebaseFirestore.instance,
                cachedDataDao: appDatabase.cachedDataDao,
              ),
        ),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => SearchFunProvider()),
        ChangeNotifierProvider(create: (_) => RegisterWithGoogleProvider()),
        Provider(create: (_) => messageRepository),
        ChangeNotifierProvider(
          create: (_) => MessagesProvider(messageRepository: messageRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewProvider(reviewRepository: reviewRepository),
        ),
        ChangeNotifierProvider(
          create:
              (_) => FavoritesProvider(
                dao: appDatabase.likedUsersListDao,
                authInstance: FirebaseAuth.instance,
                firestoreInstance: FirebaseFirestore.instance,
                recentlyViewedDao: recentlyViewedDao,
              ),
        ),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        Provider(create: (_) => UploadProfileImagesToServer()),
        Provider(create: (_) => UploadWorkMediaToServer()),
        ChangeNotifierProvider(create: (_) => BeginningProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        Provider(create: (_) => UserRepository(sharedPreferences)),
      ],
      child: Builder(
        builder: (context) {
          return MultiProvider(
            providers: [
              Provider(
                create:
                    (_) => ImageRepository(
                      imageDao: appDatabase.imageDao,
                      context: context,
                    ),
              ),
            ],
            child: const MyApp(),
          );
        },
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Firebase services
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  late final UserProvider _userProvider;
  late final HomeProvider _homeAlgorithmProvider;
  late final SearchFunProvider _searchFunProvider;
  late final MessagesProvider _messagesProvider;
  late final ReviewProvider _reviewProvider;
  late final FavoritesProvider _favoritesProvider;
  late final UploadProfileImagesToServer _uploadProfileImagesToServer;
  late final UploadWorkMediaToServer _uploadWorkImagesToServer;
  late final BeginningProvider _beginningProvider;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final ProfileProvider _profileProvider;
  bool _isAppActive = false;

  // Router
  late GoRouter _goRouter;
  bool _isInitialized = false;

  String normalizePath(String path) {
    final uri = Uri.parse(path);
    String normalized = uri.path;
    // Elimina el slash final, excepto para la ruta raíz ("/")
    if (normalized.endsWith('/') && normalized.length > 1) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  Future<void> updateUserUsingAppStatus(bool isUsingApp) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection(AppStrings.usersCollection)
        .doc(currentUser.uid);

    try {
      await userDoc.set(
        {'userUsingApp': isUsingApp},
        SetOptions(merge: true), // Actualiza o crea el campo
      );
    } catch (e) {
      debugPrint(' $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _initializeApp();
    _handleInitialDeepLink();
    _beginningProvider = Provider.of<BeginningProvider>(context, listen: false);
    _userProvider.getCountryAndState();
    WidgetsBinding.instance.addObserver(this);
    updateUserUsingAppStatus(true);

    // Verifica y guarda el token FCM
    _checkAndSaveFcmToken();
  }

  Future<void> _checkAndSaveFcmToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid);

    try {
      final snapshot = await userDoc.get();
      if (!snapshot.exists || !snapshot.data()!.containsKey("fcmToken")) {
        // Si no existe el token, obtén y guárdalo
        FirebaseUtils.getDeviceToken(
          onTokenReceived: (token) async {
            await FirebaseUtils.saveTokenToFirestore(
              uid: currentUser.uid,
              token: token,
              onSuccess: () {},
              onError: (e) {},
            );
          },
          onError: (e) {},
        );
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    // Elimina el observador del ciclo de vida de la aplicación
    WidgetsBinding.instance.removeObserver(this);
    updateUserUsingAppStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Actualiza el estado según el ciclo de vida de la aplicación
    if (state == AppLifecycleState.resumed) {
      updateUserUsingAppStatus(true);
    } else {
      updateUserUsingAppStatus(false);
    }
  }

  /// Función para verificar si la aplicación está activa
  bool isAppActive() {
    return _isAppActive;
  }

  Future<void> _handleInitialDeepLink() async {
    if (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _handleInitialDeepLink();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        final isHandled = await DeepLinkHandler.handleDeepLink(
          context,
          _goRouter,
        );

        if (!isHandled && _auth.currentUser != null) {
          final initialRoute = await _determineInitialRoute();
          _goRouter.go(initialRoute);
        }
      } catch (e) {
        if (mounted) {
          _goRouter.go(AppStrings.selectionScreenRoute);
        }
      }
    });
  }

  Future<void> _initializeApp() async {
    // Inicialización de todos los providers

    _userProvider = Provider.of<UserProvider>(context, listen: false);
    _homeAlgorithmProvider = Provider.of<HomeProvider>(context, listen: false);
    _searchFunProvider = Provider.of<SearchFunProvider>(context, listen: false);
    _profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    _messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
    _reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    _favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    _uploadProfileImagesToServer = UploadProfileImagesToServer();
    _uploadWorkImagesToServer = UploadWorkMediaToServer();
    // Obtiene el tipo de usuario
    await _userProvider.fetchUserType();

    // Inicializa el currentUserId
    await _userProvider.fetchCurrentUserId();

    // Determinar ruta inicial
    final initialRoute = await _determineInitialRoute();

    // Configurar el router
    _goRouter = GoRouter(
      initialLocation: initialRoute,
      routes: _buildAppRoutes(),
      redirect: (BuildContext context, GoRouterState state) {
        // Si la ruta entrante no está en la lista de rutas válidas, redirige a initialRoute
        final validPaths = [
          AppStrings.nicknameScreenRoute,
          AppStrings.loadingScreenRoute,
          AppStrings.homeScreenRoute,
          AppStrings.selectionScreenRoute,
          AppStrings.loginOptionsScreenRoute,
          AppStrings.reviewsScreenRoute,
          AppStrings.usernameScreen,
          AppStrings.registerOptionsArtistRoute,
          AppStrings.settingsScreenRoute,
          AppStrings.myAccountScreenRoute,
          AppStrings.registerOptionsContractorRoute,
          AppStrings.registerArtistMailScreenRoute,
          AppStrings.registerContractorMailScreenRoute,
          AppStrings.loginMailScreenRoute,
          AppStrings.searchRoute,
          AppStrings.ageTermsScreenRoute,
          AppStrings.profileArtistScreenRoute,
          AppStrings.profileArtistScreenWSRoute,
          AppStrings.messagesScreenRoute,
          AppStrings.forgotPasswordScreenRoute,
          AppStrings.chatScreenRoute,
          AppStrings.contractorProfileScreenRoute,
          AppStrings.settingsRoute,
          AppStrings.blockedAccountsRoute,
          AppStrings.helpRoute,
          AppStrings.suggestionsRoute,
          AppStrings.likedArtistsGridRoute,
          AppStrings.likedUsersListScreenRoute,
          AppStrings.deleteAccountRoute,
          AppStrings.changePasswordRoute,
          AppStrings.confirmIdentityRoute,
          AppStrings.finalConfirmationRoute,
          AppStrings.searchFunScreenRoute,
          AppStrings.resetPasswordRoute,
          AppStrings.verifyEmailRoute,
          AppStrings.waitingConfirmScreenRoute,
          AppStrings.groupNameScreenRoute,
          AppStrings.profileImageScreenRoute,
          AppStrings.countryStateScreenRoute,
          AppStrings.musicGenresScreenRoute,
          AppStrings.userCanWorkCountryStateScreenRoute,
          AppStrings.eventSpecializationScreenRoute,
          AppStrings.priceScreenRoute,
          AppStrings.welcomeScreenRoute,
          AppStrings.recentlyViewedScreenRoute,
          AppStrings.imagePreviewScreenRoute,
        ];
        // Normaliza la ruta entrante
        final normalizedIncomingPath = normalizePath(state.subloc);

        // Verifica si la ruta es válida
        final isPathValid = validPaths.any(
          (validPath) => normalizePath(validPath) == normalizedIncomingPath,
        );

        if (!isPathValid) {
          return initialRoute; // Redirige a la ruta inicial si no es válida
        }

        return null; // No redirige si la ruta es válida
      },
      errorBuilder:
          (context, state) => Scaffold(
            body: Center(child: Text('${AppStrings.error404}: ${state.error}')),
          ),
    );

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<String> _determineInitialRoute() async {
    final currentUser = _auth.currentUser;

    // Si no hay usuario logueado
    if (currentUser == null) {
      return AppStrings.selectionScreenRoute;
    }

    final currentUserId = currentUser.uid;

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();

      final data = userDoc.data() ?? {};

      // Si el documento no existe o no está registrado
      if (!userDoc.exists || (data['isRegistered'] ?? false) != true) {
        return AppStrings.selectionScreenRoute;
      }

      final isVerified = data['isVerified'] ?? false;
      final name = data['name'] ?? '';
      final nickname = data['nickname'] ?? '';
      final profileImageUrl = data['profileImageUrl'] ?? '';
      final country = data['country'] ?? '';
      final state = data['state'] ?? '';
      final genres = data['genres'] as List<dynamic>? ?? [];
      final specialty = data['specialty'] ?? '';
      final price = data['price'];
      final countries = data['countries'] as List<dynamic>? ?? [];
      final states = data['states'] as List<dynamic>? ?? [];
      final userType = data['userType'] ?? '';
      final isArtist = userType == 'artist';

      final age = data['age'];
      final acceptedTerms = data['acceptedTerms'];
      final acceptedPrivacy = data['acceptedPrivacy'];

      // Si el correo no está verificado, se redirige a esperar confirmación
      if (!isVerified) {
        return AppStrings.waitingConfirmScreenRoute;
      }

      _beginningProvider.setRouteToGo(AppStrings.welcomeScreenRoute);

      if (!isArtist) {
        // ✅ Check de edad y términos justo antes de name
        if (age == null || acceptedTerms != true || acceptedPrivacy != true) {
          return AppStrings.ageTermsScreenRoute;
        }

        if (name.isEmpty) {
          return AppStrings.usernameScreen;
        }
        if (nickname.isEmpty) {
          return AppStrings.nicknameScreenRoute;
        }
      }

      if (isArtist) {
        _beginningProvider.setRouteToGo(AppStrings.profileImageScreenRoute);

        // ✅ Check de edad y términos justo antes de group name
        if (age == null || acceptedTerms != true || acceptedPrivacy != true) {
          return AppStrings.ageTermsScreenRoute;
        }

        if (isVerified && name.isEmpty) {
          return AppStrings.verifyEmailRoute;
        }
        if (name.isEmpty) {
          return AppStrings.groupNameScreenRoute;
        }
        if (nickname.isEmpty) {
          return AppStrings.nicknameScreenRoute;
        }
        if (profileImageUrl.isEmpty) {
          return AppStrings.profileImageScreenRoute;
        }
        if (genres.isEmpty) {
          return AppStrings.musicGenresScreenRoute;
        }
        if (specialty.isEmpty) {
          return AppStrings.eventSpecializationScreenRoute;
        }
        if (price == null) {
          return AppStrings.priceScreenRoute;
        }
        if (countries.isEmpty || states.isEmpty) {
          return AppStrings.userCanWorkCountryStateScreenRoute;
        }
        if (country.isEmpty || state.isEmpty) {
          return AppStrings.countryStateScreenRoute;
        }
      }

      return AppStrings.homeScreenRoute;
    } catch (e) {
      return AppStrings.selectionScreenRoute;
    }
  }

  List<RouteBase> _buildAppRoutes() {
    return [
      GoRoute(
        path: AppStrings.nicknameScreenRoute,
        builder: (context, state) => NicknameScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.loadingScreenRoute,
        builder: (context, state) => LoadingScreen(),
      ),
      GoRoute(
        path: AppStrings.homeScreenRoute,
        builder: (context, state) {
          return Home(
            auth: FirebaseAuth.instance,
            userProvider: Provider.of<UserProvider>(context, listen: false),
            homeProvider: Provider.of<HomeProvider>(context, listen: false),
            searchProvider: Provider.of<SearchProvider>(context, listen: false),
            searchFunProvider: Provider.of<SearchFunProvider>(
              context,
              listen: false,
            ),
            reviewProvider: Provider.of<ReviewProvider>(context, listen: false),
            favoritesProvider: Provider.of<FavoritesProvider>(
              context,
              listen: false,
            ),
            goRouter: _goRouter,
            beginningProvider: _beginningProvider,
          );
        },
      ),
      GoRoute(
        path: AppStrings.selectionScreenRoute,
        builder:
            (context, state) => SelectionScreen(
              onArtistClick: () {
                context.go(AppStrings.registerOptionsArtistRoute);
              },
              onContractorClick: () {
                context.go(AppStrings.registerOptionsContractorRoute);
              },
              onLoginClick: () {
                context.go(AppStrings.loginOptionsScreenRoute);
              },
            ),
      ),
      GoRoute(
        path: AppStrings.loginOptionsScreenRoute,
        builder: (context, state) => LoginOptionsScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.usernameScreen,
        builder: (context, state) => UsernameScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.reviewsScreenRoute,
        builder:
            (context, state) => ReviewsContractorScreen(
              goRouter: _goRouter,
              userProvider: _userProvider,
              reviewProvider: _reviewProvider,
              messagesProvider: _messagesProvider,
            ),
      ),
      GoRoute(
        path: AppStrings.registerOptionsArtistRoute,
        builder:
            (context, state) =>
                RegisterOptionsArtistScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.myAccountScreenRoute,
        builder:
            (context, state) => MyAccountScreen(
              goRouter: _goRouter,
              userProvider: _userProvider,
            ),
      ),
      GoRoute(
        path: AppStrings.registerOptionsContractorRoute,
        builder:
            (context, state) =>
                RegisterOptionsContractorScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.registerArtistMailScreenRoute,
        builder: (context, state) => RegisterArtistMailScreen(),
      ),
      GoRoute(
        path: AppStrings.registerContractorMailScreenRoute,
        builder: (context, state) => RegisterContractorMailScreen(),
      ),
      GoRoute(
        path: AppStrings.loginMailScreenRoute,
        builder:
            (context, state) =>
                LoginMailScreen(auth: _auth, goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.ageTermsScreenRoute,
        builder: (context, state) => AgeTermsScreen(goRouter: _goRouter),
      ),

      GoRoute(
        path: AppStrings.searchScreenRoute,
        redirect: (context, state) {
          final userType = _userProvider.userType;
          if (userType != "artist" && userType != "contractor") {
            return AppStrings.selectionScreenRoute;
          }
          return null;
        },
        builder:
            (context, state) =>
                SearchScreen(goRouter: _goRouter, userProvider: _userProvider),
      ),
      GoRoute(
        path: AppStrings.profileArtistScreenRoute,
        builder:
            (context, state) => ProfileArtistScreen(
              key: const Key("profile_artist_screen"),
              uploadProfileImagesToServer: _uploadProfileImagesToServer,
              uploadWorkImagesToServer: _uploadWorkImagesToServer,
              goRouter: _goRouter,
              profileProvider: _profileProvider,
              userProvider: _userProvider,
              reviewProvider: _reviewProvider,
              messagesProvider: _messagesProvider,
            ),
      ),
      GoRoute(
        path: AppStrings.profileArtistScreenWSRoute,
        builder:
            (context, state) => ArtistProfileScreenWS(
              goRouter: _goRouter,
              userProvider: _userProvider,
              favoritesProvider: _favoritesProvider,
            ),
      ),
      GoRoute(
        path: AppStrings.messagesScreenRoute,
        builder:
            (context, state) => ConversationsScreen(
              goRouter: _goRouter,
              userProvider: _userProvider,
              messagesProvider: _messagesProvider,
              reviewProvider: _reviewProvider,
            ),
      ),
      GoRoute(
        path: AppStrings.forgotPasswordScreenRoute,
        builder: (context, state) => ForgotPasswordScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.chatScreenRoute,
        builder:
            (context, state) => ChatScreen(
              currentUserId: _currentUserId,
              userProvider: _userProvider,
              messagesProvider: _messagesProvider,
              goRouter: _goRouter,
            ),
      ),
      GoRoute(
        path: AppStrings.contractorProfileScreenRoute,
        builder:
            (context, state) => ContractorProfileScreen(
              goRouter: _goRouter,
              uploadProfileImagesToServer: _uploadProfileImagesToServer,
              userProvider: _userProvider,
            ),
      ),
      GoRoute(
        path: AppStrings.settingsScreenRoute,
        builder:
            (context, state) => SettingsScreen(
              goRouter: _goRouter,
              userProvider: _userProvider,
            ),
      ),
      GoRoute(
        path: AppStrings.blockedAccountsRoute,
        builder:
            (context, state) => BlockedAccounts(
              goRouter: _goRouter,
              userProvider: _userProvider,
            ),
      ),
      GoRoute(
        path: AppStrings.helpRoute,
        builder:
            (context, state) =>
                Help(goRouter: _goRouter, userProvider: _userProvider),
      ),
      GoRoute(
        path: AppStrings.suggestionsRoute,
        builder:
            (context, state) =>
                Suggestions(goRouter: _goRouter, userProvider: _userProvider),
      ),
      GoRoute(
        path: AppStrings.likedArtistsGridRoute,
        builder: (context, state) => LikedArtistsScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.likedUsersListScreenRoute,
        builder: (context, state) => LikedUsersListScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.deleteAccountRoute,
        builder:
            (context, state) =>
                DeleteAccount(goRouter: _goRouter, userProvider: _userProvider),
      ),
      GoRoute(
        path: AppStrings.changePasswordRoute,
        builder: (context, state) => ChangePassword(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.confirmIdentityRoute,
        builder:
            (context, state) => ConfirmIdentity(
              goRouter: _goRouter,
              deletionRequest: (newValue) {},
            ),
      ),
      GoRoute(
        path: AppStrings.finalConfirmationRoute,
        builder: (context, state) => FinalConfirmation(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.searchFunScreenRoute,
        builder: (context, state) => SearchFunScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.resetPasswordRoute,
        builder: (context, state) {
          final uri = state.location;
          final link = Uri.parse(uri).queryParameters['link'];
          return ResetPasswordScreen(
            goRouter: _goRouter,
            routerState: state,
            deepLink: link,
          );
        },
      ),
      GoRoute(
        path: AppStrings.verifyEmailRoute,
        builder: (context, state) => VerificationSuccessScreen(),
      ),
      GoRoute(
        path: AppStrings.waitingConfirmScreenRoute,
        builder: (context, state) => WaitingConfirmScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.groupNameScreenRoute,
        builder: (context, state) => GroupNameScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.profileImageScreenRoute,
        builder:
            (context, state) =>
                ProfileImageScreen(userId: _currentUserId, goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.countryStateScreenRoute,
        builder: (context, state) => CountryStateScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.musicGenresScreenRoute,
        builder: (context, state) => MusicGenresScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.userCanWorkCountryStateScreenRoute,
        builder:
            (context, state) =>
                UserCanWorkCountryStateScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.eventSpecializationScreenRoute,
        builder:
            (context, state) => EventSpecializationScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.priceScreenRoute,
        builder: (context, state) => PriceScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.welcomeScreenRoute,
        builder: (context, state) => WelcomeScreen(goRouter: _goRouter),
      ),
      GoRoute(
        path: AppStrings.recentlyViewedScreenRoute,
        builder:
            (context, state) => RecentlyViewedScreen(
              userProvider: _userProvider,
              reviewProvider: _reviewProvider,
              favoritesProvider: _favoritesProvider,
              goRouter: _goRouter,
            ),
      ),
      GoRoute(
        path: AppStrings.imagePreviewScreenRoute,
        builder: (context, state) => ImagePreviewScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'ES')],
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp.router(
      routerConfig: _goRouter,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      builder: (context, child) {
        // Escuchar deep links continuamente
        DeepLinkHandler.deepLinkStream.listen((link) {
          if (mounted && link.isNotEmpty) {
            DeepLinkHandler.processDeepLink(context, _goRouter, link);
          }
        });

        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: _userProvider),
            ChangeNotifierProvider.value(value: _homeAlgorithmProvider),
            ChangeNotifierProvider.value(value: _searchFunProvider),
            // ... otros providers
          ],
          child: Builder(
            builder: (context) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.0)),
                child: child!,
              );
            },
          ),
        );
      },
    );
  }
}
