/*
 * Fecha de creación: 2025-04-26
 * Autor: KingdomOfJames
 * Descripción:
 *  La clase `CircleProfileImage` es un widget personalizado que muestra una imagen de perfil circular. Si se proporciona una URL de la imagen, se carga usando la librería `CachedNetworkImage`, lo que permite optimizar la carga y almacenamiento en caché de las imágenes de red. Si no se proporciona una URL, se muestra una imagen por defecto. Además, este widget permite ejecutar una acción cuando se toca sobre la imagen, lo que lo hace interactivo.
 *  
 * Recomendaciones:
 *  - Utiliza este widget cuando necesites mostrar imágenes de perfil circulares que puedan provenir de una URL o de un recurso local.
 *  - Asegúrate de que la URL de la imagen esté bien configurada para evitar que se muestre la imagen por defecto innecesariamente.
 *  - Este widget es completamente reutilizable y puede usarse en diferentes partes de la aplicación donde se requiera un perfil circular.
 *  
 * Características:
 *  - Imagen de perfil circular que puede ser tocada para ejecutar una acción.
 *  - Soporta imágenes de red con caché para mejorar el rendimiento.
 *  - Si no se proporciona una URL de imagen, usa una imagen por defecto local.
 */

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:live_music/presentation/resources/strings.dart';

class CircleProfileImage extends StatelessWidget {
  final String? profileImageUrl; // URL de la imagen de perfil, puede ser nula.
  final Function()?
  onPressed; // Acción que se ejecuta cuando la imagen es tocada.
  final double size; // Tamaño de la imagen circular.

  const CircleProfileImage({
    Key? key,
    this.profileImageUrl,
    this.onPressed,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed, // Ejecuta la acción al tocar la imagen.
      child: Container(
        width: size, // Define el tamaño de la imagen circular.
        height: size, // Define el tamaño de la imagen circular.
        decoration: BoxDecoration(
          shape: BoxShape.circle, // Hace que la imagen tenga forma circular.
          border: Border.all(
            color: Colors.grey, // Color del borde de la imagen.
            width: 1.0, // Ancho del borde.
          ),
          image: DecorationImage(
            image:
                profileImageUrl != null
                    ? CachedNetworkImageProvider(
                      profileImageUrl!,
                    ) // Carga la imagen desde la URL.
                    : const AssetImage(AppStrings.defaultUserImagePath)
                        as ImageProvider, // Si no hay URL, muestra la imagen por defecto.
            fit:
                BoxFit
                    .cover, // Asegura que la imagen cubra todo el área del círculo sin distorsión.
          ),
        ),
      ),
    );
  }
}
