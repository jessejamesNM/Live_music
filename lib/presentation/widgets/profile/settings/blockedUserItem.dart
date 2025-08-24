// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
//
// Descripción: Este widget muestra la información de un usuario bloqueado en una tarjeta,
// permitiendo a otros usuarios desbloquearlo. Se muestra una imagen de perfil (si está disponible),
// el nombre del usuario y un botón para desbloquearlo. Es útil en interfaces de usuario donde se
// gestionan usuarios bloqueados, como en una aplicación de redes sociales o de mensajería.
//
// Recomendaciones:
// - Asegúrate de que el `userData.profileImageUrl` esté correctamente formateado y sea accesible.
// - Si el `userData.profileImageUrl` está vacío, se muestra un ícono predeterminado de persona.
// - Si el botón de desbloqueo no tiene una acción definida (cuando `onUnblockClick` es `null`),
//   sería útil deshabilitarlo o mostrar algún tipo de retroalimentación al usuario.
//
// Características:
// - Muestra una tarjeta con la información del usuario bloqueado.
// - El ícono de la imagen de perfil cambia según si el usuario tiene o no una foto.
// - Un botón para desbloquear al usuario, que ejecuta una acción proporcionada por el callback `onUnblockClick`.
// - Diseño responsive con el uso de `ListTile` y `CircleAvatar` para mostrar la imagen de perfil.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../../data/model/messages/user_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:live_music/presentation/resources/strings.dart';

class BlockedUserItem extends StatelessWidget {
  final UserData userData;
  final VoidCallback onUnblockClick;
  final double scaleFactor;

  const BlockedUserItem({
    Key? key,
    required this.userData,
    required this.onUnblockClick,
    required this.scaleFactor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Column(
      children: [
        Card(
          color: colorScheme[AppStrings.primaryColor],
          margin: EdgeInsets.symmetric(vertical: 8 * scaleFactor),
          child: ListTile(
            leading: SizedBox(
              width: 60 * scaleFactor,
              height: 60 * scaleFactor,
              child: CircleAvatar(
                radius: 30 * scaleFactor,
                backgroundImage: userData.profileImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(userData.profileImageUrl)
                    : null,
                child: userData.profileImageUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 30 * scaleFactor,
                        color: colorScheme[AppStrings.secondaryColor],
                      )
                    : null,
              ),
            ),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                userData.name,
                style: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor],
                  fontSize: 16 * scaleFactor,
                ),
              ),
            ),
            trailing: TextButton(
              onPressed: onUnblockClick,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme[AppStrings.essentialColor],
              ),
              child: FittedBox(
                child: Text(
                  AppStrings.unblock,
                  style: TextStyle(fontSize: 14 * scaleFactor),
                ),
              ),
            ),
          ),
        ),
        Divider(
          color: colorScheme[AppStrings.secondaryColor],
          thickness: 1 * scaleFactor,
        ),
      ],
    );
  }
}