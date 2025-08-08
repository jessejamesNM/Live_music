// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
// Descripción: Esta pantalla muestra las conversaciones del usuario con otros usuarios. Los usuarios pueden seleccionar varias conversaciones para eliminarlas o bloquearlas.
//              Además, se puede gestionar el estado de conexión de los usuarios y, si el usuario es un artista, se muestran opciones adicionales en la interfaz.
// Características:
// - El usuario puede eliminar o bloquear conversaciones seleccionadas.
// - Los usuarios pueden ver el estado de conexión de otros usuarios (en línea o no).
// - Si el usuario es un artista, se muestran diferentes opciones en la interfaz.
// - Implementación de un modo de selección para realizar acciones masivas sobre las conversaciones.
// Recomendaciones:
// - Asegúrate de gestionar bien los estados de conexión y bloqueo de usuarios para evitar problemas de sincronización.
// - El código está bien modularizado, pero ten en cuenta que los streams pueden acumular datos si no se manejan adecuadamente.


import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/messages/messages_provider.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/widgets/get_conversation_reference.dart';
import '../../../data/provider_logics/user/user_provider.dart';
import '../../../data/provider_logics/user/review_provider.dart';
import '../../../data/sources/local/internal_data_base.dart';
import '../../widgets/chat/bottom_sheet_widget.dart';
import '../../widgets/chat/receiver_card.dart';
import '../buttom_navigation_bar.dart';

class ConversationsScreen extends HookWidget {
  final GoRouter goRouter;
  final UserProvider userProvider;
  final MessagesProvider messagesProvider;
  final ReviewProvider reviewProvider;

  const ConversationsScreen({
    required this.goRouter,
    required this.userProvider,
    required this.messagesProvider,
    required this.reviewProvider,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    // Estado para manejar el UID reactivamente
    final currentUserIdState = useState<String?>(
      FirebaseAuth.instance.currentUser?.uid,
    );

    // Escucha cambios del auth
    useEffect(() {
      final listener = FirebaseAuth.instance.authStateChanges().listen((user) {
        currentUserIdState.value = user?.uid;
      });
      return listener.cancel;
    }, []);

    final currentUserId = currentUserIdState.value;

    // Estados internos para seguimiento del usuario anterior
    final previousUserId = useRef<String?>(null);

    // Si cambia el currentUserId, se reinicia todo
    useEffect(() {
      if (previousUserId.value != currentUserId) {
        messagesProvider.cancelAllActiveListeners();
        messagesProvider.clearAllConversations();

        if (currentUserId != null) {
          messagesProvider.setupConversationListener(currentUserId);
        }

        previousUserId.value = currentUserId;
      }
      return null;
    }, [currentUserId]);

    final userType = userProvider.userType;
    final isArtist = userType == AppStrings.artist;

    final selectedReceivers = useState<List<String>>([]);
    final showSelectionCircles = useState(false);
    final selectionButtonText = useState(AppStrings.edit);
    final isBottomSheetVisible = useState(false);
    final showActionBar = useState(false);

    void deleteSelectedConversations() {
      if (currentUserId == null) return;

      selectedReceivers.value.forEach((otherUserId) async {
        if (otherUserId.isEmpty) return;

        try {
          final conversationRef = ConversationReference();
          final reference = await conversationRef.getConversationReference(
            currentUserId,
            otherUserId,
          );
          await reference.remove();
          messagesProvider.deleteConversation(otherUserId);
          messagesProvider.deleteAllMessages(currentUserId, otherUserId);
        } catch (_) {}
      });

      selectedReceivers.value = [];
      showSelectionCircles.value = false;
      selectionButtonText.value = AppStrings.edit;
      showActionBar.value = false;
      isBottomSheetVisible.value = false;
    }

    void blockSelectedConversations() {
      if (currentUserId == null) return;

      selectedReceivers.value.forEach((otherUserId) async {
        if (otherUserId.isEmpty) return;

        try {
          userProvider.blockUser(currentUserId, otherUserId);
        } catch (_) {}
      });

      selectedReceivers.value = [];
      showSelectionCircles.value = false;
      selectionButtonText.value = AppStrings.edit;
      showActionBar.value = false;
      isBottomSheetVisible.value = false;
    }

    void blockOneConversation(String otherUserId) {
      if (currentUserId == null || otherUserId.isEmpty) return;
      userProvider.blockUser(currentUserId, otherUserId);
    }

    void unblockOneConversation(String otherUserId) {
      if (currentUserId == null || otherUserId.isEmpty) return;
      userProvider.unblockUser(currentUserId, otherUserId);
    }

    void deleteOneConversation(String otherUserId) {
      if (currentUserId == null || otherUserId.isEmpty) return;
      messagesProvider.deleteConversation(otherUserId);
      messagesProvider.deleteAllMessages(currentUserId, otherUserId);
    }

    void toggleSelectionMode() {
      if (selectionButtonText.value == AppStrings.edit) {
        showSelectionCircles.value = true;
        selectionButtonText.value = AppStrings.done;
        isBottomSheetVisible.value = true;
      } else {
        showSelectionCircles.value = false;
        selectionButtonText.value = AppStrings.edit;
        isBottomSheetVisible.value = false;
        selectedReceivers.value = [];
      }
    }

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        isArtist: isArtist,
        goRouter: goRouter,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: toggleSelectionMode,
                              child: Text(
                                selectionButtonText.value,
                                style: TextStyle(
                                  color: colorScheme[AppStrings.essentialColor],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              AppStrings.messages,
                              style: TextStyle(
                                fontSize: 24,
                                color: colorScheme[AppStrings.secondaryColor],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<Conversation>>(
                      stream: messagesProvider.conversations,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              AppStrings.errorLoadingConversations,
                              style: TextStyle(
                                fontSize: 18,
                                color: colorScheme[AppStrings.secondaryColor],
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              AppStrings.noMessagesYet,
                              style: TextStyle(
                                fontSize: 18,
                                color: colorScheme[AppStrings.secondaryColor],
                              ),
                            ),
                          );
                        }

                        final conversationList = snapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: conversationList.length,
                          itemBuilder: (context, index) {
                            final conversation = conversationList[index];
                            final id = conversation.otherUserId;

                            return Row(
                              children: [
                                if (showSelectionCircles.value)
                                  GestureDetector(
                                    onTap: () {
                                      if (selectedReceivers.value.contains(
                                        id,
                                      )) {
                                        selectedReceivers.value = List.from(
                                          selectedReceivers.value,
                                        )..remove(id);
                                      } else {
                                        selectedReceivers.value = List.from(
                                          selectedReceivers.value,
                                        )..add(id);
                                      }
                                    },
                                    child: Container(
                                      width: 25,
                                      height: 25,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color:
                                            colorScheme[AppStrings
                                                .primaryColor],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              colorScheme[AppStrings
                                                  .secondaryColor]!,
                                          width: 1,
                                        ),
                                      ),
                                      child:
                                          selectedReceivers.value.contains(id)
                                              ? Icon(
                                                Icons.check,
                                                color:
                                                    colorScheme[AppStrings
                                                        .secondaryColor],
                                                size: 16,
                                              )
                                              : null,
                                    ),
                                  ),
                                Expanded(
                                  child: ConversationItem(
                                    conversation: conversation,
                                    currentUserId: currentUserId ?? '',
                                    messagesProvider: messagesProvider,
                                    blockOneConversation: blockOneConversation,
                                    unblockOneConversation:
                                        unblockOneConversation,
                                    deleteOneConversation:
                                        deleteOneConversation,
                                    isArtist: isArtist,
                                    goRouter: goRouter,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (isBottomSheetVisible.value)
              BottomSheetWidget(
                isBottomSheetVisible: isBottomSheetVisible.value,
                selectedReceivers: selectedReceivers.value,
                deleteSelectedConversations: deleteSelectedConversations,
                blockSelectedConversations: blockSelectedConversations,
                onBottomSheetVisibilityChanged: (visible) {
                  if (!visible) {
                    showSelectionCircles.value = false;
                    selectionButtonText.value = AppStrings.edit;
                    selectedReceivers.value = [];
                  }
                  isBottomSheetVisible.value = visible;
                },
              ),
          ],
        ),
      ),
    );
  }
}

class ConversationItem extends StatefulWidget {
  final Conversation conversation;
  final String currentUserId;
  final MessagesProvider messagesProvider;
  final void Function(String) deleteOneConversation;
  final void Function(String) blockOneConversation;
  final void Function(String) unblockOneConversation;
  final bool isArtist;
  final GoRouter goRouter;

  const ConversationItem({
    required this.conversation,
    required this.currentUserId,
    required this.messagesProvider,
    required this.deleteOneConversation,
    required this.blockOneConversation,
    required this.unblockOneConversation,
    required this.isArtist,
    required this.goRouter,
    Key? key,
  }) : super(key: key);

  @override
  State<ConversationItem> createState() => _ConversationItemState();
}

class _ConversationItemState extends State<ConversationItem> {
  bool isOnline = false;
  bool iAmBlocked = false;
  bool iBlocked = false;

  late final StreamSubscription<DocumentSnapshot> userSub;
  late final StreamSubscription<DocumentSnapshot> currentUserSub;

  @override
  void initState() {
    super.initState();

    widget.messagesProvider.syncMessagesWithFirebase(
      widget.currentUserId,
      widget.conversation.otherUserId,
    );

    userSub = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.conversation.otherUserId)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          final data = snapshot.data();
          if (data != null) {
            setState(() {
              isOnline = data['userUsingApp'] ?? false;
              final blockedUsers = List<String>.from(
                data['blockedUsers'] ?? [],
              );
              iAmBlocked = blockedUsers.contains(widget.currentUserId);
            });
          }
        });

    currentUserSub = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.currentUserId)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          final data = snapshot.data();
          if (data != null) {
            setState(() {
              final blockedUsers = List<String>.from(
                data['blockedUsers'] ?? [],
              );
              iBlocked = blockedUsers.contains(widget.conversation.otherUserId);
            });
          }
        });
  }

  @override
  void dispose() {
    userSub.cancel();
    currentUserSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ColorPalette.getPalette(context);

    return ReceiverCard(
      conversation: widget.conversation,
      isOnline: isOnline,
      iAmBlocked: iAmBlocked,
      iBlocked: iBlocked,
      artist: widget.isArtist,
      deleteOneConversation: widget.deleteOneConversation,
      blockOneConversation: widget.blockOneConversation,
      unblockOneConversation: widget.unblockOneConversation,
      messagesProvider: widget.messagesProvider,
      goRouter: widget.goRouter,
    );
  }
}





