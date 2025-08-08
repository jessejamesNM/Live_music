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
  final UserData userData; // Datos del usuario bloqueado
  final VoidCallback
  onUnblockClick; // Función que se ejecuta al hacer clic en el botón de desbloquear

  const BlockedUserItem({
    Key? key,
    required this.userData,
    required this.onUnblockClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtener el esquema de colores de la aplicación
    final colorScheme = ColorPalette.getPalette(context);

    return Column(
      children: [
        // Tarjeta que contiene la información del usuario bloqueado
        Card(
          color:
              colorScheme[AppStrings
                  .primaryColor], // Color de fondo de la tarjeta
          margin: const EdgeInsets.symmetric(
            vertical: 8,
          ), // Margen vertical para separación
          child: ListTile(
            leading: SizedBox(
              width: 60, // Ancho del avatar
              height: 60, // Alto del avatar
              child: CircleAvatar(
                radius: 30, // Radio del círculo
                backgroundImage:
                    userData.profileImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(
                          userData.profileImageUrl,
                        ) // Si tiene imagen, cargarla
                        : null, // Si no tiene imagen, dejarlo vacío
                child:
                    userData.profileImageUrl.isEmpty
                        ? Icon(
                          // Ícono predeterminado cuando no hay imagen de perfil
                          Icons.person,
                          size: 30,
                          color:
                              colorScheme[AppStrings
                                  .secondaryColor], // Color del ícono
                        )
                        : null,
              ),
            ),
            title: Text(
              userData.name, // Nombre del usuario
              style: TextStyle(
                color: colorScheme[AppStrings.secondaryColor],
              ), // Estilo del texto
            ),
            trailing: TextButton(
              onPressed:
                  onUnblockClick, // Acción al presionar el botón de desbloqueo
              style: TextButton.styleFrom(
                foregroundColor:
                    colorScheme[AppStrings
                        .essentialColor], // Color del texto del botón
              ),
              child: Text(AppStrings.unblock), // Texto del botón
            ),
          ),
        ),
        Divider(
          color: colorScheme[AppStrings.secondaryColor],
          thickness: 1,
        ), // Línea divisoria
      ],
    );
  }
}
