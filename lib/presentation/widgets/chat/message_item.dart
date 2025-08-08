/*
Fecha de creación: 26/04/2025
Autor: KingdomOfJames

Descripción:
Pantalla/widget que representa cada ítem de un chat, mostrando mensajes
de texto, imágenes, videos o ubicaciones. Soporta tanto mensajes enviados
como recibidos, diferenciándolos con alineaciones y colores. 
También maneja errores como URLs inválidas o formatos incorrectos de coordenadas.

Recomendaciones:
- Agregar soporte para otros tipos de mensajes como audios o documentos.
- Mejorar la gestión de errores al cargar imágenes o videos.
- Optimizar las miniaturas de video para mejorar el rendimiento.

Características:
- Visualización de mensajes de texto, imágenes, videos y ubicaciones.
- Muestra separación de días en la conversación.
- Diferencia mensajes enviados y recibidos.
- Permite previsualizar imágenes y videos en pantalla completa.

*/

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/widgets/chat/map_preview_chat.dart';
import 'package:live_music/presentation/widgets/chat/media_previewer_chat.dart';
import 'package:live_music/presentation/widgets/chat/message_error_box.dart';
import 'package:live_music/presentation/widgets/chat/video_tumb_nail.dart';

import '../../../data/provider_logics/nav_buttom_bar_components/home/search_fun_provider.dart';

class MessageItem extends StatelessWidget {
  final dynamic
  message; // El mensaje recibido, puede ser texto, imagen, video o ubicación.
  final String
  currentUserId; // ID del usuario actual para identificar si es emisor o receptor.

  const MessageItem({
    Key? key,
    required this.message,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    // Si el mensaje es simplemente un String, es un separador de día.
    if (message is String) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _buildDaySeparator(message, colorScheme),
      );
    }

    // Verificar si el mensaje fue enviado por el usuario actual.
    final isSender = message.senderId == currentUserId;
    final alignment =
        isSender ? MainAxisAlignment.end : MainAxisAlignment.start;
    final backgroundColor =
        isSender
            ? colorScheme[AppStrings.mainColorGray] ?? Colors.grey.shade200
            : colorScheme[AppStrings.primaryColorLight] ?? Colors.blue.shade50;

    // Construir el contenido del mensaje.
    return Row(
      mainAxisAlignment: alignment,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 70, maxWidth: 250),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding:
                (message.type == AppStrings.messageTypeImage ||
                        message.type == AppStrings.messageTypeVideo)
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  (message.type == AppStrings.messageTypeImage ||
                          message.type == AppStrings.messageTypeVideo)
                      ? null
                      : backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMessageContent(context, message, colorScheme),
          ),
        ),
      ],
    );
  }

  // Construye el contenido según el tipo de mensaje (texto, imagen, video o ubicación).
  Widget _buildMessageContent(
    BuildContext context,
    dynamic message,
    Map<String, Color> colorScheme,
  ) {
    switch (message.type) {
      case AppStrings.messageTypeLocation:
        final coordinates = _parseCoordinates(message.messageText);
        if (coordinates != null) {
          return MapPreviewChat(
            latitude: coordinates.first,
            longitude: coordinates.second,
          );
        } else {
          return ErrorMessageBox(
            text: AppStrings.invalidLocationFormat,
            backgroundColor: Colors.red.shade100,
            colorScheme: colorScheme,
          );
        }

      case AppStrings.messageTypeImage:
      case AppStrings.messageTypeVideo:
        final url = message.url as String?;
        final timestamp = _parseTimestamp(message.timestamp);
        final isRead = message.messageRead;

        if (url == null || url.isEmpty) {
          return ErrorMessageBox(
            text: AppStrings.invalidUrl,
            backgroundColor: colorScheme[AppStrings.primaryColor]!,
            colorScheme: colorScheme,
          );
        }

        final isVideo =
            url.toLowerCase().endsWith(".mp4") ||
            url.toLowerCase().endsWith(".mov");

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) =>
                        MediaPreviewPageChat(mediaUrl: url, isVideo: isVideo),
              ),
            );
          },
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    isVideo
                        ? VideoThumbnailChat(url: url, width: 250, height: 250)
                        : Image.network(
                          url,
                          width: 250,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Icon(
                                Icons.error,
                                color: colorScheme[AppStrings.essentialColor],
                              ),
                          loadingBuilder:
                              (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : SizedBox(
                                        width: 250,
                                        height: 250,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  colorScheme[AppStrings
                                                      .essentialColor]!,
                                                ),
                                          ),
                                        ),
                                      ),
                        ),
              ),
              if (isVideo)
                const Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 48,
                      color: Colors.white70,
                    ),
                  ),
                ),
              Positioned(
                bottom: 6,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _formatTimestamp(timestamp),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: isRead ? Colors.blueAccent : Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        final timestamp = _parseTimestamp(message.timestamp);
        return IntrinsicWidth(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  message.messageText,
                  style: TextStyle(
                    color:
                        colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: colorScheme[AppStrings.grayColor],
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    message.messageRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color:
                        message.messageRead
                            ? colorScheme[AppStrings.colorBlue] ?? Colors.blue
                            : Colors.black38,
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  // Construye un separador visual entre días diferentes en el chat.
  Widget _buildDaySeparator(String message, Map<String, Color> colorScheme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              colorScheme[AppStrings.primarySecondColor] ??
              Colors.grey.shade300,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: colorScheme[AppStrings.secondaryColor] ?? Colors.black54,
          ),
        ),
      ),
    );
  }

  // Formatea la hora de un timestamp.
  String _formatTimestamp(DateTime timestamp) {
    final time = TimeOfDay.fromDateTime(timestamp);
    final hour = time.hourOfPeriod.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? AppStrings.am : AppStrings.pm;
    return "$hour:$minute $period";
  }

  // Parsea un texto de coordenadas a un par de números.
  Pair<double, double>? _parseCoordinates(String coordinatesText) {
    try {
      final parts = coordinatesText.split(',');
      if (parts.length == 2) {
        final latitude = double.parse(parts[0]);
        final longitude = double.parse(parts[1]);
        return Pair(latitude, longitude);
      }
    } catch (_) {}
    return null;
  }

  // Parsea distintos formatos de timestamp a DateTime.
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      return DateTime.now();
    }
  }
}
