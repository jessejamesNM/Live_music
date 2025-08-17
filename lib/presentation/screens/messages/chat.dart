/// -----------------------------------------------------------------------------
/// Created: 2025-04-23
/// Author: KingdomOfJames
/// Description:
/// ChatScreen es una pantalla dedicada a conversaciones entre dos usuarios.
/// Permite el envío y visualización en tiempo real de mensajes de texto,
/// imágenes y ubicación, integrando Firebase Realtime Database y funcionalidades
/// del sistema como selección de medios y geolocalización.
/// También incluye manejo de bloqueos, notificaciones push y estados de conexión.
///
/// Características:
/// - Carga y muestra el historial de mensajes desde Firebase.
/// - Escucha y sincroniza mensajes nuevos en tiempo real.
/// - Permite enviar mensajes de texto, imágenes y ubicaciones.
/// - Gestiona el estado online del otro usuario.
/// - Previene el envío de mensajes si hay un bloqueo entre usuarios.
/// - Muestra imagen de perfil y nombre artístico.
/// - Manejo dinámico del scroll y visibilidad de componentes según el estado.
///
/// Recomendaciones:
/// - Modularizar secciones como el input de mensaje, encabezado y lista de mensajes
///   en widgets separados para mayor legibilidad y reutilización.
/// - Considerar migrar lógica pesada (ej. listeners de Firebase) hacia el provider.
/// - Implementar lazy loading y paginación para optimizar carga de mensajes.
/// - Desacoplar el manejo de estado (`StatefulWidget`) hacia un `StateNotifier`
///   o similar, si se escala en complejidad.
/// -----------------------------------------------------------------------------

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:live_music/data/repositories/render_http_client/notifications/notification.dart';
import 'package:live_music/data/widgets/firebase_utils.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/messages/messages_provider.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/animated_visibility.dart';
import '../../widgets/chat/message_item.dart';
import 'package:live_music/presentation/resources/colors.dart';

// ChatScreen Widget (Stateful)
class ChatScreen extends StatefulWidget {
  final UserProvider userProvider;
  final MessagesProvider messagesProvider;
  final GoRouter goRouter;
  const ChatScreen({
    Key? key,
    required this.userProvider,
    required this.messagesProvider,
    required this.goRouter,
  }) : super(key: key);

  @override
  _ChatScreenState createState() =>
      _ChatScreenState(userProvider: userProvider);
}

// ChatScreen State
class _ChatScreenState extends State<ChatScreen> {
  late String currentUserId;
  late String otherUserId;
  final UserProvider userProvider;
  File? _selectedMediaFile;
  String? _profileImageUrl;
  bool _isOnline = false;
  bool _iAmBlocked = false;
  bool _iBlocked = false;
  bool _showBlockedDialog = false;
  bool _showUnblockDialog = false;
  String _artistName = AppStrings.loadingText;
  double? _currentLatitude;
  double? _currentLongitude;
  TextEditingController _messageController = TextEditingController();
  bool _isBottomSheetVisible = false;
  late String _otherUserId;
  StreamSubscription? _messagesSubscription;
  final Logger logger = Logger();
  String token = '';

  _ChatScreenState({required this.userProvider});

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _otherUserId = userProvider.otherUserId;
    _initializeChat();
    _checkAndSaveFcmToken();

    widget.messagesProvider.getFcmToken(_otherUserId).then((_) {
      setState(() {
        token = widget.messagesProvider.notificationUserToken.value;
      });
    });
  }

  void _initializeChat() {
    widget.messagesProvider.loadProfileImage(_otherUserId, (url) {
      if (mounted) setState(() => _profileImageUrl = url);
    });

    widget.messagesProvider.getFcmToken(_otherUserId);
    widget.messagesProvider.checkOnlineStatusAndBlock(_otherUserId, (
      isOnline,
      iAmBlocked,
    ) {
      if (mounted)
        setState(() {
          _isOnline = isOnline;
          _iAmBlocked = iAmBlocked;
        });
    });
    _syncMessages();
    _loadMessages();
    _setupFirebaseListener();
    widget.messagesProvider.updateArtistName(_otherUserId, (name) {
      if (mounted) setState(() => _artistName = name);
    });
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newOtherUserId = userProvider.otherUserId;
    if (newOtherUserId != _otherUserId) {
      _cleanupListeners();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _otherUserId = newOtherUserId;
          _initializeChat();
        });
      });
    }
  }

  void _cleanupListeners() {
    _messagesSubscription?.cancel();
    widget.messagesProvider.clearAllFirebaseListeners();
  }

  void _syncMessages() {
    if (_otherUserId.isNotEmpty && currentUserId.isNotEmpty) {
      widget.messagesProvider.syncMessagesWithFirebase(
        currentUserId,
        _otherUserId,
      );
    }
  }

  void _loadMessages() {
    if (_otherUserId.isNotEmpty && currentUserId.isNotEmpty) {
      widget.messagesProvider.loadMessagesFromRoom(currentUserId, _otherUserId);
      Future.delayed(Duration(seconds: 1), () {
        widget.messagesProvider.loadMessagesFromRoom(
          currentUserId,
          _otherUserId,
        );
      });
    }
  }

  void _setupFirebaseListener() async {
    if (_otherUserId.isNotEmpty && currentUserId.isNotEmpty) {
      _messagesSubscription?.cancel();
      widget.messagesProvider.setupFirebaseListener(
        currentUserId,
        _otherUserId,
      );
      if (mounted) setState(() {});
    }
  }

  void _sendMessage() {
    if (_iAmBlocked) {
      setState(() => _showBlockedDialog = true);
    } else if (_iBlocked) {
      setState(() => _showUnblockDialog = true);
    } else {
      widget.messagesProvider.sendMessage(
        context,
        _messageController.text,
        _selectedMediaFile,
        currentUserId,
        _otherUserId,
      );
      _messageController.clear();
      setState(() => _selectedMediaFile = null);
    }
  }

  Future<void> _handleLocationSharing() async {
    if (_iAmBlocked) {
      setState(() => _showBlockedDialog = true);
      return;
    }

    if (_iBlocked) {
      setState(() => _showUnblockDialog = true);
      return;
    }

    // Always request location permission when button is clicked
    final status = await Permission.location.request();

    if (!status.isGranted) {
      // If denied, show explanation and request again
      if (await Permission.location.shouldShowRequestRationale) {
        // Show explanation why permission is needed
        await showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: Text('Permisos de ubicación requeridos'),
                content: Text(
                  'Necesitamos acceso a tu ubicación para compartirla en el chat. '
                  'Por favor, concede los permisos cuando se te solicite.',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Entendido'),
                  ),
                ],
              ),
        );

        // Request permission again after explanation
        final newStatus = await Permission.location.request();
        if (!newStatus.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se puede compartir ubicación sin permisos'),
            ),
          );
          return;
        }
      } else {
        // Permission permanently denied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Los permisos de ubicación fueron denegados permanentemente. '
              'Puedes habilitarlos en la configuración de la aplicación.',
            ),
            action: SnackBarAction(
              label: 'Abrir configuración',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }
    }

    // Permissions granted, proceed with location
    widget.messagesProvider.getCurrentLocationForChat(widget.messagesProvider, (
      location,
    ) {
      if (location != null && mounted) {
        setState(() {
          _currentLatitude = location['latitude'];
          _currentLongitude = location['longitude'];
        });
        widget.messagesProvider.showLocationBottomSheetModal(
          context,
          _currentLatitude!,
          _currentLongitude!,
          ColorPalette.getPalette(context),
          () {
            widget.messagesProvider.sendLocation(
              context,
              _currentLatitude!,
              _currentLongitude!,
              currentUserId,
              _otherUserId,
            );
            Navigator.pop(context);
            sendNotification(
              "Te ah compartido su ubicación",
              _artistName,
              token,
            );
          },
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.locationError)));
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesSubscription?.cancel();
    widget.messagesProvider.clearAllFirebaseListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primarySecondColor],
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedVisibility(
                visible: _isBottomSheetVisible,
                duration: Duration(milliseconds: 500),
                child: Container(
                  width: double.infinity,
                  height: 95,
                  decoration: BoxDecoration(
                    color: colorScheme[AppStrings.primaryColor],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      left: 16,
                      right: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [],
                    ),
                  ),
                ),
              ),
            ),
            Stack(
              children: [
                Container(color: colorScheme[AppStrings.primaryColor]),
                Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: colorScheme[AppStrings.secondaryColor],
                              size: 28,
                            ),
                            onPressed: () {
                              widget.messagesProvider
                                  .clearAllFirebaseListeners();
                              widget.messagesProvider.setupConversationListener(
                                currentUserId,
                              );
                              context.pop();
                            },
                          ),
                          CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 25,
                            child: ClipOval(
                              child:
                                  _iAmBlocked
                                      ? SvgPicture.asset(
                                        AppStrings.defaultUserImagePath,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                        fit: BoxFit.cover,
                                      )
                                      : _profileImageUrl != null
                                      ? Image.network(
                                        _profileImageUrl!,
                                        fit: BoxFit.cover,
                                        width: 50,
                                        height: 50,
                                      )
                                      : SvgPicture.asset(
                                        AppStrings.defaultUserImagePath,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _artistName,
                                style: TextStyle(
                                  color: colorScheme[AppStrings.secondaryColor],
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                _isOnline
                                    ? AppStrings.onlineStatus
                                    : AppStrings.offlineStatus,
                                style: TextStyle(
                                  color: _isOnline ? Colors.green : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Expanded(
                        child: ValueListenableBuilder<List<dynamic>>(
                          valueListenable: widget.messagesProvider.messages,
                          builder: (context, List<dynamic> rawList, child) {
                            return ListView.builder(
                              reverse: true,
                              itemCount: rawList.length,
                              itemBuilder: (context, index) {
                                return MessageItem(
                                  message: rawList[index],
                                  currentUserId: currentUserId,
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Container(
                        color: colorScheme[AppStrings.primarySecondColor],
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.image,
                                color: colorScheme[AppStrings.essentialColor],
                                size: 30,
                              ),
                              onPressed: () async {
                                if (_iAmBlocked) {
                                  setState(() => _showBlockedDialog = true);
                                } else if (_iBlocked) {
                                  setState(() => _showUnblockDialog = true);
                                } else {
                                  final pickedFile =
                                      await widget.messagesProvider.pickMedia();
                                  if (pickedFile != null) {
                                    widget
                                        .messagesProvider
                                        .selectedImageFile
                                        .value = pickedFile;
                                    if (context.mounted) {
                                      widget.goRouter.push(
                                        AppStrings.imagePreviewScreenRoute,
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                            SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                Icons.location_on,
                                color: colorScheme[AppStrings.essentialColor],
                                size: 30,
                              ),
                              onPressed: _handleLocationSharing,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[700],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        style: TextStyle(
                                          color:
                                              colorScheme[AppStrings
                                                  .secondaryColor],
                                        ),
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintStyle: TextStyle(
                                            color:
                                                colorScheme[AppStrings
                                                    .grayColor],
                                          ),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.send,
                                        color:
                                            _messageController.text
                                                    .trim()
                                                    .isEmpty
                                                ? colorScheme[AppStrings
                                                    .essentialColor]
                                                : colorScheme[AppStrings
                                                    .essentialColor],
                                        size: 30,
                                      ),
                                      onPressed:
                                          _messageController.text.trim().isEmpty
                                              ? null
                                              : () {
                                                _sendMessage();
                                                if (!_iAmBlocked &&
                                                    !_iBlocked) {
                                                  sendNotification(
                                                    "te ha enviado un mensaje",
                                                    _artistName,
                                                    token,
                                                  );
                                                }
                                              },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showBlockedDialog)
              AlertDialog(
                title: Text(AppStrings.blockedAlertTitle),
                content: Text(AppStrings.blockedAlertMessage),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _showBlockedDialog = false),
                    child: Text(AppStrings.accept),
                  ),
                ],
              ),
            if (_showUnblockDialog)
              AlertDialog(
                title: Text(AppStrings.blockedUserAlertTitle),
                content: Text(AppStrings.blockedUserAlertMessage),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showUnblockDialog = false;
                        widget.messagesProvider.unblockUser(
                          currentUserId,
                          _otherUserId,
                        );
                      });
                    },
                    child: Text(AppStrings.unblock),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _showUnblockDialog = false),
                    child: Text(AppStrings.cancel),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
