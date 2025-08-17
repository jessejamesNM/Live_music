/*
Fecha de creación: 26 de abril de 2025
Autor: KingdomOfJames

Descripción:
Pantalla de tarjeta de receptor de mensajes en un chat.
Esta tarjeta muestra el nombre de usuario, la imagen de perfil, el último mensaje enviado, la cantidad de mensajes no leídos, el estado de conexión (en línea o desconectado) y permite acciones rápidas como ver el perfil, bloquear, desbloquear o eliminar una conversación.

Recomendaciones:
- Evitar mostrar información sensible en los logs o errores.
- Manejar mejor los errores de carga de imágenes, quizás con un widget propio de error.
- Optimizar el control de estado para evitar reconstrucciones innecesarias si se usa en una lista larga.
- En el futuro considerar separar aún más la lógica de presentación en un ViewModel.

Características principales:
- Muestra imagen de perfil o imagen por defecto.
- Indica si el usuario está en línea o desconectado.
- Abre un modal con opciones al hacer long-press.
- Muestra un bottom sheet con la vista previa del perfil al presionar la imagen.
- Formatea la fecha del último mensaje dependiendo si es hoy o un día anterior.
*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/chat/profile_preview_messages.dart';
import 'package:provider/provider.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/messages/messages_provider.dart';
import '../../../data/provider_logics/user/user_provider.dart';
import '../../../data/sources/local/internal_data_base.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Widget principal que representa la tarjeta de conversación del receptor
class ReceiverCard extends StatefulWidget {
  final Conversation conversation;
  final bool isOnline;
  final bool iAmBlocked;
  final bool iBlocked;
  final bool artist;
  final GoRouter goRouter;
  final void Function(String) deleteOneConversation;
  final void Function(String) blockOneConversation;
  final void Function(String) unblockOneConversation;
  final MessagesProvider messagesProvider;

  const ReceiverCard({
    required this.conversation,
    required this.isOnline,
    required this.iAmBlocked,
    required this.iBlocked,
    required this.artist,
    required this.deleteOneConversation,
    required this.blockOneConversation,
    required this.unblockOneConversation,
    required this.messagesProvider,
    required this.goRouter,
    Key? key,
  }) : super(key: key);

  @override
  _ReceiverCardState createState() => _ReceiverCardState();
}

class _ReceiverCardState extends State<ReceiverCard> {
  String? _formattedDay;

  @override
  void initState() {
    super.initState();
    _formatDayFromTimestamp();
  }

  // Formatea el timestamp del último mensaje para mostrar hora o día de la semana
  void _formatDayFromTimestamp() {
    final timestamp = widget.conversation.timestamp;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      // Si el mensaje es de hoy, muestra la hora
      final format = DateFormat('hh:mm a', 'es');
      _formattedDay = format.format(date).toLowerCase();
    } else {
      // Si el mensaje es de otro día, muestra el día de la semana
      _formattedDay = DateFormat.EEEE('es').format(date);
      _formattedDay =
          _formattedDay![0].toUpperCase() + _formattedDay!.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    final receiverId = widget.conversation.otherUserId;
    final profileImageUrl = widget.conversation.profileImage;
    final messagesUnread = widget.conversation.messagesUnread;
    final lastMessage = widget.conversation.lastMessage;
    final userName = widget.conversation.name;
    final artist = widget.conversation.artist;
    final currentUserId = widget.conversation.currentUserId;
    final currentUserName = widget.conversation.conversationName;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Marca los mensajes como leídos y navega a la pantalla de chat
            widget.messagesProvider.messagesAsRead(
              currentUserName,
              currentUserId,
            );
            context.read<UserProvider>().setOtherUserId(receiverId);
            context.push(AppStrings.chatScreenRoute);
          },
          onLongPress: () {
            // Abre el menú de opciones al hacer long press
            showDialog(
              context: context,
              builder:
                  (_) => OptionsMenu(
                    userName: userName,
                    onDismiss: () => Navigator.pop(context),
                    iBlocked: widget.iBlocked,
                    receiverId: receiverId,
                    blockOneConversation: widget.blockOneConversation,
                    unblockOneConversation: widget.unblockOneConversation,
                    deleteOneConversation: widget.deleteOneConversation,
                  ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            color: colorScheme[AppStrings.primaryColor],
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // Muestra la vista previa del perfil
                    widget
                        .messagesProvider
                        .isBottomSheetVisibleForProfile
                        .value = true;
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor:
                          colorScheme[AppStrings.primarySecondColor],
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) {
                        return FractionallySizedBox(
                          heightFactor: 0.65,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme[AppStrings.primarySecondColor],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: ProfilePreviewScreen(
                              messagesProvider: widget.messagesProvider,
                              userId: receiverId,
                              userName: userName,
                              profileImageUrl: profileImageUrl,
                              artist: artist,
                              isBottomSheetVisibleForProfile:
                                  widget
                                      .messagesProvider
                                      .isBottomSheetVisibleForProfile
                                      .value,
                              goRouter: widget.goRouter,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Imagen de perfil o imagen por defecto
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme[AppStrings.secondaryColor],
                          border: Border.all(color: Colors.white, width: 0.5),
                        ),
                        child: ClipOval(
                          child:
                              widget.iAmBlocked || profileImageUrl == null
                                  ? SvgPicture.asset(
                                    AppStrings.defaultUserImagePath,
                                    width: 65,
                                    height: 65,
                                    fit: BoxFit.cover,
                                  )
                                  : Image.network(
                                    profileImageUrl,
                                    width: 65,
                                    height: 65,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            SvgPicture.asset(
                                              AppStrings.defaultUserImagePath,
                                              width: 65,
                                              height: 65,
                                              fit: BoxFit.cover,
                                            ),
                                  ),
                        ),
                      ),
                      // Indicador de conexión en línea
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color:
                                widget.iAmBlocked || !widget.isOnline
                                    ? Colors.grey
                                    : Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del usuario
                      Text(
                        userName,
                        style: TextStyle(
                          color:
                              widget.iAmBlocked
                                  ? Colors.grey
                                  : colorScheme[AppStrings.secondaryColor],
                          fontSize: 17,
                        ),
                      ),
                      // Último mensaje
                      Text(
                        lastMessage,
                        style: TextStyle(
                          color: colorScheme[AppStrings.grayColor],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    // Fecha u hora del último mensaje
                    if (_formattedDay != null)
                      Text(
                        _formattedDay!,
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                    // Contador de mensajes no leídos
                    if (messagesUnread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          messagesUnread > 99
                              ? '+99'
                              : messagesUnread.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Separador entre tarjetas
        Divider(
          color: Theme.of(context).primaryColorLight,
          thickness: 1,
          indent: 80,
          height: 0,
        ),
      ],
    );
  }
}

// Widget para mostrar el menú de opciones (bloquear, desbloquear, eliminar)
class OptionsMenu extends StatelessWidget {
  final String userName;
  final VoidCallback onDismiss;
  final bool iBlocked;
  final String receiverId;
  final void Function(String) blockOneConversation;
  final void Function(String) unblockOneConversation;
  final void Function(String) deleteOneConversation;

  const OptionsMenu({
    required this.userName,
    required this.onDismiss,
    required this.iBlocked,
    required this.receiverId,
    required this.blockOneConversation,
    required this.unblockOneConversation,
    required this.deleteOneConversation,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    return AlertDialog(
      backgroundColor: colorScheme[AppStrings.primaryColorLight],
      title: Text(
        "${AppStrings.confirmationTitle} - $userName",
        style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
      ),
      content: Text(
        AppStrings.selectUserType,
        style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (iBlocked) {
              unblockOneConversation(receiverId);
            } else {
              blockOneConversation(receiverId);
            }
            onDismiss();
          },
          child: Text(
            iBlocked ? AppStrings.unblock : AppStrings.block,
            style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
          ),
        ),
        TextButton(
          onPressed: () {
            deleteOneConversation(receiverId);
            onDismiss();
          },
          child: Text(
            AppStrings.delete,
            style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
          ),
        ),
      ],
    );
  }
}
